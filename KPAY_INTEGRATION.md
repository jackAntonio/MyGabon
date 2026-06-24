# 🔐 Intégration Kpay - Paiement Airtel Money (Gabon)

## 📋 Vue d'ensemble

Kpay (https://kpay.site) est l'agrégateur mobile money utilisé par MyGabon
pour les paiements **Airtel Money** au Gabon (provider `AIRTEL_GAB`, seul
opérateur Gabon listé dans leur documentation officielle — **Moov Money
Gabon n'est pas supporté par Kpay** et n'est donc pas proposé dans l'app).

⚠️ Toutes les infos ci-dessous viennent de https://kpay.site/documentation
(consultée le 2026-06-25). Aucune valeur n'est inventée, mais aucun compte
marchand réel n'a encore été testé en conditions réelles — à valider à la
première transaction sandbox.

### ✅ Fonctionnalités
- Initiation de paiement Airtel Money (mode USSD)
- Validation directe par le client sur son téléphone (pas d'OTP saisi dans l'app)
- Webhook serveur-à-serveur comme seule autorité sur le statut final
- Polling de statut possible en complément (`GET /payments/:id`)

---

## 🏗️ Architecture (important)

**Aucune clé Kpay ne vit dans l'app Flutter.** `X-API-Key` et surtout
`X-Secret-Key` (explicitement nommée "Secret key" par Kpay) ne doivent
jamais être compilées dans un binaire mobile, extractible d'un APK/IPA —
règle explicite du projet ("Jamais exposer les clés API paiement dans le
code Flutter").

```
App Flutter (KpayService)
   │  supabase.functions.invoke('kpay-initiate', {transactionId, phoneNumber})
   │  (JWT de l'utilisateur connecté, pas de secret Kpay)
   ▼
Edge Function kpay-initiate (supabase/functions/kpay-initiate)
   │  vérifie via RLS que l'appelant est bien l'acheteur de la transaction
   │  POST https://admin.kpay.site/api/v1/payments/init
   │  Headers: X-API-Key + X-Secret-Key (secrets Edge Function)
   ▼
Kpay → SMS/USSD envoyé au téléphone de l'acheteur → il valide avec son code PIN mobile money
   │
   ▼
Kpay envoie un webhook serveur-à-serveur (signature HMAC)
   ▼
Edge Function kpay-webhook (supabase/functions/kpay-webhook)
   │  vérifie la signature, appelle confirm_external_payment / fail_external_payment
   │  (RPC réservées au rôle service_role, jamais au client)
   ▼
transactions.status passe à 'success'/'failed' → l'app l'observe via Supabase Realtime
```

Le client (`mobile_money_screen.dart`) ne fait jamais que : créer la
transaction, demander l'initiation, puis **attendre** la confirmation
serveur. Il ne peut jamais déclarer lui-même un paiement réussi.

---

## 🚀 Configuration

### 1. Compte marchand Kpay
1. https://kpay.site → créer un compte, créer une "Application" dans le dashboard
2. Récupérer la paire de clés sandbox : `kpay_test_...` (X-API-Key) et `sk_test_...` (X-Secret-Key)
3. Compléter le KYC pour obtenir les clés `kpay_live_...` / `sk_live_...` en production

### 2. Secrets Edge Functions (jamais dans env.json / --dart-define)

```bash
supabase functions deploy kpay-initiate
supabase functions deploy kpay-webhook
supabase secrets set KPAY_API_KEY=kpay_test_xxxxx
supabase secrets set KPAY_SECRET_KEY=sk_test_xxxxx
supabase secrets set KPAY_WEBHOOK_SECRET=xxxxx
```

### 3. Webhook côté dashboard Kpay
Dans le dashboard Kpay (Application → Webhooks), configurer l'URL de
callback (dépôts) :
```
https://<project-ref>.supabase.co/functions/v1/kpay-webhook
```

---

## 🔄 Flux de paiement réel

1. **Initiation** : `mobile_money_screen.dart` crée la transaction Supabase
   (`status='pending'`, `payment_method='airtel_money'`), puis appelle
   `KpayService().initiateAirtelMoneyPayment(transactionId, phoneNumber)`.
2. **Edge Function `kpay-initiate`** vérifie que l'appelant est l'acheteur,
   puis `POST /payments/init` avec `{amount, provider: 'AIRTEL_GAB',
   phoneNumber, externalId: transactionId}`.
3. **Validation utilisateur** : Kpay déclenche la procédure côté opérateur
   (USSD). L'utilisateur valide directement sur son téléphone avec son code
   PIN Airtel Money — **il n'y a pas d'OTP à saisir dans l'app MyGabon**
   (contrairement à ce que décrivait une version précédente de ce doc).
4. **Confirmation** : Kpay envoie un webhook server-to-server à
   `kpay-webhook`, qui vérifie la signature puis crédite le vendeur et passe
   la transaction à `success`/`failed`.
5. **L'app observe** ce changement via `SupabaseService().watchTransactionStatus()`
   (Supabase Realtime) et navigue vers l'écran de succès.

---

## 🌍 Pays et opérateurs supportés (Kpay, /documentation/providers)

| Pays | Opérateurs |
|---|---|
| Bénin | `MTN_MOMO_BEN`, `MOOV_BEN` |
| Cameroun | `MTN_MOMO_CMR`, `ORANGE_CMR` |
| Côte d'Ivoire | `MTN_MOMO_CIV`, `ORANGE_CIV` |
| RD Congo | `VODACOM_MPESA_COD`, `AIRTEL_COD`, `ORANGE_COD` |
| **Gabon** | **`AIRTEL_GAB`** (seul opérateur — pas de Moov) |
| Congo | `AIRTEL_COG`, `MTN_MOMO_COG` |
| Rwanda | `AIRTEL_RWA`, `MTN_MOMO_RWA` |
| Kenya | `MPESA_KEN` |
| Sénégal | `FREE_SEN`, `ORANGE_SEN` |
| Ouganda | `AIRTEL_OAPI_UGA`, `MTN_MOMO_UGA` |
| Zambie | `AIRTEL_OAPI_ZMB`, `MTN_MOMO_ZMB`, `ZAMTEL_ZMB` |

---

## 📡 Référence API

**Base URL** : `https://admin.kpay.site/api/v1`

**Authentification** (headers sur chaque requête) :
```
X-API-Key: kpay_test_xxxxx   (ou kpay_live_xxxxx en prod)
X-Secret-Key: sk_test_xxxxx  (ou sk_live_xxxxx en prod)
Content-Type: application/json
```

**Initier un paiement** — `POST /payments/init`
```json
{ "amount": 5000, "provider": "AIRTEL_GAB", "phoneNumber": "24106XXXXXXX", "externalId": "<notre transactions.id>" }
```
Réponse `201` :
```json
{ "id": "pay_abc123", "status": "PENDING", "reference": "KPAY-...", "amount": 5000, "currency": "XAF", "provider": "AIRTEL_GAB", "phoneNumber": "..." }
```

**Vérifier le statut** — `GET /payments/:id` → même forme, `status` parmi
`PENDING | PROCESSING | COMPLETED | FAILED | CANCELLED`.

**Codes d'échec (sandbox)** : `PAYER_LIMIT_REACHED`, `PAYER_NOT_FOUND`,
`PAYMENT_NOT_APPROVED`, `UNSPECIFIED_FAILURE`, `RECIPIENT_NOT_FOUND`.

---

## 🔐 Webhook (`/documentation/webhooks`)

- Header de signature : **`X-KPAY-Signature`**
- Algorithme : **HMAC-SHA256 (hex), calculé sur le corps brut JSON reçu**
  (pas re-sérialisé) — comparaison en temps constant côté serveur.
- Payload :
```json
{
  "event": "payment.completed",
  "paymentId": "pay_abc123",
  "reference": "KPAY-DEP-12345",
  "status": "COMPLETED",
  "amount": 5000,
  "phoneNumber": "24106XXXXXXX",
  "externalId": "<notre transactions.id>",
  "metadata": {},
  "completedAt": "2026-05-14T10:02:30.000Z",
  "failedAt": null,
  "failureReason": null,
  "timestamp": "2026-05-14T10:02:31.000Z"
}
```
On retrouve notre transaction par **`externalId`** (jamais par `reference`,
qui est un identifiant interne Kpay). `status` : `COMPLETED | FAILED | CANCELLED`.

---

## 🧪 Numéros de test sandbox

⚠️ La documentation Kpay ne liste des numéros de test que pour le **Cameroun**
(`MTN_MOMO_CMR`/`ORANGE_CMR`). **Aucun numéro de test n'est documenté pour
`AIRTEL_GAB`** — à demander au support Kpay avant de tester en sandbox sur
le Gabon, ou à découvrir empiriquement une fois les clés `kpay_test_...`
obtenues.

Numéros Cameroun connus (pour référence du mécanisme) :
- `237653456789` → `COMPLETED` (succès garanti)
- `237653456129` → `SUBMITTED` (reste en attente)
- `237653456019/029/039/069` → `FAILED` (codes d'échec différents)

---

## 📊 Suivi des transactions (Supabase)

```sql
SELECT * FROM transactions
WHERE payment_method = 'airtel_money'
ORDER BY created_at DESC;
```

Colonnes clés : `gross_amount`, `visible_fee`/`actual_fee` (5% chacun,
identiques — pas de frais caché), `net_to_seller`, `status`
(`pending`/`success`/`failed`), `transaction_reference` (= `paymentId` Kpay
une fois confirmé), `notes` (raison d'échec si applicable).

---

## ⚠️ Sans credentials Kpay réels

Sans `KPAY_API_KEY`/`KPAY_SECRET_KEY` configurées comme secrets des Edge
Functions, `kpay-initiate` répond `503 Kpay non configuré côté serveur` —
l'app affiche l'erreur, ne plante pas. Pas de mode simulation automatique.

---

## ✅ Checklist avant mise en production

- [ ] Compte marchand Kpay + KYC validé (clés `kpay_live_...`)
- [ ] `supabase secrets set KPAY_API_KEY=... KPAY_SECRET_KEY=... KPAY_WEBHOOK_SECRET=...`
- [ ] `supabase functions deploy kpay-initiate kpay-webhook`
- [ ] URL de webhook configurée dans le dashboard Kpay
- [ ] Test de bout en bout avec un vrai numéro Airtel Money Gabon
- [ ] Vérifier que `transactions.status` passe bien à `success` et que le wallet vendeur est crédité

---

**MyGabon + Kpay** | Paiement Airtel Money Gabon, confirmé exclusivement côté serveur | 🔐
