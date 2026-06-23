# GabonConnect — Context projet

## Description
Marketplace mobile Gabon en Flutter/Dart.
Système de paiement dual : MyGabon wallet + Airtel Money.

## Architecture
- Frontend : Flutter (Dart)
- Backend : Supabase (PostgreSQL + Auth + Storage)
- Paiements : MyGabon API + Airtel Money API

## Règles spécifiques
- Jamais exposer les clés API paiement dans le code Flutter
- Utiliser flutter_dotenv ou --dart-define pour les secrets
- Toujours tester les edge cases de paiement (échec, timeout, double débit)
- Sécuriser les endpoints Supabase avec Row Level Security (RLS)

## Conventions de code
- Nommage : camelCase pour variables, PascalCase pour classes
- Un widget = un fichier
- Séparer la logique métier des widgets (BLoC ou Provider)
