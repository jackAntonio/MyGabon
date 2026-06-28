-- Ajoute latitude/longitude optionnels aux produits et services, pour le
-- tri "à proximité" du marketplace. Calcul de distance fait côté client
-- (Geolocator, lib/services/geolocation_service.dart) sur les pages déjà
-- chargées : pas de PostGIS, le volume actuel ne justifie pas un vrai
-- ORDER BY distance serveur.

ALTER TABLE products ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE products ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE services ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE services ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
