import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/security_models.dart';
import '../utils/security_utils.dart';

/// Service for managing user reviews and ratings
class ReviewService {
  static const String _reviewsBoxName = 'reviews_cache';
  static const String _ratingsBoxName = 'ratings_cache';
  
  late Box<dynamic> _reviewsBox;
  late Box<dynamic> _ratingsBox;
  
  static final ReviewService _instance = ReviewService._internal();
  
  factory ReviewService() {
    return _instance;
  }
  
  ReviewService._internal();
  
  /// Initialize Hive boxes
  Future<void> init() async {
    _reviewsBox = await Hive.openBox(_reviewsBoxName);
    _ratingsBox = await Hive.openBox(_ratingsBoxName);
  }
  
  /// Submit a review
  Future<String> submitReview({
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
    List<String>? tags,
    bool recommendsUser = true,
  }) async {
    // Validate input
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }
    
    if (!SecurityValidator.isSafeInput(comment)) {
      throw Exception('Review comment contains invalid content');
    }
    
    if (comment.length < 10) {
      throw Exception('Review must be at least 10 characters');
    }
    
    if (comment.length > 500) {
      throw Exception('Review must not exceed 500 characters');
    }
    
    final review = UserReview(
      id: const Uuid().v4(),
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      rating: rating,
      comment: SecurityValidator.sanitizeInput(comment),
      tags: tags ?? [],
      recommendsUser: recommendsUser,
    );
    
    _reviewsBox.put(review.id, review.toJson());
    
    // Update rating summary
    await _updateRatingSummary(revieweeId);
    
    return review.id;
  }
  
  /// Get reviews for a user
  Future<List<UserReview>> getUserReviews(String userId) async {
    final reviews = <UserReview>[];
    
    for (final data in _reviewsBox.values) {
      if (data is Map) {
        final review = data as Map<String, dynamic>;
        if (review['revieweeId'] == userId) {
          reviews.add(UserReview.fromJson(review));
        }
      }
    }
    
    // Sort by newest first
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }
  
  /// Get user rating summary
  Future<UserRatingSummary?> getUserRatingSummary(String userId) async {
    final data = _ratingsBox.get(userId);
    if (data == null) {
      return null;
    }
    
    final map = data as Map<String, dynamic>;
    final ratingDistribution = <int, int>{};
    final dist = map['ratingDistribution'] as Map?;
    if (dist != null) {
      dist.forEach((key, value) {
        ratingDistribution[int.parse(key.toString())] = value as int;
      });
    }
    
    return UserRatingSummary(
      userId: userId,
      averageRating: (map['averageRating'] as num).toDouble(),
      totalReviews: map['totalReviews'] as int,
      recommendCount: map['recommendCount'] as int,
      ratingDistribution: ratingDistribution,
    );
  }
  
  /// Update rating summary (internal)
  Future<void> _updateRatingSummary(String userId) async {
    final reviews = await getUserReviews(userId);
    
    if (reviews.isEmpty) {
      _ratingsBox.delete(userId);
      return;
    }
    
    double totalRating = 0;
    int recommendCount = 0;
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final review in reviews) {
      totalRating += review.rating;
      if (review.recommendsUser) recommendCount++;
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    
    final averageRating = totalRating / reviews.length;
    
    _ratingsBox.put(userId, {
      'userId': userId,
      'averageRating': averageRating,
      'totalReviews': reviews.length,
      'recommendCount': recommendCount,
      'ratingDistribution': distribution,
      'lastUpdate': DateTime.now().toIso8601String(),
    });
  }
  
  /// Delete review (by reviewer or moderator)
  Future<void> deleteReview(String reviewId, {required String deletedBy}) async {
    if (_reviewsBox.containsKey(reviewId)) {
      final review = _reviewsBox.get(reviewId) as Map;
      final revieweeId = review['revieweeId'] as String;
      _reviewsBox.delete(reviewId);
      await _updateRatingSummary(revieweeId);
    }
  }
  
  /// Get top rated users
  Future<List<String>> getTopRatedUsers({int limit = 10}) async {
    final users = <String>[];
    final ratings = _ratingsBox.toMap().values
        .whereType<Map>()
        .toList()
        ..sort((a, b) => 
            (b['averageRating'] as num).compareTo(a['averageRating'] as num));
    
    for (final rating in ratings.take(limit)) {
      users.add(rating['userId'] as String);
    }
    
    return users;
  }
  
  /// Flag review as inappropriate
  Future<void> flagReviewAsInappropriate(String reviewId, String reason) async {
    if (_reviewsBox.containsKey(reviewId)) {
      final review = _reviewsBox.get(reviewId) as Map;
      review['flagged'] = true;
      review['flagReason'] = reason;
      review['flaggedAt'] = DateTime.now().toIso8601String();
      _reviewsBox.put(reviewId, review);
    }
  }
  
  /// Get flagged reviews
  Future<List<UserReview>> getFlaggedReviews() async {
    final reviews = <UserReview>[];
    
    for (final data in _reviewsBox.values) {
      if (data is Map) {
        final review = data as Map<String, dynamic>;
        if (review['flagged'] == true) {
          reviews.add(UserReview.fromJson(review));
        }
      }
    }
    
    return reviews;
  }
  
  /// Get most helpful reviews
  Future<List<UserReview>> getMostHelpfulReviews(String userId, {int limit = 5}) async {
    final reviews = await getUserReviews(userId);
    
    // Sort by rating and recommendation
    reviews.sort((a, b) {
      final scoreA = (a.rating * 2) + (a.recommendsUser ? 1 : 0);
      final scoreB = (b.rating * 2) + (b.recommendsUser ? 1 : 0);
      return scoreB.compareTo(scoreA);
    });
    
    return reviews.take(limit).toList();
  }
  
  /// Get review statistics for period
  Future<Map<String, dynamic>> getReviewStats({Duration period = const Duration(days: 30)}) async {
    final startDate = DateTime.now().subtract(period);
    final reviews = <UserReview>[];
    
    for (final data in _reviewsBox.values) {
      if (data is Map) {
        final review = UserReview.fromJson(data as Map<String, dynamic>);
        if (review.createdAt.isAfter(startDate)) {
          reviews.add(review);
        }
      }
    }
    
    double avgRating = 0;
    if (reviews.isNotEmpty) {
      final sum = reviews.fold<double>(0, (sum, r) => sum + r.rating);
      avgRating = sum / reviews.length;
    }
    
    return {
      'totalReviews': reviews.length,
      'averageRating': avgRating,
      'recommendPercentage': reviews.isEmpty 
          ? 0 
          : (reviews.where((r) => r.recommendsUser).length / reviews.length) * 100,
      'period': period.inDays,
    };
  }
  
  /// Cleanup old reviews
  Future<void> cleanupOldReviews({int daysOld = 180}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final keysToRemove = <String>[];
    for (final entry in _reviewsBox.toMap().entries) {
      if (entry.value is Map) {
        final data = entry.value as Map;
        if (data['createdAt'] != null) {
          final createdAt = DateTime.parse(data['createdAt']);
          if (createdAt.isBefore(cutoffDate)) {
            keysToRemove.add(entry.key);
          }
        }
      }
    }
    
    for (final key in keysToRemove) {
      _reviewsBox.delete(key);
    }
  }
}
