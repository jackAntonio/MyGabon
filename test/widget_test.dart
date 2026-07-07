// Tests unitaires du calcul des frais de transaction MyGabon.
//
// L'ancien test du template Flutter référençait une classe `MyApp` inexistante
// (l'app s'appelle MyGabonApp) et faisait échouer `flutter test`.
// Pomper MyGabonApp ici exigerait de mocker Supabase/Hive ; on teste donc
// la logique métier pure (PaymentService), partagée entre l'écran de paiement
// et l'estimation affichée à la publication d'une annonce.

import 'package:flutter_test/flutter_test.dart';
import 'package:mygabon/services/payment_service.dart';

void main() {
  group('PaymentService.calculateFees', () {
    test('applique 5% de frais sur un montant standard', () {
      final fees = PaymentService.calculateFees(10000);

      expect(fees.visibleFee, 500);
      expect(fees.actualFee, 500);
      expect(fees.netToSeller, 9500);
      expect(fees.totalWithVisibleFee, 10500);
    });

    test('frais affiché et frais prélevé restent identiques', () {
      // Règle produit : aucun écart caché entre le frais montré à l'acheteur
      // et celui réellement prélevé au vendeur.
      final fees = PaymentService.calculateFees(123456);

      expect(fees.visibleFee, fees.actualFee);
      expect(fees.netToSeller + fees.actualFee, closeTo(123456, 0.001));
    });

    test('montant nul : aucun frais, aucun net vendeur', () {
      final fees = PaymentService.calculateFees(0);

      expect(fees.visibleFee, 0);
      expect(fees.netToSeller, 0);
      expect(fees.totalWithVisibleFee, 0);
    });

    test('la livraison standard MyGabon est fixée à 5000 FCFA', () {
      expect(PaymentService.standardDeliveryFee, 5000);
    });
  });
}
