-- ============================================================
-- Correctif du ledger COD (20260717000001, même jour) : le livreur était
-- payé DEUX FOIS de sa commission, aux frais de MyGabon.
--
-- confirm_cash_on_delivery inscrivait  amount_owed = collecté - sa part,
-- c'est-à-dire « garde ta commission sur les espèces », TOUT EN créditant
-- aussi cette même part sur son wallet (comme le fait complete_delivery
-- pour une livraison déjà payée). Sur une commande à 52 250 FCFA : le
-- livreur encaissait 52 250, n'en remettait que 49 750 (2 500 gardés en
-- cash) et voyait malgré tout +2 500 sur son wallet. 2 500 FCFA créés de
-- rien à chaque livraison encaissée.
--
-- Correctif retenu : le livreur remet TOUT ce qu'il a encaissé et n'est
-- payé que par son wallet — même canal que pour une livraison déjà réglée
-- (complete_delivery), une seule fois. Le ledger redevient une notion
-- simple et non ambiguë : « espèces prises en main, pas encore remises ».
--
-- amount_owed devient donc toujours égal à amount_collected : on supprime
-- la colonne plutôt que d'entretenir deux chiffres censés ne jamais
-- diverger (c'est exactement leur divergence qui a produit le bug).
-- driver_payout part aussi : il vit déjà sur transactions.driver_payout,
-- et n'a rien à faire dans un compte de caisse.
--
-- Invariant à retenir pour la suite — sur une commande COD encaissée :
--   espèces remises (amount_collected)
--     = net vendeur + part livreur + marge MyGabon
-- soit 52 250 = 42 750 + 2 500 + 7 000 sur l'exemple ci-dessus.
-- ============================================================

ALTER TABLE public.driver_cash_collections DROP COLUMN IF EXISTS amount_owed;
ALTER TABLE public.driver_cash_collections DROP COLUMN IF EXISTS driver_payout;

-- Encours = tout ce qui a été encaissé et pas encore remis, sans déduction.
CREATE OR REPLACE FUNCTION driver_cash_float(p_driver_id UUID)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(amount_collected), 0)
    FROM driver_cash_collections
   WHERE driver_id = p_driver_id AND NOT remitted;
$$;

CREATE OR REPLACE FUNCTION confirm_cash_on_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
  v_collected NUMERIC;
  v_payout NUMERIC;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;
  IF v_txn.driver_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Accès refusé : vous n''êtes pas le livreur assigné';
  END IF;
  IF v_txn.payment_method <> 'cash_on_delivery' THEN
    RAISE EXCEPTION 'Cette fonction ne traite que le paiement à la livraison';
  END IF;
  IF v_txn.status <> 'pending' THEN
    RAISE EXCEPTION 'Transaction déjà traitée';
  END IF;
  IF v_txn.delivery_status <> 'claimed' THEN
    RAISE EXCEPTION 'Livraison non réclamée ou déjà terminée';
  END IF;

  -- Exactement ce que l'acheteur voyait en "Total à payer" à la commande.
  v_collected := v_txn.gross_amount + v_txn.visible_fee + v_txn.delivery_fee;
  v_payout := v_txn.delivery_fee * 0.5;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.seller_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_wallets (user_id, balance) VALUES (auth.uid(), 0)
    ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
    SET balance = balance + v_txn.net_to_seller, updated_at = now()
    WHERE user_id = v_txn.seller_id;
  -- Unique rémunération du livreur : sa part passe par le wallet, jamais
  -- par une retenue sur les espèces (cf. en-tête de cette migration).
  UPDATE user_wallets
    SET balance = balance + v_payout, updated_at = now()
    WHERE user_id = auth.uid();

  UPDATE transactions
    SET status = 'success',
        completed_at = now(),
        delivery_status = 'delivered',
        driver_payout = v_payout
    WHERE id = p_transaction_id;

  -- Le livreur doit remettre l'intégralité des espèces prises en main.
  -- UNIQUE(transaction_id) rend l'écriture non rejouable même si la RPC
  -- était appelée deux fois.
  INSERT INTO driver_cash_collections (transaction_id, driver_id, amount_collected)
  VALUES (p_transaction_id, auth.uid(), v_collected);

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.buyer_id,
    'Commande livrée et payée',
    format('Votre commande a été remise et réglée (%s FCFA en espèces).', v_collected::BIGINT),
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'delivered')
  );

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.seller_id,
    'Vente encaissée',
    format('Le livreur a encaissé votre vente : %s FCFA crédités sur votre wallet.',
           v_txn.net_to_seller::BIGINT),
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'delivered')
  );
END;
$$;

CREATE OR REPLACE FUNCTION confirm_cash_remittance(p_collection_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_driver_id UUID;
  v_amount NUMERIC;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Accès refusé : réservé aux administrateurs';
  END IF;

  UPDATE driver_cash_collections
    SET remitted = true, remitted_at = now(), confirmed_by = auth.uid()
    WHERE id = p_collection_id AND NOT remitted
    RETURNING driver_id, amount_collected INTO v_driver_id, v_amount;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Remise introuvable ou déjà confirmée';
  END IF;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_driver_id,
    'Recette remise confirmée',
    format('MyGabon a confirmé la remise de %s FCFA. Votre plafond d''encours est libéré d''autant.',
           v_amount::BIGINT),
    'cash_remittance',
    jsonb_build_object('collection_id', p_collection_id, 'amount', v_amount)
  );
END;
$$;

-- CREATE OR REPLACE conserve les ACL existantes ; on les réaffirme pour que
-- ce fichier reste correct même rejoué seul sur une base reconstruite.
DO $$
DECLARE
  fn text;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'public.confirm_cash_on_delivery(uuid)',
    'public.confirm_cash_remittance(uuid)'
  ] LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', fn);
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', fn);
  END LOOP;

  EXECUTE 'REVOKE EXECUTE ON FUNCTION public.driver_cash_float(uuid) FROM PUBLIC';
  EXECUTE 'REVOKE EXECUTE ON FUNCTION public.driver_cash_float(uuid) FROM anon';
  EXECUTE 'REVOKE EXECUTE ON FUNCTION public.driver_cash_float(uuid) FROM authenticated';
END $$;

COMMENT ON TABLE public.driver_cash_collections IS
  'Espèces encaissées par les livreurs en paiement à la livraison et dues '
  'INTÉGRALEMENT à MyGabon (la part du livreur passe par son wallet, jamais '
  'par une retenue sur la recette). Écrite uniquement par '
  'confirm_cash_on_delivery / confirm_cash_remittance (SECURITY DEFINER) : '
  'aucune policy INSERT/UPDATE.';
