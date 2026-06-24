-- ============================================================
-- Mise à jour de complete_marketplace_transaction pour inclure les frais
-- de livraison dans le débit acheteur (le vendeur n'en reçoit rien ; le
-- livreur ne touchera sa part qu'à la livraison, via complete_delivery).
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
  v_buyer_debit NUMERIC;
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

  v_buyer_debit := v_txn.gross_amount + v_txn.visible_fee + v_txn.delivery_fee;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.buyer_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.seller_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT balance INTO v_buyer_balance FROM user_wallets WHERE user_id = v_txn.buyer_id FOR UPDATE;

  IF v_buyer_balance < v_buyer_debit THEN
    RAISE EXCEPTION 'Solde insuffisant';
  END IF;

  UPDATE user_wallets
    SET balance = balance - v_buyer_debit, updated_at = now()
    WHERE user_id = v_txn.buyer_id;

  UPDATE user_wallets
    SET balance = balance + v_txn.net_to_seller, updated_at = now()
    WHERE user_id = v_txn.seller_id;

  UPDATE transactions
    SET status = 'success', completed_at = now()
    WHERE id = p_transaction_id;
END;
$$;
