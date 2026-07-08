import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Types d'échec possibles lors d'une demande de position.
/// Distingués pour permettre des messages d'erreur actionnables côté UI.
enum LocationError {
  /// Le service de localisation (GPS) est désactivé au niveau du système.
  gpsDisabled,

  /// L'utilisateur a refusé la permission lors de la demande.
  permissionDenied,

  /// L'utilisateur a refusé définitivement : l'app doit passer par les
  /// paramètres système pour obtenir l'autorisation.
  permissionPermanentlyDenied,

  /// La position n'a pas pu être obtenue dans le délai imparti (signal faible,
  /// intérieur, émulateur sans GPS simulé).
  timeout,

  /// Erreur inattendue : voir les logs pour les détails.
  unknown,
}

/// Résultat d'une demande de localisation : position ou raison de l'échec.
class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult.success(Position this.position) : error = null;
  LocationResult.failure(LocationError this.error) : position = null;

  bool get isSuccess => position != null;
}

/// Service de géolocalisation : récupère la position de l'utilisateur et
/// calcule les distances, pour le tri "à proximité" du marketplace et des
/// services (MarketplaceProvider / ServiceProvider).
class GeolocationService {
  /// Récupère la position actuelle.
  ///
  /// - Vérifie d'abord que le service de localisation est activé.
  /// - Demande la permission si elle n'a pas encore été accordée.
  /// - Le timeout de [_positionTimeoutSeconds] secondes s'applique
  ///   uniquement à l'acquisition GPS (PAS à la dialog de permission) pour
  ///   éviter que le timer expire pendant que l'utilisateur répond au dialog.
  /// - Renvoie un [LocationResult] avec la position ou le type d'erreur.
  static const int _positionTimeoutSeconds = 20;

  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Vérifier que le GPS / service de localisation est activé
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationResult.failure(LocationError.gpsDisabled);
      }

      // 2. Vérifier / demander la permission (PAS de timeout ici : on attend
      //    que l'utilisateur réponde au dialog système)
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.failure(LocationError.permissionPermanentlyDenied);
      }
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(LocationError.permissionDenied);
      }

      // 3. Acquérir la position (timeout appliqué à CETTE étape uniquement)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: _positionTimeoutSeconds),
        ),
      );
      return LocationResult.success(position);
    } on TimeoutException {
      debugPrint('[GeolocationService] Timeout : GPS fix non obtenu en '
          '${_positionTimeoutSeconds}s (intérieur ou émulateur sans GPS simulé)');
      return LocationResult.failure(LocationError.timeout);
    } catch (e) {
      debugPrint('[GeolocationService] Erreur inattendue : $e');
      return LocationResult.failure(LocationError.unknown);
    }
  }

  /// Distance en kilomètres entre deux coordonnées GPS.
  static double distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Ouvre les paramètres de localisation du système (GPS activé/désactivé).
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  /// Ouvre les paramètres de l'app pour gérer les permissions de localisation.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Message utilisateur actionnable pour chaque type d'échec.
  static String messageFor(LocationError error) {
    switch (error) {
      case LocationError.gpsDisabled:
        return 'Activez la localisation (GPS) dans les paramètres du téléphone';
      case LocationError.permissionDenied:
        return 'Autorisez l\'accès à la position pour trier par proximité';
      case LocationError.permissionPermanentlyDenied:
        return 'Localisation refusée définitivement : activez-la dans les paramètres de l\'app';
      case LocationError.timeout:
        return 'Signal GPS introuvable, réessayez à l\'extérieur';
      case LocationError.unknown:
        return 'Localisation indisponible, réessayez plus tard';
    }
  }

  /// Vrai si l'erreur nécessite d'ouvrir un écran de paramètres système
  /// plutôt que de simplement réessayer.
  static bool needsSettings(LocationError error) =>
      error == LocationError.gpsDisabled ||
      error == LocationError.permissionPermanentlyDenied;
}
