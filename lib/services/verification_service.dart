import 'dart:async';
import 'package:hive/hive.dart';
import '../models/security_models.dart';
import '../utils/security_utils.dart';

/// Service for managing user verification (phone OTP, ID verification)
class VerificationService {
  static const String _verificationBoxName = 'verification_cache';
  static const String _otpBoxName = 'otp_cache';
  
  late Box<dynamic> _verificationBox;
  late Box<dynamic> _otpBox;
  
  final Map<String, int> _otpAttempts = {};
  final Map<String, DateTime> _otpExpiry = {};
  
  static final VerificationService _instance = VerificationService._internal();
  
  factory VerificationService() {
    return _instance;
  }
  
  VerificationService._internal();
  
  /// Initialize Hive boxes
  Future<void> init() async {
    _verificationBox = await Hive.openBox(_verificationBoxName);
    _otpBox = await Hive.openBox(_otpBoxName);
  }
  
  /// Send OTP to phone number (simulated - integrate with SMS service)
  Future<String> sendOTPToPhone(String phoneNumber) async {
    if (!SecurityValidator.isValidPhoneNumber(phoneNumber)) {
      throw Exception('Invalid phone number format');
    }
    
    final otp = SecurityUtils.generateOTP();
    final sanitizedPhone = SecurityValidator.sanitizeInput(phoneNumber);
    
    // Store OTP with expiry (5 minutes)
    _otpBox.put(sanitizedPhone, {
      'otp': otp,
      'createdAt': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
    
    _otpAttempts[sanitizedPhone] = 0;
    _otpExpiry[sanitizedPhone] = DateTime.now().add(Duration(minutes: 5));
    
    // TODO: Integrate with actual SMS service (Twilio, AWS SNS, etc.)
    // For now, simulated
    print('OTP for $phoneNumber: $otp (simulated SMS)');
    
    return 'OTP_SENT_${sanitizedPhone.substring(sanitizedPhone.length - 4)}';
  }
  
  /// Verify OTP
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    if (otp.length != 6 || int.tryParse(otp) == null) {
      return false;
    }
    
    final sanitizedPhone = SecurityValidator.sanitizeInput(phoneNumber);
    
    // Check expiry
    if (_otpExpiry[sanitizedPhone] == null || 
        DateTime.now().isAfter(_otpExpiry[sanitizedPhone]!)) {
      return false;
    }
    
    // Check attempts (max 5)
    if ((_otpAttempts[sanitizedPhone] ?? 0) >= 5) {
      return false;
    }
    
    final storedData = _otpBox.get(sanitizedPhone);
    if (storedData == null) {
      return false;
    }
    
    final storedOtp = storedData['otp'] as String;
    
    if (otp != storedOtp) {
      _otpAttempts[sanitizedPhone] = (_otpAttempts[sanitizedPhone] ?? 0) + 1;
      return false;
    }
    
    return true;
  }
    
  /// Mark phone as verified
  Future<void> markPhoneVerified(String userId, String phoneNumber) async {
    final verification = await getUserVerification(userId) ?? 
        UserVerification(userId: userId);
    
    final updated = UserVerification(
      userId: userId,
      phoneVerified: true,
      phoneNumber: phoneNumber,
      phoneVerifiedAt: DateTime.now(),
      idVerified: verification.idVerified,
      idType: verification.idType,
      idNumber: verification.idNumber,
      idVerifiedAt: verification.idVerifiedAt,
    );
    
    _verificationBox.put(userId, updated.toJson());
  }
  
  /// Mark ID as verified
  Future<void> markIdVerified(
    String userId,
    String idType,
    String idNumber,
  ) async {
    final verification = await getUserVerification(userId) ?? 
        UserVerification(userId: userId);
    
    final updated = UserVerification(
      userId: userId,
      phoneVerified: verification.phoneVerified,
      phoneNumber: verification.phoneNumber,
      phoneVerifiedAt: verification.phoneVerifiedAt,
      idVerified: true,
      idType: idType,
      idNumber: SecurityUtils.encryptIdNumber(idNumber),
      idVerifiedAt: DateTime.now(),
    );
    
    _verificationBox.put(userId, updated.toJson());
  }
  
  /// Get user verification status
  Future<UserVerification?> getUserVerification(String userId) async {
    final data = _verificationBox.get(userId);
    if (data == null) {
      return null;
    }
    
    return UserVerification.fromJson(data as Map<String, dynamic>);
  }
  
  /// Get all verified users
  Future<List<String>> getVerifiedUsers() async {
    final verifiedUsers = <String>[];
    
    for (final data in _verificationBox.values) {
      if (data is Map && (data['phoneVerified'] == true || data['idVerified'] == true)) {
        verifiedUsers.add(data['userId'] as String);
      }
    }
    
    return verifiedUsers;
  }
  
  /// Clear OTP for phone
  Future<void> clearOTP(String phoneNumber) async {
    final sanitized = SecurityValidator.sanitizeInput(phoneNumber);
    _otpBox.delete(sanitized);
    _otpAttempts.remove(sanitized);
    _otpExpiry.remove(sanitized);
  }
  
  /// Cleanup old verifications
  Future<void> cleanupExpiredVerifications() async {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    
    final keysToRemove = <String>[];
    for (final entry in _verificationBox.toMap().entries) {
      if (entry.value is Map) {
        final data = entry.value as Map;
        if (data['phoneVerifiedAt'] != null) {
          final verifiedAt = DateTime.parse(data['phoneVerifiedAt']);
          if (verifiedAt.isBefore(thirtyDaysAgo)) {
            keysToRemove.add(entry.key);
          }
        }
      }
    }
    
    for (final key in keysToRemove) {
      _verificationBox.delete(key);
    }
  }
}
