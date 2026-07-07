// Tests unitaires de SecurityValidator, utilisé par VerificationProvider
// avant tout envoi d'OTP ou de vérification d'identité (argent/sécurité :
// un faux positif ici laisserait passer un numéro ou un ID invalide vers
// l'Edge Function send-otp-sms).

import 'package:flutter_test/flutter_test.dart';
import 'package:mygabon/utils/security_utils.dart';

void main() {
  group('SecurityValidator.isValidPhoneNumber', () {
    test('accepte un numéro gabonais local (9 chiffres)', () {
      expect(SecurityValidator.isValidPhoneNumber('061234567'), true);
    });

    test('accepte un numéro au format international', () {
      expect(SecurityValidator.isValidPhoneNumber('+24106123456'), true);
    });

    test('rejette un numéro trop court', () {
      expect(SecurityValidator.isValidPhoneNumber('12345'), false);
    });

    test('rejette un numéro trop long', () {
      expect(SecurityValidator.isValidPhoneNumber('123456789012345'), false);
    });
  });

  group('SecurityValidator.isValidEmail', () {
    test('accepte un email valide', () {
      expect(SecurityValidator.isValidEmail('jean@mygabon.ga'), true);
    });

    test('rejette un email sans domaine', () {
      expect(SecurityValidator.isValidEmail('jean@mygabon'), false);
    });
  });

  group('SecurityValidator.isValidIdFormat', () {
    test('rejette un identifiant vide', () {
      expect(SecurityValidator.isValidIdFormat(''), false);
    });

    test('rejette un identifiant trop court', () {
      expect(SecurityValidator.isValidIdFormat('AB12'), false);
    });

    test('accepte un identifiant de longueur plausible', () {
      expect(SecurityValidator.isValidIdFormat('GA123456789'), true);
    });
  });
}
