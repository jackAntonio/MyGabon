# 🇬🇦 MyGabon - Guide de Configuration Complet

## 📋 Vue d'ensemble

MyGabon est une super-app Flutter pour la marketplace du Gabon avec:
- ✅ Authentification Supabase (login/signup)
- ✅ Marketplace avec produits réels
- ✅ Portefeuille MyGabon (wallet)
- ✅ Paiements via MyGabon Wallet et Airtel Money
- ✅ Services (9 services Gabon)
- ✅ Gestion des annonces (poster/vendre)
- ✅ Profil utilisateur avec historique de transactions

## 🚀 Configuration Initiale

### 1. Prérequis
- Flutter 3.0+
- Dart 3.0+
- Supabase Account (cloud ou local)
- Node.js & npm (optionnel, pour Firebase)

### 2. Installation Flutter & Dépendances

```bash
# Vérifier l'installation Flutter
flutter --version

# Obtenir les dépendances
cd c:\Users\HP\Downloads\MyGabon
flutter pub get

# Ajouter supabase_flutter
flutter pub add supabase_flutter

# Ajouter flutter_dotenv
flutter pub add flutter_dotenv
```

### 3. Configuration Supabase

#### Option A: Supabase Cloud (Recommandé)

1. **Créer un compte Supabase**
   - Aller sur https://supabase.com
   - S'inscrire ou se connecter
   - Créer un nouveau projet

2. **Récupérer les credentials**
   - Aller dans Settings → API
   - Copier `SUPABASE_URL`
   - Copier `anon public key`

3. **Mettre à jour .env**
```bash
# .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

4. **Initialiser la base de données**
   - Exécuter le script SQL: `SUPABASE_SETUP.sql`
   - Copier le contenu complet
   - Aller dans Supabase Dashboard → SQL Editor
   - Coller et exécuter le script
   - Cela crée toutes les tables et les données de démo

#### Option B: Supabase Local (Développement)

```bash
# Installer Supabase CLI
npm install -g supabase

# Initialiser Supabase local
supabase init

# Démarrer le stack local
supabase start

# Exécuter les migrations
supabase migration up
```

### 4. Configuration de l'App Flutter

#### Dans `lib/main_modern.dart`
```dart
// Les credentials sont chargés automatiquement depuis .env
// Grâce à flutter_dotenv
```

#### Vérifier le chargement du .env
```bash
# Le fichier .env doit être dans le root du projet
# Et dans pubspec.yaml:
flutter:
  assets:
    - .env
```

## 📱 Exécution de l'App

### Sur Chrome (Web)
```bash
flutter run -d chrome --no-browser
# Puis ouvrir http://localhost:xxxxx dans le navigateur
```

### Sur Android
```bash
flutter run -d android
# Assurez-vous qu'un appareil Android est connecté
```

### Sur iOS
```bash
flutter run -d ios
```

## 🔐 Authentification

### Flux Login/Signup

1. **Première connexion**
   - L'app affiche l'écran AuthScreen
   - Créer un compte avec email/password
   - Les données utilisateur sont sauvegardées dans Supabase

2. **Connexion suivante**
   - Utiliser email/password pour se connecter
   - La session est sauvegardée localement
   - L'app affiche la marketplace directement

### Données de test
```
Email: test@mygabon.com
Password: TestPassword123!
```

## 💰 Système de Paiement

### MyGabon Wallet
- **Solde initial**: 500,000 FCFA
- **Frais visibles**: 5%
- **Frais réels**: 10%
- **Flux**: Product → Checkout → Success

### Airtel Money
- **Numéro format**: +241XXXXXXXX ou 06XXXXXXXX
- **OTP**: Confirmation en 60 secondes
- **Flux**: Product → Checkout → Airtel Confirmation → Success

## 📊 Structure de la Base de Données

### Tables principales
```sql
-- Authentification
users (id, email, full_name, rating, avatar_url)

-- Marketplace
products (id, seller_id, title, price, category, location, image_url)

-- Paiements
transactions (id, buyer_id, seller_id, gross_amount, visible_fee, actual_fee)

-- Portefeuille
user_wallets (user_id, balance)

-- Services
services (id, provider_id, title, price, category)

-- Revues
reviews (id, product_id, seller_id, buyer_id, rating, comment)

