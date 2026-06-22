# 🔐 Intégration Kpay - Paiements Airtel Money

## 📋 Vue d'ensemble

Kpay est la solution de paiement intégrée pour MyGabon permettant les paiements **Airtel Money** en Afrique Centrale, particulièrement au Gabon.

### ✅ Fonctionnalités
- Initiation de paiement Airtel Money
- Vérification OTP automatique
- Confirmation de paiement
- Gestion des erreurs
- Support multi-devises (XAF, USD, EUR)
- Webhooks pour notifications

---

## 🚀 Configuration Kpay

### 1. Créer un compte Kpay

1. Aller sur: https://kpay.africa
2. S'inscrire en tant que marchand
3. Vérifier votre email
4. Créer votre profil marchand

### 2. Obtenir les credentials

#### Dashboard Kpay
- Aller dans **Settings → API Keys**
- Copier:
  - `API_KEY` (clé API secrète)
  - `MERCHANT_ID` (identifiant commerçant)
  - `WEBHOOK_SECRET` (optionnel, pour les notifications)

### 3. Configurer .env

```bash
# .env
KPAY_API_KEY=your_api_key_from_kpay_dashboard
KPAY_MERCHANT_ID=your_merchant_id_from_kpay_dashboard
KPAY_WEBHOOK_SECRET=your_webhook_secret_optional
```

### 4. Configuration du Webhook (optionnel)

```bash
# Dans Kpay Dashboard:
# Settings → Webhooks
# Callback URL: https://mygabon.app/api/payment/callback
# Return URL: mygabon://payment-success

# Notez le WEBHOOK_SECRET généré
```

---

## 🔄 Flux de Paiement Airtel Money

### 1. Checkout (CheckoutScreenComplete)
```
Utilisateur clique "Payer via Airtel Money"
    ↓
Choisit numéro Airtel (06XXXXXXXX ou +241XXXXXXXX)
    ↓
Clique "Procéder au paiement"
```

### 2. Initiation (AirtelMoneyScreen)
```
App appelle: kpay.initiateAirtelPayment()
    ↓
Kpay envoie SMS avec instruction à l'utilisateur
    ↓
Utilisateur voit écran "Envoi du code OTP"
```

### 3. Saisie OTP
```
Utilisateur reçoit OTP sur son téléphone Airtel
    ↓
Rentre le code OTP (6 chiffres)
    ↓
Timer: 60 secondes avant expiration
```

### 4. Confirmation
```
App appelle: kpay.confirmAirtelPayment(transactionId, otp)
    ↓
Kpay valide l'OTP auprès d'Airtel Money
    ↓
Paiement confirmé ✅
    ↓
Écran de succès avec reçu
```

---

## 📱 Numéros de Téléphone Acceptés

### Format Gabon
```
✅ Acceptés:
- +241XXXXXXXX (format international)
- 06XXXXXXXX (format local)
- 237XXXXXXXX (code pays)

❌ Rejetés:
- 06 XXXX XXXX (espaces)
- 06-XXXX-XXXX (tirets)
- XXXXXXXX (sans préfixe)
```

### Validation
```dart
if (!kpayService.isValidGabonPhone(phoneNumber)) {
  // Afficher erreur
}
```

---

## 💰 Montants et Devises

### Devises supportées
```
XAF  - Franc CFA (Gabon) - Défaut
USD  - Dollar américain
EUR  - Euro
GBP  - Livre sterling
```

### Montants minimums/maximums
```
Minimum: 100 FCFA
Maximum: 10 000 000 FCFA (par transaction)
```

### Exemple de transaction
```dart
final response = await kpay.initiateAirtelPayment(
  phoneNumber: '+241612345678',
  amount: 850000,  // 850 000 FCFA
  productName: 'iPhone 14 Pro',
  productId: 'prod_12345',
);
```

---

## ⚠️ Gestion des Erreurs

### Codes d'erreur Kpay

```
'INVALID_PHONE'         → Numéro invalide
'INSUFFICIENT_BALANCE'  → Solde insuffisant
'OTP_EXPIRED'          → OTP expiré
'OTP_INVALID'          → OTP incorrect
'TRANSACTION_FAILED'   → Paiement échoué
'NETWORK_ERROR'        → Problème connexion
```

### Gestion dans l'app

```dart
try {
  final response = await kpay.initiateAirtelPayment(...);
  if (response.success) {
    // Succès
  } else {
    // Erreur: response.message
  }
} on KpayException catch (e) {
  // Gérer l'exception
  showErrorSnackBar(e.message);
}
```

---

## 🔍 Vérification du Statut

### Vérifier manuellement le statut
```dart
final status = await kpay.checkPaymentStatus(
  transactionId: 'txn_123456',
);

if (status.isCompleted) {
  print('Paiement confirmé');
} else if (status.isPending) {
  print('En attente...');
} else if (status.isFailed) {
  print('Paiement échoué');
}
```

