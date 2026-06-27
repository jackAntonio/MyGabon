-- ============================================================
-- Recharge du MyGabon Wallet via Airtel Money (Kpay).
--
-- Table dédiée plutôt que de réutiliser `transactions` : cette dernière a
-- buyer_id/seller_id/product_id NOT NULL et un trigger
-- (enforce_transaction_pricing) qui recalcule le montant depuis
-- products.price — aucun des deux n'a de sens pour une recharge (on crédite
-- son propre wallet, il n'y a ni vendeur ni produit).
--
-- Même modèle de confiance que confirm_external_payment/fail_external_payment
-- (migration kpay_external_payment) : le statut ne passe à 'success'/'failed'
-- que via ces RPC SECURITY DEFINER, réservées à service_role (donc seulement
-- depuis kpay-webhook après vérification de la signature HMAC) — jamais
-- déclaré par le client.
-- ============================================================

CREATE TABLE IF NOT EXISTS wallet_topups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  amount NUMERIC NOT NULL CHECK (amount > 0),
  payment_method TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  transaction_reference TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_wallet_topups_user ON wallet_topups(user_id);

ALTER TABLE wallet_topups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own topups" ON wallet_topups
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own topups" ON wallet_topups
  FOR INSERT WITH CHECK (auth.uid() = user_id AND status = 'pending');
-- ⚠️ Pas de policy UPDATE pour authenticated : la confirmation/échec passe
-- uniquement par confirm_wallet_topup/fail_wallet_topup ci-dessous.

CREATE OR REPLACE FUNCTION confirm_wallet_topup(
  p_topup_id UUID,
  p_provider_reference TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_topup RECORD;
BEGIN
  SELECT * INTO v_topup FROM wallet_topups WHERE id = p_topup_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Recharge introuvable';
  END IF;

  IF v_topup.status <> 'pending' THEN
    RAISE EXCEPTION 'Recharge déjà traitée';
  END IF;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_topup.user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
    SET balance = balance + v_topup.amount, updated_at = now()
    WHERE user_id = v_topup.user_id;

  UPDATE wallet_topups
    SET status = 'success',
        completed_at = now(),
        transaction_reference = p_provider_reference
    WHERE id = p_topup_id;
END;
$$;

REVOKE ALL ON FUNCTION confirm_wallet_topup(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION confirm_wallet_topup(UUID, TEXT) FROM authenticated;
GRANT EXECUTE ON FUNCTION confirm_wallet_topup(UUID, TEXT) TO service_role;

CREATE OR REPLACE FUNCTION fail_wallet_topup(
  p_topup_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE wallet_topups
    SET status = 'failed', notes = p_reason
    WHERE id = p_topup_id AND status = 'pending';
END;
$$;

REVOKE ALL ON FUNCTION fail_wallet_topup(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION fail_wallet_topup(UUID, TEXT) FROM authenticated;
GRANT EXECUTE ON FUNCTION fail_wallet_topup(UUID, TEXT) TO service_role;

-- Realtime : le client attend la confirmation serveur, comme pour transactions.
ALTER PUBLICATION supabase_realtime ADD TABLE wallet_topups;
