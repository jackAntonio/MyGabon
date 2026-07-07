// Tests unitaires de la validation de numéro Kpay (Airtel Money Gabon).
// Ne teste que la logique pure (normalisation + regex) : les appels réseau
// (Supabase.instance.client.functions.invoke) exigent un vrai projet
// Supabase initialisé et sortent du périmètre d'un test unitaire — cf.
// README.md pour la configuration d'un environnement Supabase de test si
// une couverture d'intégration est ajoutée plus tard.

import 'package:flutter_test/flutter_test.dart';
import 'package:mygabon/services/kpay_service.dart';

void main() {
  group('KpayService.isValidGabonPhone', () {
    test('accepte un numéro local au format 0X XX XX XX XX', () {
      expect(kpayService.isValidGabonPhone('06123456'), true);
      expect(kpayService.isValidGabonPhone('07123456'), true);
    });

    test('accepte un numéro déjà au format international avec +', () {
      expect(kpayService.isValidGabonPhone('+24106123456'), true);
    });

    test('accepte un numéro international sans le +', () {
      expect(kpayService.isValidGabonPhone('24106123456'), true);
    });

    test('accepte un numéro avec espaces ou tirets', () {
      expect(kpayService.isValidGabonPhone('06 12 34 56'), true);
      expect(kpayService.isValidGabonPhone('+241-06-12-34-56'), true);
    });

    test('rejette un numéro trop court', () {
      expect(kpayService.isValidGabonPhone('123'), false);
    });

    test('rejette une chaîne vide', () {
      expect(kpayService.isValidGabonPhone(''), false);
    });
  });

  group('KpayService.formatPrice', () {
    test('formate un montant en FCFA sans décimales', () {
      expect(kpayService.formatPrice(10500), '10500 FCFA');
    });

    test('arrondit un montant décimal', () {
      expect(kpayService.formatPrice(9999.6), '10000 FCFA');
    });
  });
}