### Propriétés du statut
```dart
KpayPaymentStatus {
  transactionId: String,
  status: String,           // 'completed', 'pending', 'failed'
  amount: double,
  phoneNumber: String,
  paidAt: DateTime?,
  message: String?,
}
```

---

## 🔐 Webhooks & Callbacks

### Configuration des webhooks

1. **Callback URL** - Pour les notifications serveur
   ```
   https://mygabon.app/api/payment/callback
   ```

2. **Return URL** - Deep link après paiement
   ```
   mygabon://payment-success
   ```

### Vérifier la signature webhook

```dart
bool isValid = kpayService.verifyWebhookSignature(
  payload: jsonEncode(webhookData),
  signature: headerSignature,
);

if (isValid) {
  // Traiter le webhook en confiance
}
```

### Exemple de payload webhook

```json
{
  "transaction_id": "txn_123456",
  "status": "completed",
  "amount": 850000,
  "currency": "XAF",
  "phone_number": "+241612345678",
  "reference": "prod_12345",
  "timestamp": "2026-06-22T10:30:00Z",
  "signature": "base64_encoded_signature"
}
```

---

## 📊 Suivi des Transactions

### Dans Supabase

Les transactions Kpay sont stockées dans la table `transactions`:

```sql
SELECT * FROM transactions 
WHERE payment_method = 'airtel_money' 
ORDER BY created_at DESC;
```

### Colonnes importantes

```sql
transaction_id      -- ID unique Kpay
buyer_id           -- Utilisateur qui paie
seller_id          -- Vendeur qui reçoit
product_id         -- Produit acheté
gross_amount       -- Montant brut
visible_fee        -- Frais visibles (5%)
actual_fee         -- Frais réels (10%)
net_to_seller      -- Montant net au vendeur
payment_method     -- 'airtel_money'
status             -- 'pending', 'success', 'failed'
created_at         -- Timestamp création
completed_at       -- Timestamp confirmation
```

---

## 🧪 Mode Test/Simulation

### Sans credentials Kpay réels

Si `KPAY_API_KEY` ou `KPAY_MERCHANT_ID` manquent, l'app utilise la **simulation**:

```dart
// Toujours simulé en développement
if (kpayApiKey == null || kpayMerchantId == null) {
  debugPrint('⚠️ Kpay credentials non trouvés - mode simulation');
  // Les paiements sont simulés localement
}
```

### Paiements simulés

```
Numéro test: 06XXXXXXXX
OTP test: 123456
Montant test: Tous les montants acceptés
Résultat: Succès garanti en simulation
```

---

## 📞 Support Kpay

### Documentation
- https://kpay.africa/docs
- https://api.kpay.africa/docs

### API Endpoints

```
Base URL: https://api.kpay.africa/api/v1

POST   /payments/initiate      → Initier un paiement
POST   /payments/confirm       → Confirmer avec OTP
GET    /payments/status/:id    → Vérifier le statut
POST   /payments/refund        → Remboursement
```

### Support technique
- Email: support@kpay.africa
- Phone: +237 XXX XXX XXX
- Slack: kpay-support.slack.com

---

## ✅ Checklist d'implémentation

- [ ] Créer compte Kpay
- [ ] Obtenir API_KEY et MERCHANT_ID
- [ ] Ajouter credentials dans .env
- [ ] Tester avec numéro réel (mode production)
- [ ] Configurer webhooks (optionnel)
- [ ] Tester flux complet de paiement
- [ ] Vérifier transactions dans Supabase
- [ ] Mettre à jour support client

---

## 🎯 Prochaines étapes

### Phase 1 - Actuel (Production)
- [x] Intégration Kpay complète
- [x] Paiements Airtel Money
- [x] Gestion OTP
- [x] Écran de succès

### Phase 2 - À venir
- [ ] Remboursements automatiques
- [ ] Paiements récurrents
- [ ] Porte-monnaie Airtel Money
- [ ] Support Orange Money
- [ ] Support MTN Money
- [ ] Paiements par scan QR

### Phase 3 - Avancé
- [ ] Paiements B2B
- [ ] Factures automatiques
- [ ] Réconciliation comptable
- [ ] Rapports d'audit
- [ ] API pour partenaires

---

## 📝 Notes

- Les frais Kpay sont déjà inclus dans `actual_fee`
- Les frais visibles (5%) sont affichés à l'utilisateur
- Les frais réels (10%) incluent commission Kpay (~3%) + commission MyGabon (7%)
- Les remboursements sont manuels actuellement
- Support multi-devise via Kpay (conversion automatique)

---

**MyGabon + Kpay** | Paiements Airtel Money sécurisés | 🔐

