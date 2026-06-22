# 🚀 KPAY Production - Guide de Test

## ✅ Configuration Actuelle

```
MODE: PRODUCTION ✅
API_KEY: kpay_live_1aa96e6134ec1205d50d11b19e44ef4962e783839f5bdef7
MERCHANT_ID: c21f2e54d0ae97ee48da5f3cb15ef19328d577d111fcc06b50c4ed68c35edf00
SUPABASE: https://kbggddignhydzxjzdera.supabase.com
```

---

## ⚠️ ATTENTION PRODUCTION

```
🚨 LES PAIEMENTS SONT RÉELS 🚨

Chaque paiement testé va:
✓ Débiter un vrai compte Airtel Money
✓ Créditer le compte marchand Kpay
✓ Être enregistré dans Supabase
✓ Générer des frais réels

RÈGLES DE TEST:
1. Utiliser PETIT montant d'abord (1000 FCFA)
2. Avoir un numéro Airtel Money réel avec solde
3. Vérifier chaque étape avant de continuer
4. Garder trace de tous les tests
```

---

## 🔧 Préparation

### Étape 1: Vérifier le .env
```bash
# Ouvrir c:\Users\HP\Downloads\MyGabon\.env
# Vérifier ces lignes existent:

KPAY_API_KEY=kpay_live_1aa96e6134ec1205d50d11b19e44ef4962e783839f5bdef7
KPAY_MERCHANT_ID=c21f2e54d0ae97ee48da5f3cb15ef19328d577d111fcc06b50c4ed68c35edf00
```

### Étape 2: Préparer l'app
```bash
cd c:\Users\HP\Downloads\MyGabon
flutter clean
flutter pub get
flutter run -d chrome --no-browser
```

### Étape 3: Vérifier les logs
```bash
# Dans le terminal, tu devrais voir:
✅ Supabase initialisé
✅ Kpay initialisé
```

---

## 🧪 Flux de Test Complet

### Test 1: Authentification
```
1. Aller sur l'app Flutter (localhost)
2. Créer un compte test:
   Email: test@mygabon.com
   Password: Test123456!
3. Vérifier la connexion ✓
```

### Test 2: Voir un produit
```
1. Cliquer sur "Accueil"
2. Cliquer sur un produit (ex: iPhone 14 Pro)
3. Voir les détails ✓
```

### Test 3: Paiement MyGabon (Simulation)
```
1. Cliquer "Payer via MyGabon"
2. Voir CheckoutScreen
3. Voir solde wallet: 485,750 FCFA
4. Cliquer "Procéder au paiement"
5. Voir écran de succès ✓
```

### Test 4: Paiement Airtel Money (RÉEL) ⚠️
```
1. Retourner à un produit
2. Cliquer "Payer via Airtel Money"
3. Entrer numéro Airtel:
   Format: 06XXXXXXXX ou +241XXXXXXXX
   Exemple: 06612345678
4. Cliquer "Procéder au paiement"
```

### Test 5: Écran Initiation Kpay
```
Tu devrais voir:
✓ Animation phone icon (pulsante)
✓ "Paiement Airtel Money"
✓ Montant: 893,750 FCFA (avec frais 5%)
✓ Numéro: 06612345678
✓ Produit: iPhone 14 Pro

Étape 1: ✓ Envoi du code
Étape 2: ⚙ Vérification OTP
Étape 3:   Paiement confirmé

"Envoi du code OTP en cours..."
Loading spinner
```

### Test 6: Réception SMS OTP
```
⏳ Attendre 15-30 secondes
📱 Tu reçois SMS d'Airtel Money:
   "Code OTP: 123456
    Valable 60 secondes"
```

### Test 7: Saisie OTP
```
1. Voir écran "Code OTP"
2. Saisir le code reçu: 123456
3. Timer: "45 secondes restantes"
4. Cliquer "Confirmer le paiement"
```

### Test 8: Confirmation et Succès
```
Tu devrais voir:
✓ "⚙ Confirming payment..."
✓ "✓ Paiement réussi!"
✓ ID Transaction: txn_123456
✓ Montant: 893,750 FCFA
✓ Date/Heure: 22/06/2026 10:30
✓ Boutons: "Retour" et "Télécharger reçu"
```

---

## 📊 Vérifications Post-Paiement

### Dans Supabase
```sql
-- Vérifier la transaction dans Supabase
SELECT * FROM transactions 
WHERE payment_method = 'airtel_money'
ORDER BY created_at DESC
LIMIT 1;

Devrait afficher:
✓ buyer_id: ton ID utilisateur
✓ gross_amount: 850000
✓ visible_fee: 42500
✓ actual_fee: 85000
✓ status: 'success'
✓ payment_method: 'airtel_money'
```

### Compte Kpay
```
1. Aller à https://dashboard.kpay.africa
2. Transactions → Récentes
3. Chercher ta transaction
4. Status: ✓ Confirmée
5. Montant débité: ✓ Visible
```

### Compte Airtel Money
```
1. Ouvrir USSD: *143#
2. Vérifier solde réduit de 893,750 FCFA
3. Voir transaction de paiement
```

---

## 🐛 Troubleshooting

