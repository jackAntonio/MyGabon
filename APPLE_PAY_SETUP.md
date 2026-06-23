# 🍎 Configuration Apple Pay pour MyGabon

## Installation des dépendances

```bash
flutter pub get
```

Le package `pay: ^2.1.0` sera installé automatiquement.

---

## Configuration iOS

### 1. Activer Apple Pay dans Xcode

```bash
cd ios
open Runner.xcworkspace
```

**Dans Xcode:**
1. Sélectionnez `Runner` → Target `Runner`
2. Allez dans `Signing & Capabilities`
3. Cliquez sur `+ Capability`
4. Cherchez et ajoutez `Apple Pay`

### 2. Configurer les Merchant IDs

**Dans Capabilities > Apple Pay:**
- Cliquez sur le `+` pour ajouter un Merchant ID
- Format: `merchant.com.mygabon.app` (ou votre domaine)

### 3. Info.plist - Configuration

Ajoutez à `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>MyGabon a besoin d'accéder à votre réseau local pour les paiements</string>
<key>NSBonjourServiceTypes</key>
<array>
  <string>_http._tcp</string>
</array>
```

---

## Configuration Android

### 1. Fichier `build.gradle`

Vérifiez que `android/app/build.gradle` contient:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Important pour Google Pay
    }
}
```

### 2. Permissions `AndroidManifest.xml`

Ajoutez à `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

## Utilisation dans l'app

### Importer le service

```dart
import 'package:mygabon/services/apple_pay_service.dart';

final applePayService = ApplePayService();
```

### Initialiser au démarrage

```dart
void main() async {
  // ... autres initialisations
  await applePayService.init();
  runApp(const MyGabonApp());
}
```

### Utiliser dans le checkout

```dart
// Vérifier disponibilité
final isAvailable = await applePayService.isAvailable();

if (isAvailable) {
  final success = await applePayService.processPayment(
    product: product,
    totalAmount: totalAmount,
    visibleFee: visibleFee,
    countryCode: 'GA', // Gabon
  );
}
```

---

## Structure de paiement

### Flux de paiement complet:

```
1. Marketplace Detail Screen
        ↓
2. Payment Method Selection Screen ← NOUVEAU
        ↓
   ┌────────────┬────────────┬──────────────┬──────────┐
   ↓            ↓            ↓              ↓          ↓
Apple Pay   Google Pay   MyGabon    Airtel Money   Cash
              Wallet
   ↓            ↓            ↓              ↓          ↓
Success    Success    Checkout      OTP Modal    Modal
Screen     Screen     Screen        Screen       Info
```

---

## Montants de transaction

Les montants sont traités en **FCFA** (devises du Gabon):

```dart
// Exemple: 850 000 FCFA
double amount = 850000;

// Apple Pay affiche: "8 500,00 XOF" ou "850 000 FCFA"
// selon la configuration du device
```

### Structure des frais:

```
Prix du produit:      850 000 FCFA
Frais visibles (5%):  +42 500 FCFA
─────────────────────────────────
Total à payer:        892 500 FCFA

Frais réels (10%):    85 000 FCFA (déducte au paiement)
Net au vendeur:       765 000 FCFA
```

---

## Sécurité

✅ **Données chiffrées en transit** (TLS 1.2+)
✅ **Pas d'exposition de numéros de carte** (Apple Pay / Google Pay gèrent)
✅ **Validation côté serveur obligatoire** (à implémenter)
✅ **Audit logging** pour tous les paiements

---

## Intégration Supabase (À implémenter)

Enregistrer les paiements Apple Pay:

```dart
await supabaseService.logTransaction(
  transactionType: 'apple_pay',
  amount: totalAmount,
  currency: 'XOF',
  status: 'success',
  metadata: {
    'paymentMethod': 'apple_pay',
    'deviceType': 'ios',
  },
);
```

---

## Test en développement

### iOS Simulator

```bash
flutter run -d "iPhone 15"
```

**Note:** Apple Pay fonctionne UNIQUEMENT sur device réel, pas en simulator.

### Android Emulator

```bash
flutter run -d emulator-5554
```

Google Pay nécessite des services Google Play (GMS).

---

## Troubleshooting

| Problème | Solution |
|----------|----------|
| "Apple Pay not available" | Vérifier que device a Apple Pay configuré + Merchant ID valide |
| "Capability not found" | Relancer `flutter clean && flutter pub get` |
| "PlatformException" | Vérifier Merchant ID dans Info.plist |
| "Payment cancelled" | L'utilisateur a annulé (comportement normal) |

---

## Coûts & Frais

- **Apple Pay:** Aucun frais direct (votre processeur de paiement facture)
- **Google Pay:** Même que Apple Pay
- **MyGabon Wallet:** 5% visible + 5% caché
- **Airtel Money:** Déterminé par Kpay

---

## Prochaines étapes

1. ✅ Service ApplePayService créé
2. ✅ Écran de sélection de méthode créé
3. ⏳ Intégrer ApplePayService dans payment_method_selection_screen.dart
4. ⏳ Configurer Merchant ID réel
5. ⏳ Implémenter webhook de paiement Supabase
6. ⏳ Tester sur device réel iOS

---

## Ressources

- [Flutter Pay Plugin](https://pub.dev/packages/pay)
- [Apple Pay Integration Guide](https://developer.apple.com/apple-pay/implementation/)
- [Google Pay Integration Guide](https://developers.google.com/pay)
- [MyGabon API Docs](./docs/api.md)
