import 'dart:async';
import 'package:hive/hive.dart';
import '../models/security_models.dart';
import '../utils/security_utils.dart';
import '../utils/secure_hive.dart';

/// Cache local du statut de vérification (lecture rapide pour l'UI).
/// ⚠️ Non autoritaire : la génération/vérification de l'OTP téléphone se
/// fait exclusivement côté serveur (SupabaseService -> RPC
/// request_phone_otp/confirm_phone_otp), seul habilité à positionner
/// users.verified. Ce service ne fait que refléter localement ce résultat
/// pour l'affichage, et ne doit jamais être utilisé comme preuve de
/// vérification (ex: pour débloquer une fonctionnalité sensible).
class VerificationService {
  static const String _verificationBoxName = 'verification_cache';

  late Box<dynamic> _verificationBox;

  static final VerificationService _instance = VerificationService._internal();

  factory VerificationService() {
    return _instance;
  }

  VerificationService._internal();

  /// Initialize Hive box (chiffrée : ID/téléphone sont des données
  /// personnelles sensibles).
  Future<void> init() async {
    _verificationBox = await SecureHive.openEncryptedBox(_verificationBoxName);
  }

  /// Mark phone as verified
  Future<void> markPhoneVerified(String userId, String phoneNumber) async {
    final verification =
        await getUserVerification(userId) ?? UserVerification(userId: userId);

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
    final verification =
        await getUserVerification(userId) ?? UserVerification(userId: userId);

    final updated = UserVerification(
      userId: userId,
      phoneVerified: verification.phoneVerified,
      phoneNumber: verification.phoneNumber,
      phoneVerifiedAt: verification.phoneVerifiedAt,
      idVerified: true,
      idType: idType,
      idNumber: SecurityUtils.maskIdNumber(idNumber),
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
      if (data is Map &&
          (data['phoneVerified'] == true || data['idVerified'] == true)) {
        verifiedUsers.add(data['userId'] as String);
      }
    }

    return verifiedUsers;
  }

  /// Cleanup old verifications
  Future<void> cleanupExpiredVerifications() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

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
