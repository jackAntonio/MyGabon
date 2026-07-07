-- ============================================================
-- Actions de modération admin sur les signalements (fraud_reports).
-- La migration du 2026-06-27 a rendu les signalements eux-mêmes
-- visibles par les admins (table + RLS), mais verifyReport()/blockUser()
-- (FraudDetectionService) n'écrivaient encore que dans une Hive box
-- locale à l'admin qui clique : "bloquer" un utilisateur ne changeait
-- rien pour personne d'autre, ni ne persistait après réinstallation.
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS blocked BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS blocked_reason TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMP;

-- ✅ RPC : marque un signalement comme vérifié. Réservé aux membres de
-- admin_users (même garde que la policy "Admins can read all reports").
CREATE OR REPLACE FUNCTION verify_fraud_report(p_report_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Accès réservé aux administrateurs';
  END IF;

  UPDATE fraud_reports SET verified = true WHERE id = p_report_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Signalement introuvable';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION verify_fraud_report(UUID) TO authenticated;

-- ✅ RPC : bloque/débloque un utilisateur signalé. Réservé aux admins.
CREATE OR REPLACE FUNCTION set_user_blocked(p_user_id UUID, p_blocked BOOLEAN, p_reason TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Accès réservé aux administrateurs';
  END IF;

  UPDATE users
  SET blocked = p_blocked,
      blocked_reason = CASE WHEN p_blocked THEN p_reason ELSE NULL END,
      blocked_at = CASE WHEN p_blocked THEN now() ELSE NULL END
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Utilisateur introuvable';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION set_user_blocked(UUID, BOOLEAN, TEXT) TO authenticated;
