-- ============================================================
-- 20260712_advisor_hardening.sql
-- Durcissement issu des advisors Supabase (sécurité + performance).
--
-- Objectifs :
--   1. Verrouiller l'exécution RPC des fonctions SECURITY DEFINER
--      (retirer anon/PUBLIC ; les fonctions trigger ne doivent être
--       appelables par personne via /rest/v1/rpc).
--   2. Optimiser les policies RLS (auth.<fn>() -> (select auth.<fn>()))
--      et consolider les policies permissives multiples.
--   3. Indexer les clés étrangères non couvertes.
--
-- Entièrement REJOUABLE sur une base vierge : chaque bloc est gardé
-- (to_regprocedure / DROP POLICY IF EXISTS / CREATE INDEX IF NOT EXISTS).
-- ============================================================


-- ═══════════════════════════════════════════════════════════
-- SECTION 1 — SÉCURITÉ : exécution des fonctions
-- ═══════════════════════════════════════════════════════════

-- 1a. RPC légitimement appelables par un utilisateur CONNECTÉ uniquement.
--     Toutes possèdent un contrôle d'autorisation interne (auth.uid() et,
--     pour les fonctions admin, un test d'appartenance à admin_users), mais
--     restaient exécutables par `anon` via le GRANT implicite à PUBLIC.
--     On retire PUBLIC + anon, on (ré)accorde authenticated.
--     NB : confirm_phone_otp exige aussi une session (auth.uid()), elle
--     n'est donc PAS laissée à anon.
DO $$
DECLARE
  fn text;
  rpcs text[] := ARRAY[
    'public.adjust_wallet_balance(uuid, numeric)',
    'public.purchase_subscription(text, numeric)',
    'public.cancel_subscription()',
    'public.claim_delivery(uuid)',
    'public.complete_delivery(uuid)',
    'public.complete_marketplace_transaction(uuid)',
    'public.complete_cart_checkout(jsonb)',
    'public.flag_review(uuid, text)',
    'public.get_user_report_count(uuid)',
    'public.confirm_phone_otp(text, text)',
    'public.set_user_blocked(uuid, boolean, text)',
    'public.review_driver_application(uuid, boolean, text)',
    'public.verify_fraud_report(uuid)'
  ];
BEGIN
  FOREACH fn IN ARRAY rpcs LOOP
    IF to_regprocedure(fn) IS NOT NULL THEN
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', fn);
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', fn);
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', fn);
    END IF;
  END LOOP;
END $$;

-- 1b. Fonctions de trigger / maintenance : ne doivent JAMAIS être invoquées
--     via l'API REST. Le trigger les exécute avec les droits du propriétaire,
--     aucun rôle client n'a besoin d'EXECUTE.
--     rls_auto_enable() est un orphelin hérité de l'ancien setup (absente des
--     migrations versionnées) : la garde to_regprocedure évite l'échec si elle
--     n'existe pas sur une base vierge.
DO $$
DECLARE
  fn text;
  triggers text[] := ARRAY[
    'public.enforce_transaction_pricing()',
    'public.rls_auto_enable()'
  ];
BEGIN
  FOREACH fn IN ARRAY triggers LOOP
    IF to_regprocedure(fn) IS NOT NULL THEN
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', fn);
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', fn);
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', fn);
    END IF;
  END LOOP;
END $$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 2 — Vue profiles_public (advisor ERROR : SECURITY DEFINER)
-- ═══════════════════════════════════════════════════════════
-- EXCEPTION ASSUMÉE — on NE bascule PAS en security_invoker.
-- La table users contient des données privées (email, téléphone) et est
-- verrouillée par RLS à auth.uid() = id. La vue ne projette QUE des colonnes
-- publiques (id, full_name, avatar_url, verified, rating) et n'est accordée
-- qu'à `authenticated`. Le mode SECURITY DEFINER est ici le comportement
-- VOULU : il permet d'exposer ces colonnes publiques de tous les profils
-- (messagerie, fiches contreparties) SANS ouvrir un SELECT global sur users
-- (qui fuiterait email/téléphone) ni casser l'affichage (security_invoker
-- limiterait chaque utilisateur à sa seule ligne).
-- L'ERROR de l'advisor est donc un faux positif au regard de l'intention.
COMMENT ON VIEW public.profiles_public IS
  'Projection publique (id, full_name, avatar_url, verified, rating) de users. '
  'SECURITY DEFINER volontaire : expose les colonnes publiques de tous les '
  'profils sans fuiter email/téléphone. Ne pas passer en security_invoker.';


