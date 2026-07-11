-- ============================================================
-- F8 — Coordonnées GPS précises masquées pour les utilisateurs anonymes
-- Tables    : products, services
-- Colonnes  : latitude, longitude (ajoutées dans 20260630_geolocation.sql)
-- Sévérité  : MOYEN — exposition de la position ~100m du vendeur/prestataire
--             sans authentification via GET /rest/v1/products?select=latitude,longitude
--
-- Stratégie adoptée : privilèges au niveau colonne (option A)
-- ───────────────────────────────────────────────────────────
-- En PostgreSQL, un REVOKE SELECT (colonne) FROM rôle ne peut pas
-- restreindre un GRANT SELECT table-level existant (les privilèges sont
-- additifs). La seule manière correcte est :
--   1. REVOKE SELECT table-level FROM anon
--   2. GRANT SELECT colonne par colonne (sans lat/lon) TO anon
--
-- Le rôle `authenticated` conserve le GRANT table-level complet
-- (lat/lon inclus) — nécessaire pour le tri par proximité
-- (MarketplaceProvider.sortByDistance / ServiceProvider.sortByDistance).
--
-- Impact Flutter (aucune modification côté client requise) :
--   • marketplace_provider.dart et service_provider.dart lisent déjà
--     latitude/longitude avec null-safety : `(row['latitude'] as num?)?.toDouble()`
--   • distanceKmFor() retourne null si latitude == null → tri par proximité
--     désactivé en mode anonyme, comportement déjà prévu par l'app.
--   • Les écrans post_announcement_screen.dart et post_service_screen.dart
--     écrivent lat/lon via un INSERT authenticated (policy "Sellers manage
--     own products" / "Providers manage own services") : non affecté.
--
-- ⚠️  ATTENTION : si une future migration exécute
--   `GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;`
--   elle rétablira l'accès table-level et annulera cette restriction.
--   Vérifier lors de chaque nouvelle migration qui touche les grants globaux.
-- ============================================================

-- ─────────────────────────────────────────────── UP ──────────────

-- ── TABLE products ──────────────────────────────────────────────

-- Retirer l'accès table-level SELECT accordé à anon par le setup Supabase
-- (GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon)
REVOKE SELECT ON TABLE public.products FROM anon;

-- Accorder explicitement chaque colonne NON sensible à anon.
-- Colonnes omises : latitude, longitude
GRANT SELECT (
  id,
  seller_id,
  title,
  description,
  price,
  category,
  quantity,
  image_url,
  published,
  condition,
  location,
  created_at,
  updated_at
) ON TABLE public.products TO anon;

-- Le rôle authenticated garde le SELECT table-level complet (aucun REVOKE)
-- via le GRANT existant du setup Supabase : lat/lon accessibles pour tri GPS.
-- On le réaffirme explicitement pour protéger contre un REVOKE accidentel.
GRANT SELECT ON TABLE public.products TO authenticated;


-- ── TABLE services ──────────────────────────────────────────────

REVOKE SELECT ON TABLE public.services FROM anon;

-- Colonnes omises : latitude, longitude
GRANT SELECT (
  id,
  provider_id,
  title,
  description,
  price,
  category,
  rating,
  reviews_count,
  image_url,
  published,
  location,
  created_at,
  updated_at
) ON TABLE public.services TO anon;

GRANT SELECT ON TABLE public.services TO authenticated;


-- ─────────────────────────────── DOWN (rollback) ──────────────
-- Pour annuler cette migration et rétablir l'état initial (accès GPS public),
-- exécuter les instructions suivantes :
--
--   GRANT SELECT ON TABLE public.products TO anon;
--   GRANT SELECT ON TABLE public.services TO anon;
--
-- (Le GRANT table-level rend les column-level grants ci-dessus redondants
--  mais inoffensifs — pas besoin de les REVOKE explicitement.)
-- ──────────────────────────────────────────────────────────────
