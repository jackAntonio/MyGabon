/// Simple model representing a service or announcement.
class ServiceModel {
  final String title;
  final String description;
  final String location;
  final double rating;

  ServiceModel({
    required this.title,
    required this.description,
    required this.location,
    required this.rating,
  });
}
