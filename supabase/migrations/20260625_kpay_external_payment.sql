-- ============================================================
-- Rend le paiement Airtel/Moov Money (Kpay) fonctionnel de bout en
-- bout, sans jamais faire confiance au client pour déclarer un
-- paiement réussi :
-- 1) Ferme la policy UPDATE "Participants can update own transaction"
--    (laissée ouverte dans la migration wallet_rpc_and_public_profiles
--    avec un avertissement explicite "à durcir si la fraude sur le
--    statut de paiement devient un risque réel") : un acheteur pouvait
--    jusqu'ici passer sa propre transaction en status='success' via un
--    simple PATCH REST, sans jamais payer. Toute transition de statut
--    passe désormais exclusivement par des RPC SECURITY DEFINER.
-- 2) Ajoute confirm_external_payment / fail_external_payment,
--    appelables UNIQUEMENT par service_role (donc seulement depuis
--    l'Edge Function kpay-webhook qui vérifie la signature HMAC de
--    Kpay) — jamais par le client authentifié.
-- 3) Active Realtime sur transactions pour que le client puisse
--    attendre la confirmation serveur sans la déclencher lui-même.
-- ============================================================

REVOKE UPDATE ON transactions FROM authenticated;
DROP POLICY IF EXISTS "Participants can update own transaction" ON transactions;
-- Plus aucune policy UPDATE pour authenticated : toute transition de
-- statut passe par complete_marketplace_transaction / claim_delivery /
-- complete_delivery / confirm_external_payment / fail_external_payment.

CREATE OR REPLACE FUNCTION confirm_external_payment(
  p_transaction_id UUID,
  p_provider_reference TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;

  IF v_txn.status <> 'pending' THEN
    RAISE EXCEPTION 'Transaction déjà traitée';
  END IF;

  IF v_txn.payment_method NOT IN ('airtel_money', 'moov_money') THEN
    RAISE EXCEPTION 'Cette fonction ne traite que les paiements mobile money externes';
  END IF;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.seller_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
    SET balance = balance + v_txn.net_to_seller, updated_at = now()
    WHERE user_id = v_txn.seller_id;

  UPDATE transactions
    SET status = 'success',
        completed_at = now(),
        transaction_reference = p_provider_reference
    WHERE id = p_transaction_id;
END;
$$;

-- ✅ Exécutable uniquement par le rôle service_role (Edge Function
-- kpay-webhook après vérification de signature). Jamais par le client.
REVOKE ALL ON FUNCTION confirm_external_payment(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION confirm_external_payment(UUID, TEXT) FROM authenticated;
GRANT EXECUTE ON FUNCTION confirm_external_payment(UUID, TEXT) TO service_role;

ALTER TABLE transactions ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE OR REPLACE FUNCTION fail_external_payment(
  p_transaction_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE transactions
    SET status = 'failed', notes = p_reason
    WHERE id = p_transaction_id AND status = 'pending';
END;
$$;

REVOKE ALL ON FUNCTION fail_external_payment(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION fail_external_payment(UUID, TEXT) FROM authenticated;
GRANT EXECUTE ON FUNCTION fail_external_payment(UUID, TEXT) TO service_role;

-- ✅ Realtime : le client attend la confirmation serveur (webhook) au
-- lieu de la déclarer lui-même. Sans danger : RLS continue de limiter
-- chaque utilisateur à ses propres transactions (policy SELECT déjà en
-- place : "Buyer or seller can read own transactions").
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
