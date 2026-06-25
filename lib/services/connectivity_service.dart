import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

enum ConnectionQuality {
  offline, // No connection
  poor, // Very slow, high latency (< 100KB/s)
  moderate, // Acceptable speed (100KB/s - 1MB/s)
  good, // Fast connection (> 1MB/s)
}

/// Service for monitoring network connectivity and quality
/// Detects connection status and estimates network speed for African regions
class ConnectivityService extends ChangeNotifier {
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivityStream;

  bool _isConnected = false;
  ConnectionQuality _connectionQuality = ConnectionQuality.offline;
  ConnectivityResult _lastResult = ConnectivityResult.none;

  bool get isConnected => _isConnected;
  ConnectionQuality get connectionQuality => _connectionQuality;
  bool get isOnlineMode =>
      _isConnected && _connectionQuality != ConnectionQuality.offline;
  String get connectionStatusText {
    switch (_connectionQuality) {
      case ConnectionQuality.offline:
        return '📵 Hors ligne';
      case ConnectionQuality.poor:
        return '🔴 Connexion faible';
      case ConnectionQuality.moderate:
        return '🟡 Connexion modérée';
      case ConnectionQuality.good:
        return '🟢 Bonne connexion';
    }
  }

  ConnectivityService() {
    _connectivity = Connectivity();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);

      // Listen to connectivity changes
      _connectivityStream = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
      );
    } catch (e) {
      debugPrint('❌ Erreur de connectivité: $e');
    }
  }

  /// Depuis connectivity_plus v6, plusieurs connexions peuvent être actives
  /// simultanément (ex. wifi + ethernet) : on retient la "meilleure" pour
  /// l'estimation de qualité ci-dessous (wifi > mobile > autre > aucune).
  ConnectivityResult _primaryResult(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return ConnectivityResult.wifi;
    if (results.contains(ConnectivityResult.mobile)) return ConnectivityResult.mobile;
    return results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final result = _primaryResult(results);
    _lastResult = result;

    final isOnline = result != ConnectivityResult.none;

    if (_isConnected != isOnline) {
      _isConnected = isOnline;

      if (_isConnected) {
        debugPrint('✅ Connexion établie: ${_lastResult.toString()}');
        _checkNetworkQuality();
      } else {
        debugPrint('❌ Connexion perdue');
        _connectionQuality = ConnectionQuality.offline;
      }

      notifyListeners();
    }
  }

  /// Simulate network quality check
  /// In production, implement actual network speed test
  Future<void> _checkNetworkQuality() async {
    if (!_isConnected) {
      _connectionQuality = ConnectionQuality.offline;
      return;
    }

    // Simulate network quality based on connection type
    // In a real app, perform actual speed tests
    if (_lastResult == ConnectivityResult.wifi) {
      _connectionQuality = ConnectionQuality.good;
    } else if (_lastResult == ConnectivityResult.mobile) {
      // Assume mobile is moderate unless proven otherwise
      // In production, run actual speed test
      _connectionQuality = ConnectionQuality.moderate;
    } else {
      _connectionQuality = ConnectionQuality.poor;
    }

    notifyListeners();
  }

  /// Retry operation with exponential backoff
  /// Useful for failed API calls in low-bandwidth environments
  Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries || !_isConnected) {
          rethrow;
        }

        // Exponential backoff
        final delayMs = initialDelay.inMilliseconds * (1 << (retryCount - 1));
        debugPrint(
          '⏳ Tentative $retryCount/$maxRetries après ${delayMs}ms',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Simulate network bandwidth (in KB/s)
  /// In production, use actual measurements
  int getEstimatedBandwidth() {
    switch (_connectionQuality) {
      case ConnectionQuality.offline:
        return 0;
      case ConnectionQuality.poor:
        return 50; // ~50 KB/s
      case ConnectionQuality.moderate:
        return 500; // ~500 KB/s
      case ConnectionQuality.good:
        return 2000; // ~2 MB/s
    }
  }

  @override
  void dispose() {
    _connectivityStream.cancel();
    super.dispose();
  }
}
