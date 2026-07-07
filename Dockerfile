# syntax=docker/dockerfile:1

# ============================================================
# Stage 1 : build du bundle web Flutter.
# Image Cirrus Labs (communauté, bien maintenue) plutôt que d'installer
# le SDK Flutter à la main — évite de dupliquer la logique d'install
# déjà faite sur la machine de dev. Garder ce tag synchronisé avec la
# version locale (`flutter --version`) pour un build reproductible.
# ============================================================
FROM ghcr.io/cirruslabs/flutter:3.44.4 AS build
WORKDIR /app

# Couche pub get mise en cache séparément du reste du code : ne se
# invalide que si pubspec.yaml/pubspec.lock changent, pas à chaque edit.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Secrets injectés au build, jamais gravés dans le repo ni dans une
# couche persistante nommée : mêmes valeurs que env.json (cf.
# env.json.example), passées ici via --build-arg / docker-compose args.
# SUPABASE_ANON_KEY est une clé publique cliente (protégée par RLS),
# pas un secret serveur — sûre à embarquer dans le bundle JS, comme le
# fait déjà `flutter run --dart-define-from-file=env.json` en local.
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG ONESIGNAL_APP_ID

RUN flutter build web --release \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
    --dart-define=ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}

# ============================================================
# Stage 2 : sert le bundle statique. Caddy plutôt que nginx : HTTPS
# automatique dès qu'un vrai domaine est configuré (Let's Encrypt),
# sans config TLS manuelle à maintenir en plus du Dockerfile.
# ============================================================
FROM caddy:2-alpine
COPY --from=build /app/build/web /usr/share/caddy
COPY Caddyfile /etc/caddy/Caddyfile