### Erreur: "INVALID_PHONE"
```
Cause: Numéro Gabon mal formaté
Solution: 
✓ 06XXXXXXXX (8 chiffres après 06)
✓ +241XXXXXXXX (8 chiffres après 241)
❌ 06 XXXX XXXX (pas d'espaces)
❌ XXXXXXXX (sans préfixe)
```

### Erreur: "OTP_EXPIRED"
```
Cause: OTP valid 60 secondes seulement
Solution:
✓ Entrer le code rapidement
✓ Ne pas attendre jusqu'à 0 secondes
✓ Si expiré, cliquer "Réessayer"
```

### Erreur: "OTP_INVALID"
```
Cause: Mauvais code OTP tapé
Solution:
✓ Vérifier le SMS reçu
✓ Copier-coller le code
✓ Vérifier pas d'espaces au début/fin
```

### Erreur: "INSUFFICIENT_BALANCE"
```
Cause: Compte Airtel Money pas assez de solde
Solution:
✓ Recharger le compte Airtel Money
✓ Teste avec montant plus petit (1000 FCFA)
✓ Vérifier le solde avant de payer
```

### Erreur: "TRANSACTION_FAILED"
```
Cause: Problème réseau ou Kpay
Solution:
✓ Vérifier connexion internet
✓ Attendre quelques secondes
✓ Cliquer "Réessayer"
✓ Contacter support@kpay.africa si persiste
```

### Écran reste sur "Envoi du code OTP..."
```
Cause: Possible lenteur réseau ou timeout
Solution:
✓ Attendre 30 secondes
✓ Si pas de SMS, cliquer "Réessayer"
✓ Vérifier numéro Airtel Money correct
```

---

## 📋 Checklist de Test

### Avant de lancer
- [ ] .env contient API_KEY et MERCHANT_ID
- [ ] Connection internet stable
- [ ] Numéro Airtel Money prêt
- [ ] Solde suffisant sur Airtel Money (>900,000 FCFA)
- [ ] Terminal Flutter affiche "Kpay initialisé"

### Pendant le test
- [ ] App charge sans erreurs
- [ ] Authentification fonctionne
- [ ] Produits s'affichent
- [ ] Checkout affiche montant correct
- [ ] Écran Airtel Money s'ouvre
- [ ] SMS OTP reçu sous 30 secondes
- [ ] OTP saisi correctement
- [ ] Écran de succès affiche

### Après le test
- [ ] Transaction visible dans Supabase
- [ ] Montant débité du compte Airtel Money
- [ ] Montant crédité dans Kpay dashboard
- [ ] Frais calculés correctement (5% visible, 10% réel)
- [ ] Status en base de données: 'success'

---

## 💰 Montants de Test Recommandés

```
Test 1 - Montant minimal:
  Produit: 10 000 FCFA
  Frais 5%: 500 FCFA
  Total: 10 500 FCFA
  
Test 2 - Montant normal:
  Produit: 50 000 FCFA
  Frais 5%: 2 500 FCFA
  Total: 52 500 FCFA
  
Test 3 - Montant élevé:
  Produit: 850 000 FCFA (iPhone 14)
  Frais 5%: 42 500 FCFA
  Total: 892 500 FCFA
```

---

## 📞 Logs et Debugging

### Logs Flutter (Terminal)
```bash
# Regarder les logs en temps réel
flutter logs

Tu devrais voir:
✅ Kpay Response: 200
📤 Initiating Airtel payment: txn_123456
✔️ Confirming payment: txn_123456
✅ Kpay Response: 200
```

### Logs Kpay Dashboard
```
1. Connecté à https://dashboard.kpay.africa
2. Transactions section
3. Filtre: Status = Completed
4. Voir ta transaction avec:
   ✓ Transaction ID
   ✓ Montant
   ✓ Timestamp
   ✓ Status: Completed
```

### Logs Supabase
```sql
-- Voir les transactions
SELECT created_at, buyer_id, gross_amount, status 
FROM transactions 
WHERE payment_method = 'airtel_money'
ORDER BY created_at DESC;

-- Voir les audit logs
SELECT action, details 
FROM audit_logs 
WHERE action LIKE '%payment%'
ORDER BY created_at DESC;
```

---

## ✅ Validation Finale

Si tous les tests passent:
```
✓ Authentification Supabase fonctionne
✓ Produits affichent correctement
✓ Checkout calcule les frais
✓ Airtel Money initie paiement
✓ OTP reçu et validé
✓ Paiement confirmé
✓ Transaction créée dans Supabase
✓ Montants débité/crédité corrects
✓ Écran de succès affiche

🎉 L'APP EST PRÊTE POUR LA PRODUCTION! 🚀
```

---

## 🚀 Prochaines Étapes

```
Si tout fonctionne:
1. Déployer sur serveur production
2. Configurer domaine HTTPS
3. Ajouter webhooks Kpay
4. Tester sur mobile (Android/iOS)
5. Promouvoir l'app sur le marché
6. Collecter les premiers paiements réels
```

---

## 📞 Support

```
Problème?
- Email Kpay: support@kpay.africa
- Dashboard: https://dashboard.kpay.africa
- Docs: https://kpay.africa/docs
- Supabase: https://supabase.com/docs
```

**Bonne chance! L'app est maintenant en PRODUCTION! 🎉**
