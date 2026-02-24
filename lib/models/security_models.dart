/// User verification status model
class UserVerification {
  final String userId;
  final bool phoneVerified;
  final String? phoneNumber;
  final DateTime? phoneVerifiedAt;
  
  final bool idVerified;
  final String? idType;  // passport, national_id, driver_license
  final String? idNumber;
  final DateTime? idVerifiedAt;
  
  // Verification badges
  bool get isVerifiedProvider => phoneVerified && idVerified;
  
  UserVerification({
    required this.userId,
    this.phoneVerified = false,
    this.phoneNumber,
    this.phoneVerifiedAt,
    this.idVerified = false,
    this.idType,
    this.idNumber,
    this.idVerifiedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'phoneVerified': phoneVerified,
    'phoneNumber': phoneNumber,
    'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
    'idVerified': idVerified,
    'idType': idType,
    'idNumber': idNumber,
    'idVerifiedAt': idVerifiedAt?.toIso8601String(),
  };
  
  static UserVerification fromJson(Map<String, dynamic> json) {
    return UserVerification(
      userId: json['userId'] as String,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      phoneVerifiedAt: json['phoneVerifiedAt'] != null
          ? DateTime.parse(json['phoneVerifiedAt'] as String)
          : null,
      idVerified: json['idVerified'] as bool? ?? false,
      idType: json['idType'] as String?,
      idNumber: json['idNumber'] as String?,
      idVerifiedAt: json['idVerifiedAt'] != null
          ? DateTime.parse(json['idVerifiedAt'] as String)
          : null,
    );
  }
}

/// User review and rating model
class UserReview {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final int rating;  // 1-5 stars
  final String comment;
  final List<String> tags;  // professional, friendly, reliable, etc.
  final bool recommendsUser;
  final DateTime createdAt;
  
  UserReview({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.recommendsUser,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'reviewerId': reviewerId,
    'revieweeId': revieweeId,
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'recommendsUser': recommendsUser,
    'createdAt': createdAt.toIso8601String(),
  };
  
  static UserReview fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: json['id'] as String,
      reviewerId: json['reviewerId'] as String,
      revieweeId: json['revieweeId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      recommendsUser: json['recommendsUser'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// User rating summary
class UserRatingSummary {
  final String userId;
  final double averageRating;
  final int totalReviews;
  final int recommendCount;
  final Map<int, int> ratingDistribution;  // rating -> count
  
  UserRatingSummary({
    required this.userId,
    required this.averageRating,
    required this.totalReviews,
    required this.recommendCount,
    required this.ratingDistribution,
  });
  
  double getRecommendPercentage() {
    if (totalReviews == 0) return 0;
    return (recommendCount / totalReviews) * 100;
  }
}

/// Fraud prevention model
enum FraudRiskLevel { safe, low, moderate, high, critical }

class FraudReport {
  final String id;
  final String reporterId;
  final String suspiciousUserId;
  final String? listingId;
  final String reportReason;  // suspicious_price, scam_attempt, etc.
  final String description;
  final List<String> evidence;  // photo/doc URLs
  final bool verified;
  final DateTime createdAt;
  
  FraudReport({
    required this.id,
    required this.reporterId,
    required this.suspiciousUserId,
    this.listingId,
    required this.reportReason,
    required this.description,
    required this.evidence,
    this.verified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'reporterId': reporterId,
    'suspiciousUserId': suspiciousUserId,
    'listingId': listingId,
    'reportReason': reportReason,
    'description': description,
    'evidence': evidence,
    'verified': verified,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Payment escrow model
enum EscrowStatus { pending, held, released, refunded, disputed }

class PaymentEscrow {
  final String id;
  final String transactionId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final EscrowStatus status;
  final String serviceId;
  final DateTime createdAt;
  final DateTime? releaseDate;
  final String? releaseReason;
  
  PaymentEscrow({
    required this.id,
    required this.transactionId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.status,
    required this.serviceId,
    DateTime? createdAt,
    this.releaseDate,
    this.releaseReason,
  }) : createdAt = createdAt ?? DateTime.now();
  
  bool get isReadyForRelease => status == EscrowStatus.held;
  bool get isCompleted => status == EscrowStatus.released;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'amount': amount,
    'status': status.toString(),
    'serviceId': serviceId,
    'createdAt': createdAt.toIso8601String(),
    'releaseDate': releaseDate?.toIso8601String(),
    'releaseReason': releaseReason,
  };
}

/// User block list
class BlockedUser {
  final String userId;
  final String blockedUserId;
  final String? reason;
  final DateTime createdAt;
  
  BlockedUser({
    required this.userId,
    required this.blockedUserId,
    this.reason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'blockedUserId': blockedUserId,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
  };
}
