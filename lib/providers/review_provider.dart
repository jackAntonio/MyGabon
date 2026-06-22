import 'package:flutter/material.dart';
import '../models/security_models.dart';
import '../services/review_service.dart';

/// Provider for managing user reviews and ratings
class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService;

  final Map<String, UserRatingSummary?> _userRatings = {};
  final Map<String, List<UserReview>> _userReviews = {};
  bool _isLoading = false;
  String? _error;

  ReviewProvider(this._reviewService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get user rating summary
  UserRatingSummary? getUserRating(String userId) {
    return _userRatings[userId];
  }

  /// Get user reviews
  List<UserReview> getUserReviews(String userId) {
    return _userReviews[userId] ?? [];
  }

  /// Load user reviews and rating
  Future<void> loadUserReviews(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final reviews = await _reviewService.getUserReviews(userId);
      final rating = await _reviewService.getUserRatingSummary(userId);

      _userReviews[userId] = reviews;
      _userRatings[userId] = rating;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load reviews';
      notifyListeners();
    }
  }

  /// Submit a review
  Future<bool> submitReview({
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
    List<String>? tags,
    bool recommendsUser = true,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _reviewService.submitReview(
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        rating: rating,
        comment: comment,
        tags: tags,
        recommendsUser: recommendsUser,
      );

      // Reload reviews
      await loadUserReviews(revieweeId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId, String userId,
      {required String deletedBy}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _reviewService.deleteReview(reviewId, deletedBy: deletedBy);

      // Reload reviews
      await loadUserReviews(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete review';
      notifyListeners();
      return false;
    }
  }

  /// Get top rated users
  Future<List<String>> getTopRatedUsers({int limit = 10}) async {
    try {
      return await _reviewService.getTopRatedUsers(limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Flag review as inappropriate
  Future<bool> flagReview(String reviewId, String reason) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _reviewService.flagReviewAsInappropriate(reviewId, reason);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to flag review';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
