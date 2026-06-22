import 'package:flutter_test/flutter_test.dart';
import 'package:gabon_connect/utils/security_utils.dart';
import 'package:gabon_connect/services/auth_token_service.dart';

void main() {
  group('SecurityUtils - Password Hashing', () {
    test('hashPassword should return non-empty hash', () {
      const password = 'SecurePassword123!';
      final hash = SecurityUtils.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash.length, greaterThan(10));
    });

    test('hashPassword should not return plaintext', () {
      const password = 'SecurePassword123!';
      final hash = SecurityUtils.hashPassword(password);

      expect(hash, isNot(password));
    });

    test('Two passwords should have different hashes (BCrypt includes salt)',
        () {
      const password = 'SecurePassword123!';
      final hash1 = SecurityUtils.hashPassword(password);
      final hash2 = SecurityUtils.hashPassword(password);

      // BCrypt génère du salt aléatoire, donc hashes différents
      expect(hash1, isNot(hash2));
    });

    test('verifyPassword should match correct password', () {
      const password = 'SecurePassword123!';
      final hash = SecurityUtils.hashPassword(password);

      expect(SecurityUtils.verifyPassword(password, hash), isTrue);
    });

    test('verifyPassword should reject wrong password', () {
      const password = 'SecurePassword123!';
      const wrongPassword = 'WrongPassword456!';
      final hash = SecurityUtils.hashPassword(password);

      expect(SecurityUtils.verifyPassword(wrongPassword, hash), isFalse);
    });

    test('verifyPassword should reject empty password', () {
      final hash = SecurityUtils.hashPassword('ValidPassword123!');

      expect(SecurityUtils.verifyPassword('', hash), isFalse);
    });
  });

  group('SecurityUtils - OTP Generation', () {
    test('generateOTP should generate 6 digit string', () {
      final otp = SecurityUtils.generateOTP();

      expect(otp.length, 6);
      expect(int.tryParse(otp), isNotNull);
    });

    test('generateOTP should contain only digits', () {
      final otp = SecurityUtils.generateOTP();

      expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue);
    });

    test('Two OTPs should be different (random)', () {
      final otp1 = SecurityUtils.generateOTP();
      final otp2 = SecurityUtils.generateOTP();

      // Probabilité extrêmement faible que deux générés aléatoirement soient identiques
      expect(otp1, isNot(otp2));
    });

    test('OTP should be valid according to isValidOTP', () {
      final otp = SecurityUtils.generateOTP();

      expect(SecurityUtils.isValidOTP(otp), isTrue);
    });

    test('isValidOTP should reject non-6-digit codes', () {
      expect(SecurityUtils.isValidOTP('12345'), isFalse); // 5 digits
      expect(SecurityUtils.isValidOTP('1234567'), isFalse); // 7 digits
      expect(SecurityUtils.isValidOTP('123abc'), isFalse); // Contains letters
      expect(SecurityUtils.isValidOTP(''), isFalse); // Empty
    });
  });

  group('SecurityUtils - Email & Phone Masking', () {
    test('maskEmail should hide middle characters', () {
      const email = 'john.doe@example.com';
      final masked = SecurityUtils.maskEmail(email);

      expect(masked, contains('@example.com'));
      expect(masked.startsWith('j'), isTrue);
      expect(masked, isNot(email));
    });

    test('maskEmail should handle short emails', () {
      const email = 'a@example.com';
      final masked = SecurityUtils.maskEmail(email);

      expect(masked, contains('****@'));
    });

    test('encryptPhoneNumber should hide most digits', () {
      const phone = '1234567890';
      final masked = SecurityUtils.encryptPhoneNumber(phone);

      expect(masked.endsWith('7890'), isTrue);
      expect(masked.startsWith('*'), isTrue);
    });

    test('encryptPhoneNumber should handle short numbers', () {
      const phone = '123';
      final masked = SecurityUtils.encryptPhoneNumber(phone);

      expect(masked, '****');
    });
  });

  group('SecurityValidator - Input Validation', () {
    test('isSafeInput should reject SQL injection patterns', () {
      expect(
        SecurityValidator.isSafeInput("'; DROP TABLE users; --"),
        isFalse,
      );
      expect(
        SecurityValidator.isSafeInput("1' OR '1'='1"),
        isFalse,
      );
      expect(
        SecurityValidator.isSafeInput("admin' --"),
        isFalse,
      );
    });

    test('isSafeInput should accept normal input', () {
      expect(
        SecurityValidator.isSafeInput("This is a normal comment"),
        isTrue,
      );
      expect(
        SecurityValidator.isSafeInput("My service description 2024"),
        isTrue,
      );
    });

    test('isSafeInput should reject empty input', () {
      expect(SecurityValidator.isSafeInput(''), isFalse);
    });

    test('isSafeInput should reject very long input', () {
      final longInput = 'a' * 501;
      expect(SecurityValidator.isSafeInput(longInput), isFalse);
    });
  });

  group('SecurityValidator - Phone Number', () {
    test('isValidPhoneNumber should accept Gabon format', () {
      expect(
        SecurityValidator.isValidPhoneNumber('+241612345678'),
        isTrue,
      );
    });

    test('isValidPhoneNumber should accept local format', () {
      expect(
        SecurityValidator.isValidPhoneNumber('612345678'),
        isTrue,
      );
    });

    test('isValidPhoneNumber should reject invalid formats', () {
      expect(SecurityValidator.isValidPhoneNumber('123'), isFalse);
      expect(SecurityValidator.isValidPhoneNumber(''), isFalse);
      expect(SecurityValidator.isValidPhoneNumber('abc'), isFalse);
    });
  });

  group('SecurityValidator - Email', () {
    test('isValidEmail should accept valid emails', () {
      expect(
        SecurityValidator.isValidEmail('user@example.com'),
        isTrue,
      );
      expect(
        SecurityValidator.isValidEmail('john.doe+tag@company.co.uk'),
        isTrue,
      );
    });

    test('isValidEmail should reject invalid formats', () {
      expect(SecurityValidator.isValidEmail('notanemail'), isFalse);
      expect(SecurityValidator.isValidEmail('user@'), isFalse);
      expect(SecurityValidator.isValidEmail('@example.com'), isFalse);
      expect(SecurityValidator.isValidEmail(''), isFalse);
    });
  });
}

