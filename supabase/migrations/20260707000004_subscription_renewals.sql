-- ============================================================
-- Renouvellement automatique récurrent des abonnements Pro via Kpay
-- (Airtel Money), confirmé possible par Kpay (prélèvement sans
-- re-consentement à chaque cycle, cf. discussion produit du 2026-07-07).
--
-- Flux : pg_cron déclenche quotidiennement process_subscription_renewals()
-- (SECURITY DEFINER, tourne comme un job système, pas un utilisateur),
-- qui pour chaque abonnement dû crée une ligne `subscription_renewals`
-- puis appelle l'Edge Function kpay-charge-subscription-renewal via
-- pg_net (HTTP sortant depuis Postgres). Le webhook Kpay existant
-- (kpay-webhook) confirme/échoue la ligne, qui à son tour prolonge (ou
-- non) user_subscriptions.renewal_date — même séparation
-- initiation-cliente / confirmation-serveur que pour les achats
-- marketplace et les recharges wallet (transactions, wallet_topups).
--
-- ⚠️ ÉTAPES MANUELLES REQUISES APRÈS CETTE MIGRATION (rien de tout ça
-- ne peut être versionné : ce sont soit des secrets, soit des réglages
-- dashboard propres à chaque projet Supabase) :
--
-- 1) Activer les extensions pg_cron et pg_net si elles ne le sont pas
--    déjà (Dashboard Supabase > Database > Extensions, ou :
--      create extension if not exists pg_cron with schema pg_catalog;
--      create extension if not exists pg_net;
--    pg_cron peut ne pas être disponible sur tous les plans — vérifier).
--
-- 2) Déployer la nouvelle Edge Function :
--      supabase functions deploy kpay-charge-subscription-renewal
--    (réutilise les secrets KPAY_API_KEY/KPAY_SECRET_KEY déjà configurés
--    pour kpay-initiate/kpay-initiate-topup — rien de nouveau à ajouter
--    côté Kpay.)
--
-- 3) Configurer les deux réglages Postgres lus par
--    process_subscription_renewals() pour appeler l'Edge Function
--    (JAMAIS dans une migration commitée — secrets) :
--      alter database postgres set app.settings.supabase_functions_url
--        = 'https://<project-ref>.supabase.co/functions/v1';
--      alter database postgres set app.settings.service_role_key
--        = '<service-role-key>';
--    (Exécuter ces deux lignes une fois dans le SQL Editor du dashboard,
--    jamais commitées dans supabase/migrations/.)
--
-- 4) Planifier le job (à exécuter une fois, après les étapes 1-3) :
--      select cron.schedule(
--        'process-subscription-renewals',
--        '0 3 * * *',  -- tous les jours à 3h
--        $$ select process_subscription_renewals(); $$
--      );
-- ============================================================

CREATE TABLE IF NOT EXISTS subscription_renewals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  tier TEXT NOT NULL CHECK (tier IN ('professional', 'enterprise')),
  amount NUMERIC NOT NULL,
  phone_number TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending / success / failed
  provider_reference TEXT,
  failure_reason TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_subscription_renewals_user ON subscription_renewals(user_id);

ALTER TABLE subscription_renewals ENABLE ROW LEVEL SECURITY;

-- ✅ L'utilisateur peut voir l'historique de ses propres tentatives de
-- renouvellement (ex: pour comprendre pourquoi son abonnement a expiré).
-- Aucune policy INSERT/UPDATE côté client : uniquement via les RPC
-- SECURITY DEFINER ci-dessous, déclenchées par le cron ou le webhook.
CREATE POLICY "Users can read own renewal attempts" ON subscription_renewals
  FOR SELECT USING (auth.uid() = user_id);

