-- ============================================================
-- Checkout groupé du panier : jusqu'ici chaque article se payait
-- séparément ("Payer cet article" par ligne), le schéma transactions
-- étant 1 acheteur / 1 vendeur / 1 produit. Plutôt qu'une boucle côté
-- client (qui pourrait laisser un panier à moitié payé si un article
-- échoue en cours de route), cette RPC traite tout le panier dans une
-- seule fonction PL/pgSQL = une seule transaction Postgres implicite :
-- si une ligne échoue (solde insuffisant, produit introuvable), TOUT
-- le panier est annulé, aucune transaction partielle.
--
-- Même logique de débit/crédit que complete_marketplace_transaction
-- (UPDATE direct sur user_wallets, pas adjust_wallet_balance : cette
-- dernière n'autorise que auth.uid() = p_user_id, donc inutilisable
-- pour créditer un vendeur différent de l'acheteur appelant).
-- ============================================================

CREATE OR REPLACE FUNCTION complete_cart_checkout(p_items JSONB)
RETURNS SETOF UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID := auth.uid();
  v_item JSONB;
  v_product_id UUID;
  v_seller_id UUID;
  v_price NUMERIC;
  v_quantity INT;
  v_gross NUMERIC;
  v_fee NUMERIC;
  v_net NUMERIC;
  v_delivery NUMERIC;
  v_txn_id UUID;
  v_is_first BOOLEAN := true;
  v_buyer_balance NUMERIC;
BEGIN
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Panier vide';
  END IF;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_buyer_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::UUID;
    v_quantity := GREATEST(COALESCE((v_item->>'quantity')::INT, 1), 1);

    SELECT seller_id, price INTO v_seller_id, v_price
      FROM products WHERE id = v_product_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Produit introuvable';
    END IF;

    -- Prix jamais fait confiance côté client : recalculé depuis
    -- products.price, comme enforce_transaction_pricing pour les achats
    -- simples (migration 20260626_enforce_transaction_pricing.sql).
    v_gross := v_price * v_quantity;
    v_fee := v_gross * 0.05;
    v_net := v_gross * 0.95;
    -- Un seul frais de livraison pour tout le panier (une tournée, un
    -- livreur), facturé sur la première ligne uniquement.
    v_delivery := CASE WHEN v_is_first THEN 5000 ELSE 0 END;
    v_is_first := false;

    SELECT balance INTO v_buyer_balance FROM user_wallets WHERE user_id = v_buyer_id FOR UPDATE;
    IF v_buyer_balance < (v_gross + v_fee + v_delivery) THEN
      RAISE EXCEPTION 'Solde insuffisant';
    END IF;

    INSERT INTO user_wallets (user_id, balance) VALUES (v_seller_id, 0)
      ON CONFLICT (user_id) DO NOTHING;

    UPDATE user_wallets SET balance = balance - (v_gross + v_fee + v_delivery), updated_at = now()
      WHERE user_id = v_buyer_id;
    UPDATE user_wallets SET balance = balance + v_net, updated_at = now()
      WHERE user_id = v_seller_id;

    INSERT INTO transactions (
      buyer_id, seller_id, product_id, gross_amount, visible_fee,
      actual_fee, net_to_seller, payment_method, status, delivery_fee,
      delivery_status, completed_at
    ) VALUES (
      v_buyer_id, v_seller_id, v_product_id, v_gross, v_fee, v_fee, v_net,
      'mygabon_wallet', 'success', v_delivery,
      CASE WHEN v_delivery > 0 THEN 'pending' ELSE 'none' END, now()
    ) RETURNING id INTO v_txn_id;

    RETURN NEXT v_txn_id;
  END LOOP;

  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION complete_cart_checkout(JSONB) TO authenticated;
