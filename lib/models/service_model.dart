/// Service ou prestation proposée par un professionnel sur MyGabon.
class ServiceModel {
  final String id;
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final bool providerVerified;
  final String title;
  final String description;
  final double price;
  final String category;
  final String location;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewsCount;

  ServiceModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerAvatar,
    this.providerVerified = false,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    required this.rating,
    this.reviewsCount = 0,
  });

  String get formattedPrice =>
      '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'), (m) => '${m.group(0)} ')} FCFA';
}
