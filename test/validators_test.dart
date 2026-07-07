// Tests unitaires des validateurs de formulaire (email, téléphone, champ
// requis) utilisés notamment sur l'écran de sélection de méthode de
// paiement (numéro Airtel Money) et les formulaires d'inscription.

import 'package:flutter_test/flutter_test.dart';
import 'package:mygabon/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('rejette une valeur vide ou nulle', () {
      expect(Validators.validateEmail(null), 'Required');
      expect(Validators.validateEmail(''), 'Required');
    });

    test('rejette un email sans arobase ou sans domaine', () {
      expect(Validators.validateEmail('jean.mbadinga'), 'Invalid email');
      expect(Validators.validateEmail('jean@mbadinga'), 'Invalid email');
    });

    test('accepte un email valide', () {
      expect(Validators.validateEmail('jean.mbadinga@gmail.com'), null);
    });
  });

  group('Validators.validatePhone', () {
    test('rejette une valeur vide ou nulle', () {
      expect(Validators.validatePhone(null), 'Required');
      expect(Validators.validatePhone(''), 'Required');
    });

    test('rejette un numéro trop court', () {
      expect(Validators.validatePhone('123'), 'Invalid phone');
    });

    test('accepte un numéro gabonais local ou international', () {
      expect(Validators.validatePhone('06123456'), null);
      expect(Validators.validatePhone('+24106123456'), null);
    });
  });

  group('Validators.validateNotEmpty', () {
    test('rejette une valeur vide ou nulle', () {
      expect(Validators.validateNotEmpty(null), 'Required');
      expect(Validators.validateNotEmpty(''), 'Required');
    });

    test('accepte une valeur non vide', () {
      expect(Validators.validateNotEmpty('Libreville'), null);
    });
  });
}
