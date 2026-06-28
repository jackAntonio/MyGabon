import 'package:geolocator/geolocator.dart';

/// Position de l'utilisateur + calcul de distance, pour le tri "à
/// proximité" du marketplace (lib/providers/marketplace_provider.dart,
/// service_provider.dart).
class GeolocationService {
  /// Récupère la position actuelle. Ne lève jamais d'exception : renvoie
  /// null si le GPS est désactivé ou la permission refusée, l'appelant doit
  /// alors simplement désactiver les fonctionnalités liées à la position
  /// plutôt que de planter.
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Distance en kilomètres entre deux points.
  static double distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
