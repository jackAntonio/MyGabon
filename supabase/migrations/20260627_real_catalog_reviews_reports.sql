-- ============================================================
-- Rend opérationnelles plusieurs fonctionnalités jusqu'ici fictives
-- (catalogue de démo, avis/signalements stockés uniquement en local) :
-- 1) products/services manquaient condition/location : createProduct()
--    (lib/services/supabase_service.dart) les envoie déjà depuis
--    post_announcement_screen.dart, l'INSERT échouait donc en silence
--    (colonne inexistante). Comblé ici, avec des valeurs par défaut
--    pour les lignes de démo déjà en base.
-- 2) fraud_reports : les signalements (ReportUserDialog) n'étaient
--    stockés que dans une Hive box locale au signaleur, jamais visibles
--    par un admin ni par personne d'autre. Table dédiée + RPC d'agrégat
--    (compte uniquement, jamais le détail) pour afficher un signal de
--    risque sans exposer qui a signalé quoi.
-- 3) reviews : ajoute la policy DELETE manquante (l'auteur ne pouvait
--    pas supprimer son propre avis) + un RPC flag_review pour signaler
--    un avis sans donner aux utilisateurs un accès UPDATE direct à la
--    table (qui permettrait de modifier la note/le commentaire d'autrui).
-- ============================================================

ALTER TABLE products ADD COLUMN IF NOT EXISTS condition TEXT NOT NULL DEFAULT 'Occasion';
ALTER TABLE products ADD COLUMN IF NOT EXISTS location TEXT NOT NULL DEFAULT 'Libreville';
ALTER TABLE services ADD COLUMN IF NOT EXISTS location TEXT NOT NULL DEFAULT 'Libreville';

-- ============================================================
-- Signalements (fraude / comportement suspect)
-- ============================================================

CREATE TABLE IF NOT EXISTS fraud_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  suspicious_user_id UUID NOT NULL REFERENCES users(id),
  listing_id UUID,
  reason TEXT NOT NULL,
  description TEXT NOT NULL,
  evidence_urls TEXT[] DEFAULT '{}',
  verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_fraud_reports_suspicious_user ON fraud_reports(suspicious_user_id);

ALTER TABLE fraud_reports ENABLE ROW LEVEL SECURITY;

-- ✅ Un signaleur peut créer et relire ses propres signalements ; seul un
-- admin peut voir l'ensemble (contenu sensible : qui accuse qui, de quoi).
CREATE POLICY "Reporter can create report" ON fraud_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Reporter can read own reports" ON fraud_reports
  FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Admins can read all reports" ON fraud_reports
  FOR SELECT USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

-- ✅ RPC : expose uniquement un COMPTE de signalements pour un utilisateur
-- donné (utilisable par n'importe qui pour afficher un signal d'alerte,
-- ex. SafetyWarningBanner) — jamais le détail (identité du signaleur,
-- description), qui reste réservé aux admins via la policy ci-dessus.
CREATE OR REPLACE FUNCTION get_user_report_count(p_target_user_id UUID)
RETURNS INT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::INT FROM fraud_reports WHERE suspicious_user_id = p_target_user_id;
$$;
GRANT EXECUTE ON FUNCTION get_user_report_count(UUID) TO authenticated;

-- ============================================================
-- Reviews : suppression par l'auteur + signalement modéré
-- ============================================================

CREATE POLICY "Reviewer can delete own review" ON reviews
  FOR DELETE USING (auth.uid() = reviewer_id);

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS flagged BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS flag_reason TEXT;

-- ✅ RPC plutôt qu'une policy UPDATE ouverte : un utilisateur peut signaler
-- l'avis de quelqu'un d'autre sans pouvoir toucher à sa note/son commentaire.
CREATE OR REPLACE FUNCTION flag_review(p_review_id UUID, p_reason TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  UPDATE reviews SET flagged = true, flag_reason = p_reason WHERE id = p_review_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Avis introuvable';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION flag_review(UUID, TEXT) TO authenticated;
