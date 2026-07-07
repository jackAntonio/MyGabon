-- ============================================================
-- Étend le centre de notifications in-app (20260707_notifications.sql)
-- au-delà des messages de chat : jusqu'ici, une candidature chauffeur
-- décidée, une livraison prise/terminée, ou un signalement vérifié ne
-- laissaient aucune trace consultable par l'utilisateur concerné dans
-- l'app — seul un admin le savait en interrogeant la base directement.
--
-- Les notifications sont insérées dans les RPC SECURITY DEFINER
-- existantes (déjà le seul point d'entrée pour ces actions), pas
-- depuis le client : impossible pour un utilisateur de se fabriquer
-- une fausse notification "candidature approuvée".
-- ============================================================

-- ✅ Candidature chauffeur décidée : notifie le candidat.
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

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_app.user_id,
    CASE WHEN p_approve THEN 'Candidature livreur approuvée' ELSE 'Candidature livreur refusée' END,
    CASE WHEN p_approve
      THEN 'Vous pouvez désormais accepter des livraisons.'
      ELSE COALESCE('Motif : ' || p_reason, 'Aucun motif communiqué.')
    END,
    'driver_application',
    jsonb_build_object('application_id', p_application_id, 'approved', p_approve)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION review_driver_application(UUID, BOOLEAN, TEXT) TO authenticated;

-- ✅ Livraison prise en charge : notifie l'acheteur.
CREATE OR REPLACE FUNCTION claim_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM driver_applications WHERE user_id = auth.uid() AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'Accès refusé : réservé aux livreurs approuvés';
  END IF;

  UPDATE transactions
    SET driver_id = auth.uid(), delivery_status = 'claimed'
    WHERE id = p_transaction_id AND delivery_status = 'pending' AND driver_id IS NULL
    RETURNING buyer_id INTO v_buyer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Livraison déjà prise ou introuvable';
  END IF;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_buyer_id,
    'Livreur en route',
    'Un livreur a pris en charge votre commande.',
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'claimed')
  );
END;
$$;
GRANT EXECUTE ON FUNCTION claim_delivery(UUID) TO authenticated;

-- ✅ Livraison terminée : notifie l'acheteur.
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

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.buyer_id,
    'Commande livrée',
    'Votre commande a été livrée avec succès.',
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'delivered')
  );
END;
$$;
GRANT EXECUTE ON FUNCTION complete_delivery(UUID) TO authenticated;

-- ✅ Signalement vérifié par un admin : notifie l'auteur du signalement
-- (jamais l'utilisateur signalé, pour ne pas l'alerter d'une enquête).
CREATE OR REPLACE FUNCTION verify_fraud_report(p_report_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reporter_id UUID;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Accès réservé aux administrateurs';
  END IF;

  UPDATE fraud_reports SET verified = true WHERE id = p_report_id
    RETURNING reporter_id INTO v_reporter_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Signalement introuvable';
  END IF;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_reporter_id,
    'Signalement examiné',
    'Votre signalement a été vérifié par notre équipe. Merci pour votre vigilance.',
    'report_verified',
    jsonb_build_object('report_id', p_report_id)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION verify_fraud_report(UUID) TO authenticated;