-- Logs
audit_logs (id, user_id, action, resource, details)
```

## 🎯 Flux Utilisateur Complet

### 1. Authentification
```
Startup → AuthScreen (si non-connecté) → MainShell (si connecté)
```

### 2. Accueil (HomeScreen)
- Voir les 2 produits en vedette
- Filtrer par catégories
- Cliquer pour voir les détails

### 3. Détails Produit (MarketplaceDetailScreen)
- Voir image, description, vendeur
- Choisir paiement (cash/MyGabon/Airtel)
- Paiement cash: affiche modal vendeur
- Paiement MyGabon: va à Checkout

### 4. Paiement (CheckoutScreenComplete)
- Voir le résumé de commande
- Vérifier le solde du wallet
- Confirmer le paiement
- → Success Screen

### 5. Succès (PaymentSuccessScreenComplete)
- Affiche reçu de paiement
- ID transaction
- Options: retour marketplace ou télécharger reçu

### 6. Services (ServicesScreen)
- Voir 9 services Gabon
- Filtrer par catégorie
- Voir ratings et prix

### 7. Poster Annonce (PostScreen)
- Remplir formulaire (titre, prix, catégorie, etc.)
- Ajouter quantité et localisation
- Publier l'annonce

### 8. Marketplace (MarketplaceScreen)
- Voir tous les 5 produits
- Cliquer pour acheter
- Même flux que HomeScreen

### 9. Profil (ProfileScreen)
- Voir avatar et ratings
- Solde du wallet: 485,750 FCFA
- Historique des transactions (3 exemples)
- Options: recharger, envoyer, paramètres

## 🛠️ Fonctionnalités Implémentées

### ✅ Complètes
- [x] Authentification (Supabase Auth)
- [x] 5 écrans de navigation
- [x] Marketplace avec 5 produits
- [x] Services avec 9 éléments
- [x] Formulaire de posting
- [x] Profil utilisateur
- [x] Portefeuille (lecture/affichage)
- [x] Paiement MyGabon (simulation)
- [x] Paiement Airtel Money (avec OTP)
- [x] Écrans de succès
- [x] Material 3 Design
- [x] Riverpod State Management

### 🔄 À compléter (Optional)
- [ ] Upload d'images pour les produits
- [ ] Chat en temps réel
- [ ] Notifications push
- [ ] Localisation GPS
- [ ] Moteur de recherche avancé
- [ ] Filtres de marketplace
- [ ] Historique des messages

## 📚 Fichiers Clés

```
lib/
├── main_modern.dart              # Entry point avec authentification
├── screens/
│   ├── auth_screen.dart          # Login/Signup
│   ├── marketplace_detail_screen.dart  # Détails produit
│   ├── payment/
│   │   ├── checkout_screen_complete.dart     # Checkout
│   │   ├── airtel_confirmation_screen.dart   # Airtel OTP
│   │   └── success_screen_complete.dart      # Succès
│   └── (autres screens dans main_modern.dart)
├── services/
│   ├── supabase_service.dart     # Service Supabase principal
│   ├── supabase_provider.dart    # Riverpod providers
│   └── payment_service.dart      # Calcul des frais
├── models/
│   ├── product.dart
│   ├── transaction.dart
│   └── user.dart
├── config/
│   └── theme.dart                # Material 3 Gabon colors
└── widgets/
    ├── floating_nav_bar.dart     # Barre de navigation
    └── modern_card.dart          # Cartes produit
```

## 🐛 Dépannage

### Erreur: "supabase_flutter not found"
```bash
flutter pub get
flutter pub add supabase_flutter
```

### Erreur: ".env file not found"
- Créer `.env` dans le root du projet
- Ajouter les credentials
- Relancer `flutter run`

### Erreur: "Supabase project not found"
- Vérifier SUPABASE_URL dans .env
- Vérifier que le projet Supabase existe
- Vérifier les credentials sont corrects

### Erreur: "Table does not exist"
- Exécuter le script SQL complet: `SUPABASE_SETUP.sql`
- Attendre la création de toutes les tables
- Vérifier dans Supabase Dashboard → Tables

### Paiement ne fonctionne pas
- Vérifier que Supabase est initialisé
- Vérifier la connexion internet
- Vérifier que l'utilisateur est authentifié
- Vérifier les logs: `flutter logs`

## 📞 Support Supabase

### Documentation
- https://supabase.com/docs
- https://supabase.com/docs/reference/dart/introduction

### API Reference
- Authentification: https://supabase.com/docs/guides/auth
- Realtime: https://supabase.com/docs/guides/realtime
- PostgreSQL: https://supabase.com/docs/guides/database

## 📝 Notes de Développement

### Données de Démo
- 8 utilisateurs Gabon
- 5 produits marketplace
- 9 services disponibles
- 3 transactions exemple
- Taux de change: 1 EUR = 655 FCFA

### Styling
- Couleur primaire: #0B6E4F (vert Gabon)
- Couleur accentue: #F4C430 (jaune)
- Couleur secondaire: #0A1628 (navy)
- Police: Poppins (titres), Inter (corps)

### Performance
- Images: cached_network_image
- État: flutter_riverpod
- Animations: flutter_animate
- Shimmer loading: shimmer

## 🎉 Vous êtes prêt!

```bash
# Lancer l'app complète
flutter run -d chrome --no-browser

# Et c'est parti! 🚀
```

---

**MyGabon v1.0** | Marketplace du Gabon | Made with ❤️
