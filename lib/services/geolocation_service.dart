/// Placeholder service for geolocation features.
/// Later this will request permissions and return current position.
class GeolocationService {
  /// Fetches the current device location (dummy for now).
  Future<dynamic> getCurrentLocation() async {
    // TODO: implement with geolocator package and return current coordinates
    return null;
  }

  /// Filters a list of services by proximity.
  void filterNearby() {
    // TODO: implement using coordinates
  }
}
