-- ============================================================
-- CRITIQUE, EXPLOITABLE SANS AUTHENTIFICATION : confirm_external_payment,
-- fail_external_payment, confirm_wallet_topup et fail_wallet_topup
-- (fonctions préexistantes, confirmées via information_schema.
-- routine_privileges après le push du 2026-07-08) sont censées n'être
-- appelées que par kpay-webhook (service_role), mais sont en réalité
-- exécutables par `anon` — sans authentification — via
-- POST /rest/v1/rpc/<nom>, et ne vérifient jamais qui appelle. N'importe
-- qui pouvait donc :
--   - confirm_external_payment(transaction_id, ref)  -> créditer le
--     wallet d'un vendeur sur n'importe quelle transaction en attente,
--     sans jamais payer via Kpay.
--   - confirm_wallet_topup(topup_id, ref)             -> recharger
--     n'importe quel wallet gratuitement.
--   - fail_external_payment / fail_wallet_topup        -> faire échouer
--     le paiement légitime de quelqu'un d'autre.
--
-- Cause : leurs migrations d'origine (20260625_kpay_external_payment.sql,
-- 20260629_wallet_topup.sql) n'ont jamais posé de GRANT/REVOKE explicite
-- dessus, laissant le privilège par défaut du projet (qui accorde EXECUTE
-- à anon/authenticated sur toute nouvelle fonction du schéma public,
-- antérieur à ce dépôt) s'appliquer sans restriction.
--
-- Même trou pour trois fonctions ajoutées aujourd'hui
-- (20260707000004_subscription_renewals.sql) : leur GRANT explicite
-- `TO service_role` ne suffisait pas — `anon`/`authenticated` restaient
-- exécutants via ce même privilège par défaut, jamais explicitement
-- révoqué pour elles.
--
-- Correctif : REVOKE explicite anon/authenticated/PUBLIC + GRANT
-- service_role uniquement, sur les 7 fonctions concernées. Aucun
-- changement de comportement, uniquement qui a le droit d'appeler.
-- ============================================================

REVOKE ALL ON FUNCTION confirm_external_payment(UUID, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION fail_external_payment(UUID, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION confirm_wallet_topup(UUID, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION fail_wallet_topup(UUID, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION confirm_subscription_renewal(UUID, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION fail_subscription_renewal(UUID, TEXT) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION process_subscription_renewals() FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION adjust_wallet_balance(UUID, NUMERIC) FROM anon, authenticated, PUBLIC;

GRANT EXECUTE ON FUNCTION confirm_external_payment(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION fail_external_payment(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION confirm_wallet_topup(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION fail_wallet_topup(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION confirm_subscription_renewal(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION fail_subscription_renewal(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION adjust_wallet_balance(UUID, NUMERIC) TO service_role;
-- process_subscription_renewals() est appelée par pg_cron (rôle postgres,
-- superuser, jamais bloqué par un GRANT) : pas de GRANT service_role requis,
-- seul le REVOKE ci-dessus compte pour elle.
