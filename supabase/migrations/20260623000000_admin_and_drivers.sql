-- ============================================================
-- Rôles admin & livreur + paiement de livraison.
-- ============================================================

-- ✅ Admins : présence dans cette table = admin. Aucune policy
-- INSERT/UPDATE/DELETE pour les utilisateurs authentifiés : seul un accès
-- direct (SQL editor / service role) peut y ajouter quelqu'un.
CREATE TABLE IF NOT EXISTS admin_users (
  user_id UUID PRIMARY KEY REFERENCES users(id)
);
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can check own admin status" ON admin_users
  FOR SELECT USING (auth.uid() = user_id);

-- ✅ Candidatures livreur : "tout le monde ne peut pas l'être", soumises à
-- étude de dossier par un admin via review_driver_application().
CREATE TABLE IF NOT EXISTS driver_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  full_name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL, -- 'moto', 'voiture', 'velo', 'a_pied'
  zone TEXT,
  status TEXT NOT NULL DEFAULT 'pending', -- pending / approved / rejected
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);
ALTER TABLE driver_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Applicant can read own application" ON driver_applications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can read all applications" ON driver_applications
  FOR SELECT USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));
CREATE POLICY "User can submit own application" ON driver_applications
  FOR INSERT WITH CHECK (auth.uid() = user_id AND status = 'pending');
-- ⚠️ Pas de policy UPDATE pour les utilisateurs authentifiés : la décision
-- (approuver/refuser) passe uniquement par review_driver_application()
-- (SECURITY DEFINER), jamais par un UPDATE direct du candidat ou d'un tiers.

-- ✅ RPC : seul un admin peut statuer sur une candidature.
CREATE OR REPLACE FUNCTION review_driver_application(
  p_application_id UUID,
  p_approve BOOLEAN,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_app RECORD;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Accès refusé : réservé aux administrateurs';
  END IF;

  SELECT * INTO v_app FROM driver_applications WHERE id = p_application_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Candidature introuvable';
  END IF;
  IF v_app.status <> 'pending' THEN
    RAISE EXCEPTION 'Candidature déjà traitée';
  END IF;

  UPDATE driver_applications
    SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
        rejection_reason = p_reason,
        reviewed_by = auth.uid(),
        reviewed_at = now()
    WHERE id = p_application_id;
END;
$$;
GRANT EXECUTE ON FUNCTION review_driver_application(UUID, BOOLEAN, TEXT) TO authenticated;

-- ✅ Frais et statut de livraison sur les transactions existantes.
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES users(id);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS driver_payout NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS delivery_status TEXT NOT NULL DEFAULT 'none'; -- none/pending/claimed/delivered

-- Les livreurs approuvés voient les livraisons disponibles et les leurs.
CREATE POLICY "Drivers can see available or own deliveries" ON transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM driver_applications
      WHERE user_id = auth.uid() AND status = 'approved'
    )
    AND (delivery_status = 'pending' OR driver_id = auth.uid())
  );

-- ✅ RPC : un livreur approuvé réclame une livraison disponible.
CREATE OR REPLACE FUNCTION claim_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM driver_applications WHERE user_id = auth.uid() AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'Accès refusé : réservé aux livreurs approuvés';
  END IF;

  UPDATE transactions
    SET driver_id = auth.uid(), delivery_status = 'claimed'
    WHERE id = p_transaction_id AND delivery_status = 'pending' AND driver_id IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Livraison déjà prise ou introuvable';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION claim_delivery(UUID) TO authenticated;

-- ✅ RPC : le livreur assigné marque la livraison effectuée et reçoit 50%
-- des frais de livraison (l'autre 50% reste acquis à la plateforme).
CREATE OR REPLACE FUNCTION complete_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
  v_payout NUMERIC;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;
  IF v_txn.driver_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Accès refusé : vous n''êtes pas le livreur assigné';
  END IF;
  IF v_txn.delivery_status <> 'claimed' THEN
    RAISE EXCEPTION 'Livraison non réclamée ou déjà terminée';
  END IF;

  v_payout := v_txn.delivery_fee * 0.5;

  INSERT INTO user_wallets (user_id, balance) VALUES (auth.uid(), 0)
    ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
    SET balance = balance + v_payout, updated_at = now()
    WHERE user_id = auth.uid();

  UPDATE transactions
    SET delivery_status = 'delivered', driver_payout = v_payout
    WHERE id = p_transaction_id;
END;
$$;
GRANT EXECUTE ON FUNCTION complete_delivery(UUID) TO authenticated;

-- ⚠️ Le seed du premier compte admin ne doit PAS être versionné ici : un
-- email réel dans une migration commitée devient une cible identifiable
-- (phishing/credential-stuffing visant le compte super-admin) dès que ce
-- dépôt est lu par quelqu'un d'autre. À exécuter manuellement, une fois,
-- dans le SQL editor Supabase (jamais dans un fichier git) :
--
--   INSERT INTO admin_users (user_id)
--   SELECT id FROM users WHERE email = '<email-admin-reel>'
--   ON CONFLICT (user_id) DO NOTHING;
