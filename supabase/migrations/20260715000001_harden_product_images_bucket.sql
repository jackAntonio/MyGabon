-- Bucket product-images : création + durcissement (audit 2026-07-07, point MOYEN).
-- La migration à neuf du 2026-07-11 n'avait recréé ni les buckets Storage ni
-- leurs policies — l'upload d'images était donc cassé en production.
-- Le client Flutter valide les magic bytes, mais la vraie défense est ici :
-- sans whitelist MIME, tout client authentifié peut déposer un fichier
-- arbitraire (HTML/JS/exécutable) servi publiquement.

INSERT INTO storage.buckets (id, name, public, allowed_mime_types, file_size_limit)
VALUES (
  'product-images',
  'product-images',
  true,
  ARRAY['image/jpeg', 'image/png', 'image/webp'],
  5242880  -- 5 Mo (le client compresse au-delà de 2 Mo)
)
ON CONFLICT (id) DO UPDATE
SET public             = EXCLUDED.public,
    allowed_mime_types = EXCLUDED.allowed_mime_types,
    file_size_limit    = EXCLUDED.file_size_limit;

-- Policies RLS sur storage.objects (rejouables)
DROP POLICY IF EXISTS "product_images_public_read" ON storage.objects;
CREATE POLICY "product_images_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "product_images_auth_insert" ON storage.objects;
CREATE POLICY "product_images_auth_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- Seul le propriétaire du fichier peut le supprimer
DROP POLICY IF EXISTS "product_images_owner_delete" ON storage.objects;
CREATE POLICY "product_images_owner_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'product-images' AND owner_id = (SELECT auth.uid()::text));
