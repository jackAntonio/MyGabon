import 'package:flutter/material.dart';

/// Placeholder authentication provider ready for Firebase integration.
/// Currently maintains a simple boolean to simulate login state.
class AuthProvider extends ChangeNotifier {
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  /// Simulate login process. Replace with Firebase Auth calls later.
  Future<void> login({required String emailOrPhone, required String password}) async {
    // TODO: add Firebase authentication logic here
    await Future.delayed(const Duration(seconds: 1));
    _loggedIn = true;
    notifyListeners();
  }

  /// Simulate registration process.
  Future<void> register({required String emailOrPhone, required String password}) async {
    // TODO: add Firebase registration logic here
    await Future.delayed(const Duration(seconds: 1));
    _loggedIn = true;
    notifyListeners();
  }

  void logout() {
    _loggedIn = false;
    notifyListeners();
  }
}
