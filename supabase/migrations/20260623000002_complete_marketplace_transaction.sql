-- ============================================================
-- Finalisation atomique d'une transaction MyGabon Wallet :
-- débite l'acheteur, crédite le vendeur, marque la transaction
-- "success", dans une seule fonction SECURITY DEFINER (pas de
-- mutation de solde pilotée directement par le client).
-- ============================================================

CREATE OR REPLACE FUNCTION complete_marketplace_transaction(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
  v_buyer_balance NUMERIC;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;

  IF auth.uid() IS DISTINCT FROM v_txn.buyer_id THEN
    RAISE EXCEPTION 'Accès refusé : vous n''êtes pas l''acheteur de cette transaction';
  END IF;

  IF v_txn.status <> 'pending' THEN
    RAISE EXCEPTION 'Transaction déjà traitée';
  END IF;

  IF v_txn.payment_method <> 'mygabon_wallet' THEN
    RAISE EXCEPTION 'Cette fonction ne traite que les paiements MyGabon Wallet';
  END IF;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.buyer_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.seller_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT balance INTO v_buyer_balance FROM user_wallets WHERE user_id = v_txn.buyer_id FOR UPDATE;

  IF v_buyer_balance < (v_txn.gross_amount + v_txn.visible_fee) THEN
    RAISE EXCEPTION 'Solde insuffisant';
  END IF;

  UPDATE user_wallets
    SET balance = balance - (v_txn.gross_amount + v_txn.visible_fee), updated_at = now()
    WHERE user_id = v_txn.buyer_id;

  UPDATE user_wallets
    SET balance = balance + v_txn.net_to_seller, updated_at = now()
    WHERE user_id = v_txn.seller_id;

  UPDATE transactions
    SET status = 'success', completed_at = now()
    WHERE id = p_transaction_id;
END;
$$;

GRANT EXECUTE ON FUNCTION complete_marketplace_transaction(UUID) TO authenticated;
