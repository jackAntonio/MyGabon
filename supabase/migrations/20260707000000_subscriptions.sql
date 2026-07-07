-- ============================================================
-- Abonnements Pro (user_subscriptions) : jusqu'ici, tout l'état
-- (Free/Pro/Enterprise, dates de renouvellement) vivait uniquement
-- dans une box Hive locale, et le bouton "Confirmer" de
-- subscription_screen.dart n'effectuait AUCUN débit — n'importe qui
-- devenait Pro gratuitement, sans trace serveur ni synchronisation
-- entre appareils.
--
-- Cette migration fait de Supabase la source de vérité : l'achat/le
-- renouvellement passent par purchase_subscription(), qui débite le
-- MyGabon Wallet via adjust_wallet_balance() (même RPC que le reste
-- de l'app) et écrit l'abonnement de façon atomique. Hive ne sert
-- plus que de cache local (cf. SubscriptionService.cacheFromServer).
--
-- Pas d'auto-renouvellement automatique (aucun cron/charge Kpay
-- récurrente ici) : renewal_date expiré = l'app traite l'abonnement
-- comme inactif côté client, à re-débiter manuellement. Assumé pour
-- l'instant, à revisiter si Kpay expose un vrai prélèvement récurrent.
-- ============================================================

CREATE TABLE IF NOT EXISTS user_subscriptions (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'professional', 'enterprise')),
  start_date TIMESTAMP NOT NULL DEFAULT now(),
  renewal_date TIMESTAMP NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT false,
  auto_renew BOOLEAN NOT NULL DEFAULT false,
  featured_listings_used INT NOT NULL DEFAULT 0,
  cancelled_at TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);
-- ⚠️ Volontairement aucune policy INSERT/UPDATE côté client : toute
-- activation/annulation passe par purchase_subscription() ou
-- cancel_subscription() (SECURITY DEFINER), jamais par un UPDATE
-- direct qui laisserait un client s'auto-attribuer le Pro.

-- ✅ RPC : seul point d'entrée pour souscrire/renouveler/upgrader.
-- Débite le wallet de l'appelant (adjust_wallet_balance lève déjà une
-- exception si le solde est insuffisant) puis active l'abonnement —
-- si le débit échoue, l'abonnement n'est jamais activé.
CREATE OR REPLACE FUNCTION purchase_subscription(p_tier TEXT, p_monthly_price NUMERIC)
RETURNS user_subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result user_subscriptions;
BEGIN
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

GRANT EXECUTE ON FUNCTION purchase_subscription(TEXT, NUMERIC) TO authenticated;

-- ✅ RPC : annulation. Pas de remboursement automatique du mois en
-- cours (choix produit assumé, comme la plupart des abonnements SaaS) ;
-- coupe simplement le renouvellement et repasse en Free.
CREATE OR REPLACE FUNCTION cancel_subscription()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_subscriptions
  SET tier = 'free',
      is_active = false,
      auto_renew = false,
      cancelled_at = now(),
      updated_at = now()
  WHERE user_id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION cancel_subscription() TO authenticated;
