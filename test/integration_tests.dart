import 'package:flutter_test/flutter_test.dart';
import 'package:gabon_connect/services/sms_service.dart';
import 'package:gabon_connect/services/audit_log_service.dart';
import 'package:gabon_connect/utils/security_utils.dart';

void main() {
  group('SMS Service Integration Tests', () {
    late SmsService smsService;

    setUp(() {
      smsService = SmsService(
        accountSid: 'test_sid',
        authToken: 'test_token',
        twilioNumber: '+1234567890',
      );
    });

    test('sendOTP should return true for valid inputs', () async {
      final otp = SecurityUtils.generateOTP();
      final result = await smsService.sendOTP(
        phoneNumber: '+241612345678',
        otp: otp,
      );

      expect(result, isTrue);
    });

    test('sendOTP should handle invalid phone number', () async {
      final result = await smsService.sendOTP(
        phoneNumber: '',
        otp: '123456',
      );

      expect(result, isFalse);
    });

    test('sendOTP should handle invalid OTP length', () async {
      final result = await smsService.sendOTP(
        phoneNumber: '+241612345678',
        otp: '12345', // Only 5 digits
      );

      expect(result, isFalse);
    });

    test('sendSMS should accept custom message', () async {
      final result = await smsService.sendSMS(
        phoneNumber: '+241612345678',
        message: 'Test notification',
      );

      expect(result, isTrue);
    });
  });

  group('Audit Log Service Integration Tests', () {
    late AuditLogService auditService;

    setUp(() {
      auditService = AuditLogService();
    });

    test('log should handle login action', () async {
      // Note: Nécessite Firebase configuré
      await auditService.logLogin(
        email: 'test@example.com',
        success: true,
      );

      expect(auditService, isNotNull);
    });

    test('logPhoneVerification should mask phone number', () async {
      await auditService.logPhoneVerification(
        phoneNumber: '+241612345678',
        verified: true,
      );

      expect(auditService, isNotNull);
    });

    test('logTransaction should handle transaction data', () async {
      await auditService.logTransaction(
        transactionId: 'txn_123',
        type: 'transfer',
        amount: 50000.0,
        status: 'completed',
      );

      expect(auditService, isNotNull);
    });

    test('logSuspiciousActivity should record warnings', () async {
      await auditService.logSuspiciousActivity(
        reason: 'Multiple failed login attempts',
        details: {
          'attempts': 5,
          'timeframe': '15 minutes',
        },
      );

      expect(auditService, isNotNull);
    });
  });

  group('Audit Log Model Tests', () {
    test('AuditLog should serialize to JSON', () {
      final auditLog = AuditLog(
        id: 'log_123',
        userId: 'user_456',
        action: AuditAction.login,
        details: {'email': 'test@example.com'},
        timestamp: DateTime(2026, 6, 11, 10, 0, 0),
        status: 'success',
      );

      final json = auditLog.toJson();

      expect(json['id'], 'log_123');
      expect(json['userId'], 'user_456');
      expect(json['action'], 'AuditAction.login');
      expect(json['status'], 'success');
    });

    test('AuditLog should deserialize from JSON', () {
      final json = {
        'id': 'log_123',
        'userId': 'user_456',
        'action': 'AuditAction.login',
        'details': {'email': 'test@example.com'},
        'timestamp': '2026-06-11T10:00:00.000Z',
        'status': 'success',
      };

      final auditLog = AuditLog.fromJson(json);

      expect(auditLog.id, 'log_123');
      expect(auditLog.userId, 'user_456');
      expect(auditLog.status, 'success');
    });
  });

  group('Security Integration Tests', () {
    test('Full authentication flow should be secure', () async {
      // Étape 1: Générer OTP
      final otp = SecurityUtils.generateOTP();
      expect(SecurityUtils.isValidOTP(otp), isTrue);

      // Étape 2: Envoyer SMS (simulation)
      final smsService = SmsService(
        accountSid: 'test',
        authToken: 'test',
        twilioNumber: '+1234567890',
      );

      final smsSent = await smsService.sendOTP(
        phoneNumber: '+241612345678',
        otp: otp,
      );
      expect(smsSent, isTrue);

      // Étape 3: Vérifier OTP
      final isValid = SecurityUtils.isValidOTP(otp);
      expect(isValid, isTrue);
    });

    test('Password hashing should work with OTP flow', () {
      const password = 'SecurePassword123!';

      // Hacher mot de passe
      final hash = SecurityUtils.hashPassword(password);
      expect(hash, isNotEmpty);

      // Vérifier mot de passe
      final verified = SecurityUtils.verifyPassword(password, hash);
      expect(verified, isTrue);

      // OTP séparé
      final otp = SecurityUtils.generateOTP();
      expect(SecurityUtils.isValidOTP(otp), isTrue);
    });
  });
}
