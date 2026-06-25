import '../models/security_models.dart';
import 'supabase_service.dart';

/// Service for managing user reviews and ratings.
/// Persisté dans Supabase (table `reviews`, RLS : lecture publique,
/// écriture par l'auteur uniquement) — un avis doit être visible par tout
/// le monde, pas seulement stocké localement chez celui qui l'a posté.
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal();

  /// Submit a review
  Future<String> submitReview({
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
    List<String>? tags,
    bool recommendsUser = true,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.length < 10) {
      throw Exception('Review must be at least 10 characters');
    }

    if (trimmedComment.length > 500) {
      throw Exception('Review must not exceed 500 characters');
    }

    final result = await SupabaseService().client
        .from('reviews')
        .insert({
          'reviewer_id': reviewerId,
          'reviewee_id': revieweeId,
          'rating': rating,
          'comment': trimmedComment,
          'tags': tags ?? [],
          'recommends': recommendsUser,
        })
        .select('id')
        .single();

    return result['id'] as String;
  }

  /// Get reviews for a user
  Future<List<UserReview>> getUserReviews(String userId) async {
    final rows = await SupabaseService().client
        .from('reviews')
        .select()
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows).map(_reviewFromRow).toList();
  }

  /// Get user rating summary, calculé à partir des avis (pas de table
  /// d'agrégat séparée à tenir synchronisée).
  Future<UserRatingSummary?> getUserRatingSummary(String userId) async {
    final reviews = await getUserReviews(userId);
    if (reviews.isEmpty) return null;

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var totalRating = 0.0;
    var recommendCount = 0;
    for (final review in reviews) {
      totalRating += review.rating;
      if (review.recommendsUser) recommendCount++;
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }

    return UserRatingSummary(
      userId: userId,
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      recommendCount: recommendCount,
      ratingDistribution: distribution,
    );
  }

  /// Delete review (par son auteur ; RLS refuse toute autre suppression)
  Future<void> deleteReview(String reviewId, {required String deletedBy}) async {
    await SupabaseService().client.from('reviews').delete().eq('id', reviewId);
  }

  /// Get top rated users (moyenne calculée côté client sur les avis existants)
  Future<List<String>> getTopRatedUsers({int limit = 10}) async {
    final rows = await SupabaseService().client.from('reviews').select('reviewee_id, rating');

    final byUser = <String, List<int>>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final userId = row['reviewee_id'] as String;
      byUser.putIfAbsent(userId, () => []).add(row['rating'] as int);
    }

    final averages = byUser.entries
        .map((e) => (userId: e.key, average: e.value.reduce((a, b) => a + b) / e.value.length))
        .toList()
      ..sort((a, b) => b.average.compareTo(a.average));

    return averages.take(limit).map((e) => e.userId).toList();
  }

  /// Flag review as inappropriate — passe par le RPC flag_review (l'utilisateur
  /// ne peut pas modifier directement la note/le commentaire d'autrui).
  Future<void> flagReviewAsInappropriate(String reviewId, String reason) async {
    await SupabaseService().client.rpc('flag_review', params: {
      'p_review_id': reviewId,
      'p_reason': reason,
    });
  }

  UserReview _reviewFromRow(Map<String, dynamic> row) {
    return UserReview(
      id: row['id'] as String,
      reviewerId: row['reviewer_id'] as String,
      revieweeId: row['reviewee_id'] as String,
      rating: row['rating'] as int,
      comment: row['comment'] as String? ?? '',
      tags: List<String>.from(row['tags'] as List? ?? []),
      recommendsUser: row['recommends'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
