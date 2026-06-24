import 'package:flutter/material.dart';
import '../models/security_models.dart';
import '../services/verification_service.dart';
import '../services/supabase_service.dart';
import '../utils/security_utils.dart';

/// Provider for managing user verification (phone, ID)
/// ✅ L'OTP est généré/vérifié côté serveur (SupabaseService -> RPC
/// request_phone_otp/confirm_phone_otp). Ce provider ne génère plus
/// l'OTP en local et ne le compare jamais lui-même.
class VerificationProvider extends ChangeNotifier {
  final VerificationService _verificationService;

  UserVerification? _currentUserVerification;
  bool _isVerifying = false;
  String? _verificationError;
  int _otpResendCountdown = 0;

  VerificationProvider(this._verificationService);

  // Getters
  UserVerification? get currentUserVerification => _currentUserVerification;
  bool get isVerifying => _isVerifying;
  String? get verificationError => _verificationError;
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
  
  /// Demande l'envoi d'un OTP au numéro donné (génération + hachage +
  /// stockage entièrement côté serveur, cf. RPC request_phone_otp).
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

      final sent = await SupabaseService().sendOTP(phoneNumber: phoneNumber);

      if (!sent) {
        _verificationError = 'Failed to send OTP. Please check phone number.';
        _isVerifying = false;
        notifyListeners();
        return false;
      }

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

  /// Vérifie l'OTP saisi auprès du serveur (RPC confirm_phone_otp), qui
  /// positionne lui-même users.verified en cas de succès.
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

      final isValid = await SupabaseService().verifyOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (!isValid) {
        _verificationError = 'Invalid OTP. Please try again.';
        _isVerifying = false;
        notifyListeners();
        return false;
      }

      // Mise en cache locale (UI uniquement, le serveur reste la source de
      // vérité pour users.verified).
      if (_currentUserVerification != null) {
        await _verificationService.markPhoneVerified(
          _currentUserVerification!.userId,
          phoneNumber,
        );

        await loadUserVerification(_currentUserVerification!.userId);
      }

      _isVerifying = false;
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
  
  /// Réinitialise le compte à rebours de renvoi (l'OTP lui-même vit
  /// côté serveur et expire automatiquement après 5 minutes).
  void clearOTP(String phoneNumber) {
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