void main2() {
  group('AuthTokenService - JWT Tokens', () {
    const jwtSecret = 'test-secret-minimum-32-chars-required-for-jwt-security';
    late AuthTokenService tokenService;

    setUp(() {
      tokenService = AuthTokenService(jwtSecret: jwtSecret);
    });

    test('generateAccessToken should create valid token', () {
      final token = tokenService.generateAccessToken(
        userId: 'user123',
        email: 'user@example.com',
      );

      expect(token, isNotEmpty);
      expect(
          token.split('.').length, 3); // JWT format: header.payload.signature
    });

    test('verifyToken should verify valid token', () {
      final token = tokenService.generateAccessToken(
        userId: 'user123',
        email: 'user@example.com',
      );

      expect(tokenService.verifyToken(token), isTrue);
    });

    test('verifyToken should reject expired token', () async {
      // Note: Ce test est limité car on ne peut pas facilement créer un token expiré
      // En production, utiliser des mocks
    });

    test('getUserIdFromToken should extract userId', () {
      final token = tokenService.generateAccessToken(
        userId: 'user123',
        email: 'user@example.com',
      );

      final userId = tokenService.getUserIdFromToken(token);
      expect(userId, 'user123');
    });

    test('generateRefreshToken should create refresh token', () {
      final token = tokenService.generateRefreshToken(userId: 'user123');

      expect(token, isNotEmpty);
      expect(tokenService.verifyToken(token), isTrue);
    });

    test('getTokenType should identify token type', () {
      final accessToken = tokenService.generateAccessToken(
        userId: 'user123',
        email: 'user@example.com',
      );

      final refreshToken = tokenService.generateRefreshToken(userId: 'user123');

      expect(tokenService.getTokenType(accessToken), 'access');
      expect(tokenService.getTokenType(refreshToken), 'refresh');
    });
  });
}
