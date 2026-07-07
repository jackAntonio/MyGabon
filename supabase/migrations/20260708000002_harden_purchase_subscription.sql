-- ============================================================
-- Durcissement (pas une faille active) : purchase_subscription()
-- s'appuyait uniquement sur adjust_wallet_balance() (déjà protégée par
-- une contrainte NOT NULL sur user_wallets.user_id) pour bloquer un
-- appel non authentifié, plutôt que sur une vérification explicite —
-- un anon appelant purchase_subscription() aujourd'hui obtient une
-- erreur de contrainte SQL (échoue sans effet), pas un abonnement
-- gratuit, mais cette protection est accidentelle. Ajout d'un check
-- explicite en tête de fonction, cohérent avec le reste des RPC de
-- l'app (cf. complete_cart_checkout, claim_delivery, confirm_phone_otp).
-- ============================================================

CREATE OR REPLACE FUNCTION purchase_subscription(p_tier TEXT, p_monthly_price NUMERIC)
RETURNS user_subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result user_subscriptions;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;
  IF p_tier NOT IN ('professional', 'enterprise') THEN
    RAISE EXCEPTION 'Palier d''abonnement invalide';
  END IF;
  IF p_monthly_price IS NULL OR p_monthly_price <= 0 THEN
    RAISE EXCEPTION 'Montant invalide';
  END IF;

  PERFORM adjust_wallet_balance(auth.uid(), -p_monthly_price);

  INSERT INTO user_subscriptions (
    user_id, tier, start_date, renewal_date, is_active, auto_renew,
    featured_listings_used, cancelled_at, updated_at
  )
  VALUES (
    auth.uid(), p_tier, now(), now() + interval '30 days', true, true,
    0, NULL, now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    tier = EXCLUDED.tier,
    renewal_date = now() + interval '30 days',
    is_active = true,
    auto_renew = true,
    featured_listings_used = 0,
    cancelled_at = NULL,
    updated_at = now()
  RETURNING * INTO v_result;

  RETURN v_result;
END;
$$;