-- ✅ Sélectionne les abonnements dus, débite via Kpay (pas le wallet :
-- un prélèvement automatique sans interaction ne doit pas dépendre d'un
-- solde wallet que l'utilisateur pourrait ne pas avoir rechargé).
CREATE OR REPLACE FUNCTION process_subscription_renewals()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
  v_renewal_id UUID;
  v_amount NUMERIC;
  v_functions_url TEXT;
  v_service_key TEXT;
BEGIN
  v_functions_url := current_setting('app.settings.supabase_functions_url', true);
  v_service_key := current_setting('app.settings.service_role_key', true);

  IF v_functions_url IS NULL OR v_service_key IS NULL THEN
    RAISE WARNING 'process_subscription_renewals: app.settings.supabase_functions_url / service_role_key non configurés, renouvellements ignorés';
    RETURN;
  END IF;

  FOR v_sub IN
    SELECT us.user_id, us.tier, u.phone_number
    FROM user_subscriptions us
    JOIN users u ON u.id = us.user_id
    WHERE us.renewal_date <= now()
      AND us.auto_renew = true
      AND us.is_active = true
  LOOP
    -- Prix synchronisés manuellement avec ProfessionalPlan
    -- (lib/models/monetization_models.dart) : aucune table de tarifs
    -- côté serveur pour l'instant, comme le reste des frais de l'app
    -- (cf. PaymentService.visibleFeeRate).
    v_amount := CASE v_sub.tier
      WHEN 'professional' THEN 9999
      WHEN 'enterprise' THEN 24999
      ELSE NULL
    END;

    IF v_amount IS NULL OR v_sub.phone_number IS NULL OR v_sub.phone_number = '' THEN
      CONTINUE;
    END IF;

    INSERT INTO subscription_renewals (user_id, tier, amount, phone_number, status)
    VALUES (v_sub.user_id, v_sub.tier, v_amount, v_sub.phone_number, 'pending')
    RETURNING id INTO v_renewal_id;

    PERFORM net.http_post(
      url := v_functions_url || '/kpay-charge-subscription-renewal',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_service_key
      ),
      body := jsonb_build_object('renewalId', v_renewal_id)
    );
  END LOOP;
END;
$$;

-- ✅ RPC appelée par kpay-webhook (service_role) à la confirmation Kpay :
-- prolonge l'abonnement de 30 jours et notifie l'utilisateur.
CREATE OR REPLACE FUNCTION confirm_subscription_renewal(p_renewal_id UUID, p_provider_reference TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_renewal RECORD;
BEGIN
  SELECT * INTO v_renewal FROM subscription_renewals WHERE id = p_renewal_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Renouvellement introuvable';
  END IF;
  IF v_renewal.status <> 'pending' THEN
    RETURN; -- déjà traité (webhook potentiellement rejoué par Kpay)
  END IF;

  UPDATE subscription_renewals
    SET status = 'success', provider_reference = p_provider_reference, completed_at = now()
    WHERE id = p_renewal_id;

  UPDATE user_subscriptions
    SET renewal_date = renewal_date + interval '30 days',
        is_active = true,
        updated_at = now()
    WHERE user_id = v_renewal.user_id;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_renewal.user_id,
    'Abonnement renouvelé',
    'Votre abonnement Pro a été renouvelé automatiquement pour 30 jours.',
    'subscription_renewal',
    jsonb_build_object('renewal_id', p_renewal_id, 'status', 'success')
  );
END;
$$;
-- ⚠️ service_role uniquement (jamais authenticated) : sinon n'importe
-- quel utilisateur pourrait s'auto-renouveler gratuitement en appelant
-- cette RPC directement, sans jamais payer via Kpay.
GRANT EXECUTE ON FUNCTION confirm_subscription_renewal(UUID, TEXT) TO service_role;

-- ✅ RPC appelée par kpay-webhook en cas d'échec du prélèvement : coupe
-- l'abonnement (pas de crédit gratuit sur échec de paiement) et notifie
-- l'utilisateur pour un renouvellement manuel.
CREATE OR REPLACE FUNCTION fail_subscription_renewal(p_renewal_id UUID, p_reason TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_renewal RECORD;
BEGIN
  SELECT * INTO v_renewal FROM subscription_renewals WHERE id = p_renewal_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Renouvellement introuvable';
  END IF;
  IF v_renewal.status <> 'pending' THEN
    RETURN;
  END IF;

  UPDATE subscription_renewals
    SET status = 'failed', failure_reason = p_reason, completed_at = now()
    WHERE id = p_renewal_id;

  UPDATE user_subscriptions
    SET is_active = false, auto_renew = false, updated_at = now()
    WHERE user_id = v_renewal.user_id;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_renewal.user_id,
    'Échec du renouvellement de l''abonnement',
    'Le prélèvement Airtel Money a échoué. Votre abonnement Pro est suspendu — renouvelez-le manuellement depuis votre profil.',
    'subscription_renewal',
    jsonb_build_object('renewal_id', p_renewal_id, 'status', 'failed', 'reason', p_reason)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION fail_subscription_renewal(UUID, TEXT) TO service_role;