-- ═══════════════════════════════════════════════════════════
-- SECTION 3 — PERFORMANCE RLS
--   • auth.<fn>()  ->  (select auth.<fn>())  (évite la ré-évaluation par ligne)
--   • consolidation des policies permissives multiples (même rôle+action)
-- Sémantique USING/WITH CHECK strictement conservée.
-- ═══════════════════════════════════════════════════════════

-- ── users ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own row" ON public.users;
CREATE POLICY "Users can read own row" ON public.users
  FOR SELECT USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own row" ON public.users;
CREATE POLICY "Users can update own row" ON public.users
  FOR UPDATE USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert own row" ON public.users;
CREATE POLICY "Users can insert own row" ON public.users
  FOR INSERT WITH CHECK ((select auth.uid()) = id);

-- ── services (consolidation SELECT : la lecture publique suffit, on retire la
--    branche SELECT redondante du FOR ALL en le scindant en I/U/D) ──────────
DROP POLICY IF EXISTS "Providers manage own services" ON public.services;
CREATE POLICY "Providers insert own services" ON public.services
  FOR INSERT WITH CHECK ((select auth.uid()) = provider_id);
CREATE POLICY "Providers update own services" ON public.services
  FOR UPDATE USING ((select auth.uid()) = provider_id)
             WITH CHECK ((select auth.uid()) = provider_id);
CREATE POLICY "Providers delete own services" ON public.services
  FOR DELETE USING ((select auth.uid()) = provider_id);

-- ── products (idem services) ────────────────────────────────
DROP POLICY IF EXISTS "Sellers manage own products" ON public.products;
CREATE POLICY "Sellers insert own products" ON public.products
  FOR INSERT WITH CHECK ((select auth.uid()) = seller_id);
CREATE POLICY "Sellers update own products" ON public.products
  FOR UPDATE USING ((select auth.uid()) = seller_id)
             WITH CHECK ((select auth.uid()) = seller_id);
CREATE POLICY "Sellers delete own products" ON public.products
  FOR DELETE USING ((select auth.uid()) = seller_id);

