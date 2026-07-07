# MyGabon

Super-app mobile Flutter pour le marché gabonais : trouver des services, publier des annonces,
acheter/vendre en marketplace local, avec un système de paiement double (portefeuille MyGabon +
Airtel Money) et une livraison assurée par un réseau de chauffeurs.

## Stack

- **Frontend** : Flutter/Dart, state management via `provider`
- **Backend** : Supabase (PostgreSQL, Auth, Storage, Edge Functions), sécurisé par Row Level
  Security (RLS) sur toutes les tables sensibles
- **Paiements** : portefeuille MyGabon (RPC Supabase atomique) + Airtel Money via la gateway
  Kpay (Edge Functions `kpay-initiate`, `kpay-initiate-topup`, `kpay-webhook`) + Apple Pay /
  Google Pay (sandbox, non branché à un vrai processeur) + espèces
- **Notifications push** : OneSignal (pas Firebase)
- **Géolocalisation** : `geolocator`, tri "à proximité" sur le marketplace
- **Stockage local** : Hive avec boîtes chiffrées (`SecureHive`) pour les données sensibles,
  cache-first pour tolérer les connexions faibles

## Fonctionnalités

- 🔐 **Auth** : login/register Supabase, vérification du numéro par OTP SMS
- 🏠 **Home / Services** : recherche, catégories, prestataires
- 🛒 **Marketplace** : annonces, panier, favoris, tri par proximité géographique
- 💬 **Chat** : liste de conversations + détail
- 💳 **Paiement** : sélection de méthode (MyGabon Wallet, Airtel Money, Apple/Google Pay,
  espèces), calcul de frais transparent, écran de succès
- 🚗 **Livraison** : inscription chauffeur, dashboard chauffeur, validation admin des
  candidatures
- ⭐ **Confiance** : avis/notes utilisateurs, détection de fraude sur les transactions,
  signalement d'utilisateurs suspects
- 💎 **Monétisation** : abonnement Pro, annonces mises en avant, écran d'analytics
- 📡 **Résilience réseau** : détection de qualité de connexion (4 niveaux), file d'actions
  hors-ligne avec sync automatique, cache Hive avec expiration (24h services/produits, 7j users)
- 🧾 **Traçabilité** : audit log des actions sensibles côté service

## Structure du projet

```
lib/
  main.dart                 # point d'entrée, MyGabonApp, injection des providers
  config/                   # thème (clair/sombre)
  models/                   # Product, Transaction, sécurité, monétisation, analytics, chat
  providers/                # ChangeNotifier par domaine (auth, marketplace, cart, chat, ...)
  screens/                  # un écran = un fichier (home, marketplace, chat, driver, payment/, ...)
  services/                 # accès Supabase, Kpay, cache, connectivité, fraude, vérification, ...
  utils/                    # validators, helpers
  widgets/                  # composants réutilisables (app scaffold, nav bar, cards, ...)
supabase/
  migrations/               # schéma Postgres versionné + politiques RLS
  functions/                # Edge Functions (kpay-*, send-otp-sms, send-push-notification)
```

## Démarrage

1. **Installer Flutter** : https://flutter.dev/docs/get-started/install

2. **Cloner et installer les dépendances**
   ```bash
   git clone https://github.com/jackAntonio/MyGabon.git
   cd MyGabon
   flutter pub get
   ```

3. **Configurer les secrets** — copier `env.json.example` vers `env.json` et renseigner
   `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ONESIGNAL_APP_ID`. Ce fichier n'est **jamais** commité
   et les secrets ne sont **jamais** empaquetés comme asset (lisibles en dézippant un APK/IPA) :
   ```bash
   cp env.json.example env.json
   ```
   Les clés Kpay/Twilio ne vivent que côté serveur, en secrets d'Edge Functions
   (`supabase secrets set ...`) — jamais dans le client Flutter.

4. **Lancer l'app**
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

5. **Appliquer les migrations Supabase** (schéma + RLS)
   ```bash
   supabase db push
   ```

## Docker

Build reproductible du bundle web, indépendant de la machine (pas besoin d'installer le SDK
Flutter localement). Nécessite [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```bash
cp .env.example .env   # renseigner SUPABASE_URL / SUPABASE_ANON_KEY / ONESIGNAL_APP_ID
docker compose up --build
```

L'app est servie sur http://localhost:8080. Le `Dockerfile` compile via l'image Flutter de
Cirrus Labs (stage `build`) puis sert le résultat statique via Caddy (stage final, `Caddyfile`) —
HTTPS automatique dès que ce conteneur tourne derrière un vrai nom de domaine, sans config TLS
supplémentaire. En local, seul HTTP (`:80` dans le conteneur, mappé sur `:8080` côté hôte) a un
sens : un certificat pour une IP LAN reste non reconnu par les navigateurs (Safari iOS compris),
Docker ne change rien à cette contrainte.

## Sécurité

- RLS activée sur les tables sensibles (wallet, transactions, profils) — voir
  `supabase/migrations/20260624_security_hardening.sql` et `20260702_fix_wallet_security.sql`
- Stockage local sensible chiffré via `SecureHive` (pas de boîtes Hive en clair pour les
  données utilisateur)
- Logs applicatifs sans détails sensibles (masquage des messages)
- Aucune clé API paiement/SMS dans le bundle client — uniquement `--dart-define-from-file` côté
  app, secrets d'Edge Functions côté serveur

## Tests

```bash
flutter test
```

---

Built with ❤️ pour les utilisateurs gabonais.
