# MyGabon — Context projet

## Description
Marketplace mobile Gabon en Flutter/Dart (package `mygabon`, classe racine `MyGabonApp`).
Système de paiement dual : MyGabon wallet + Airtel Money (via la gateway Kpay).

## Architecture
- Frontend : Flutter (Dart)
- Backend : Supabase (PostgreSQL + Auth + Storage)
- Paiements : MyGabon Wallet (RPC Supabase) + Airtel Money (Edge Functions Kpay)

## Règles spécifiques
- Jamais exposer les clés API paiement dans le code Flutter
- Secrets uniquement via `--dart-define-from-file=env.json` côté client, jamais via un package embarqué type flutter_dotenv (lisible en dézippant l'APK/IPA) ; les clés Kpay/Twilio vivent en secrets d'Edge Functions
- Toujours tester les edge cases de paiement (échec, timeout, double débit)
- Sécuriser les endpoints Supabase avec Row Level Security (RLS)

## Conventions de code
- Nommage : camelCase pour variables, PascalCase pour classes
- Un widget = un fichier
- Séparer la logique métier des widgets (BLoC ou Provider)