-- ── messages ────────────────────────────────────────────────
DROP POLICY IF EXISTS "Participants can read own messages" ON public.messages;
CREATE POLICY "Participants can read own messages" ON public.messages
  FOR SELECT USING (
    (select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id
  );

DROP POLICY IF EXISTS "Users can send messages as themselves" ON public.messages;
CREATE POLICY "Users can send messages as themselves" ON public.messages
  FOR INSERT WITH CHECK ((select auth.uid()) = sender_id);

-- ── audit_logs ──────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own audit logs" ON public.audit_logs;
CREATE POLICY "Users can read own audit logs" ON public.audit_logs
  FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own audit logs" ON public.audit_logs;
CREATE POLICY "Users can insert own audit logs" ON public.audit_logs
  FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

-- ── reviews (SELECT public inchangé) ────────────────────────
DROP POLICY IF EXISTS "Reviewers can create reviews" ON public.reviews;
CREATE POLICY "Reviewers can create reviews" ON public.reviews
  FOR INSERT WITH CHECK ((select auth.uid()) = reviewer_id);

DROP POLICY IF EXISTS "Reviewer can delete own review" ON public.reviews;
CREATE POLICY "Reviewer can delete own review" ON public.reviews
  FOR DELETE USING ((select auth.uid()) = reviewer_id);

-- ── admin_users ─────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can check own admin status" ON public.admin_users;
CREATE POLICY "Users can check own admin status" ON public.admin_users
  FOR SELECT USING ((select auth.uid()) = user_id);

-- ── transactions (consolidation SELECT : lecture participant + livreur) ─────
DROP POLICY IF EXISTS "Buyer or seller can read own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Drivers can see available or own deliveries" ON public.transactions;
CREATE POLICY "Read own or deliverable transactions" ON public.transactions
  FOR SELECT USING (
    (select auth.uid()) = buyer_id
    OR (select auth.uid()) = seller_id
    OR (
      EXISTS (
        SELECT 1 FROM public.driver_applications da
        WHERE da.user_id = (select auth.uid()) AND da.status = 'approved'
      )
      AND (delivery_status = 'pending' OR driver_id = (select auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Buyer can create own transaction" ON public.transactions;
CREATE POLICY "Buyer can create own transaction" ON public.transactions
  FOR INSERT WITH CHECK ((select auth.uid()) = buyer_id);

DROP POLICY IF EXISTS "Participants can update own transaction" ON public.transactions;
CREATE POLICY "Participants can update own transaction" ON public.transactions
  FOR UPDATE USING (
    (select auth.uid()) = buyer_id OR (select auth.uid()) = seller_id
  );

-- ── user_wallets ────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own wallet" ON public.user_wallets;
CREATE POLICY "Users can read own wallet" ON public.user_wallets
  FOR SELECT USING ((select auth.uid()) = user_id);

-- ── driver_applications (consolidation SELECT : demandeur + admins) ─────────
DROP POLICY IF EXISTS "Applicant can read own application" ON public.driver_applications;
DROP POLICY IF EXISTS "Admins can read all applications" ON public.driver_applications;
CREATE POLICY "Read own or admin all applications" ON public.driver_applications
  FOR SELECT USING (
    (select auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM public.admin_users au WHERE au.user_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "User can submit own application" ON public.driver_applications;
CREATE POLICY "User can submit own application" ON public.driver_applications
  FOR INSERT WITH CHECK (
    (select auth.uid()) = user_id AND status = 'pending'
  );

-- ── fraud_reports (consolidation SELECT : rapporteur + admins) ──────────────
DROP POLICY IF EXISTS "Reporter can read own reports" ON public.fraud_reports;
DROP POLICY IF EXISTS "Admins can read all reports" ON public.fraud_reports;
CREATE POLICY "Read own or admin all reports" ON public.fraud_reports
  FOR SELECT USING (
    (select auth.uid()) = reporter_id
    OR EXISTS (
      SELECT 1 FROM public.admin_users au WHERE au.user_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "Reporter can create report" ON public.fraud_reports;
CREATE POLICY "Reporter can create report" ON public.fraud_reports
  FOR INSERT WITH CHECK ((select auth.uid()) = reporter_id);

-- ── wallet_topups ───────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own topups" ON public.wallet_topups;
CREATE POLICY "Users can read own topups" ON public.wallet_topups
  FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own topups" ON public.wallet_topups;
CREATE POLICY "Users can create own topups" ON public.wallet_topups
  FOR INSERT WITH CHECK ((select auth.uid()) = user_id AND status = 'pending');

-- ── notifications ───────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications" ON public.notifications
  FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE USING ((select auth.uid()) = user_id)
             WITH CHECK ((select auth.uid()) = user_id);

-- ── user_subscriptions ──────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can read own subscription" ON public.user_subscriptions
  FOR SELECT USING ((select auth.uid()) = user_id);

-- ── subscription_renewals ───────────────────────────────────
DROP POLICY IF EXISTS "Users can read own renewal attempts" ON public.subscription_renewals;
CREATE POLICY "Users can read own renewal attempts" ON public.subscription_renewals
  FOR SELECT USING ((select auth.uid()) = user_id);


-- ═══════════════════════════════════════════════════════════
-- SECTION 4 — Index sur les clés étrangères non couvertes
-- ═══════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_driver_applications_reviewed_by
  ON public.driver_applications(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_driver_applications_user_id
  ON public.driver_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_reports_reporter_id
  ON public.fraud_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_transactions_buyer_id
  ON public.transactions(buyer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_driver_id
  ON public.transactions(driver_id);
CREATE INDEX IF NOT EXISTS idx_transactions_product_id
  ON public.transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_seller_id
  ON public.transactions(seller_id);


-- ═══════════════════════════════════════════════════════════
-- SECTION 5 — Notes sur les advisors laissés volontairement
-- ═══════════════════════════════════════════════════════════
-- • phone_otp_codes (INFO rls_enabled_no_policy) : RLS activé sans policy =
--   accès service_role uniquement. Comportement VOULU (aucun rôle client ne
--   doit lire/écrire les codes OTP en clair). On ne crée aucune policy.
COMMENT ON TABLE public.phone_otp_codes IS
  'Codes OTP téléphone. RLS activé sans policy = accès service_role only (voulu).';
--
-- • unused_index (20x) : index jamais utilisés à ce stade. Base neuve sans
--   trafic — ils deviendront utiles en production. On NE les supprime PAS.
--
-- • authenticated_security_definer_function_executable (WARN) : persiste pour
--   les RPC de la section 1a, qui DOIVENT rester appelables par les utilisateurs
--   connectés. Chacune protège son accès en interne (auth.uid() / admin_users).
