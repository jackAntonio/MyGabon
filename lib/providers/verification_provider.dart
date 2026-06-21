import 'package:flutter/material.dart';
import '../models/security_models.dart';
import '../services/verification_service.dart';
import '../utils/security_utils.dart';
import '../app_services.dart';

/// Provider for managing user verification (phone, ID)
class VerificationProvider extends ChangeNotifier {
  final VerificationService _verificationService;
  
  UserVerification? _currentUserVerification;
  bool _isVerifying = false;
  String? _verificationError;
  String? _otpSent;
  int _otpResendCountdown = 0;
  
  VerificationProvider(this._verificationService);
  
  // Getters
  UserVerification? get currentUserVerification => _currentUserVerification;
  bool get isVerifying => _isVerifying;
  String? get verificationError => _verificationError;
  String? get otpSent => _otpSent;
  int get otpResendCountdown => _otpResendCountdown;
  
  bool get isPhoneVerified => _currentUserVerification?.phoneVerified ?? false;
  bool get isIdVerified => _currentUserVerification?.idVerified ?? false;
  bool get isFullyVerified => isPhoneVerified && isIdVerified;
  
  /// Load user verification status
  Future<void> loadUserVerification(String userId) async {
    try {
      _isVerifying = true;
      _verificationError = null;
      notifyListeners();
      
      _currentUserVerification = await _verificationService.getUserVerification(userId);
      _isVerifying = false;
      notifyListeners();
    } catch (e) {
      _isVerifying = false;
      _verificationError = 'Failed to load verification status';
      notifyListeners();
    }
  }
  
  /// Send OTP to phone number
  Future<bool> sendPhoneOTP(String phoneNumber) async {
    try {
      if (!SecurityValidator.isValidPhoneNumber(phoneNumber)) {
        _verificationError = 'Invalid phone number format';
        notifyListeners();
        return false;
      }

      _isVerifying = true;
      _verificationError = null;
      notifyListeners();

      // 📱 Générer OTP (6 digits)
      final otp = _generateOTP();

      // 📤 Envoyer via SMS
      final sent = await AppServices().sms.sendOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (!sent) {
        _verificationError = 'Failed to send OTP. Please check phone number.';
        _isVerifying = false;
        notifyListeners();
        return false;
      }

      // 📝 Log audit
      await AppServices().auditLog.logPhoneVerification(
        phoneNumber: phoneNumber,
        verified: false,
      );

      _otpSent = otp;
      _otpResendCountdown = 60; // 60 seconds before resend allowed

      _isVerifying = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isVerifying = false;
      _verificationError = 'Failed to send OTP. Please try again.';
      debugPrint('❌ Error sending OTP: $e');
      notifyListeners();
      return false;
    }
  }

  /// Generate 6-digit OTP
  String _generateOTP() {
    return (100000 + DateTime.now().millisecond % 900000).toString();
  }
  
  /// Verify OTP
  Future<bool> verifyPhoneOTP(String phoneNumber, String otp) async {
    try {
      if (otp.length != 6 || int.tryParse(otp) == null) {
        _verificationError = 'Invalid OTP format';
        notifyListeners();
        return false;
      }

      _isVerifying = true;
      _verificationError = null;
      notifyListeners();

      // Vérifier OTP correspond à celui envoyé
      if (_otpSent != otp) {
        _verificationError = 'Invalid OTP. Please try again.';
        _isVerifying = false;
        notifyListeners();
        return false;
      }

      final isValid = await _verificationService.verifyOTP(phoneNumber, otp);

      if (!isValid) {
        _verificationError = 'Invalid OTP. Please try again.';
        _isVerifying = false;
        notifyListeners();
        return false;
      }

      // Mark phone as verified
      if (_currentUserVerification != null) {
        await _verificationService.markPhoneVerified(
          _currentUserVerification!.userId,
          phoneNumber,
        );

        // 📝 Log successful verification
        await AppServices().auditLog.logPhoneVerification(
          phoneNumber: phoneNumber,
          verified: true,
        );

        // Reload verification status
        await loadUserVerification(_currentUserVerification!.userId);
      }

      _isVerifying = false;
      _otpSent = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isVerifying = false;
      _verificationError = 'Verification failed. Please try again.';
      debugPrint('❌ Error verifying OTP: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Verify ID
  Future<bool> verifyId(String idType, String idNumber) async {
    try {
      if (!SecurityValidator.isValidIdFormat(idNumber)) {
        _verificationError = 'Invalid ID format';
        notifyListeners();
        return false;
      }
      
      _isVerifying = true;
      _verificationError = null;
      notifyListeners();
      
      // In real app, this would verify with backend
      if (_currentUserVerification != null) {
        await _verificationService.markIdVerified(
          _currentUserVerification!.userId,
          idType,
          idNumber,
        );
        
        await loadUserVerification(_currentUserVerification!.userId);
      }
      
      _isVerifying = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isVerifying = false;
      _verificationError = 'ID verification failed. Please try again.';
      notifyListeners();
      return false;
    }
  }
  
  /// Clear OTP
  Future<void> clearOTP(String phoneNumber) async {
    await _verificationService.clearOTP(phoneNumber);
    _otpSent = null;
    _otpResendCountdown = 0;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _verificationError = null;
    notifyListeners();
  }
  
  /// Decrement OTP resend countdown
  void decrementResendCountdown() {
    if (_otpResendCountdown > 0) {
      _otpResendCountdown--;
      notifyListeners();
    }
  }
  
  bool canResendOTP() => _otpResendCountdown == 0;
}
