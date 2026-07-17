-- ============================================================
-- Durcissement des fonctions ajoutées par 20260717000003_admin_dashboard_tables.
--
-- encrypt_totp_secret / get_decrypted_totp_secret : SECURITY DEFINER restées
-- exécutables par anon/authenticated. Le REVOKE ... FROM PUBLIC ne retire pas
-- le GRANT par défaut du projet à anon/authenticated (même piège que
-- 20260712_advisor_hardening). get_decrypted_totp_secret déchiffrerait le
-- secret TOTP d'un admin : ne doit être appelable que par service_role
-- (l'API Next.js du dashboard). On révoque explicitement anon/authenticated.
--
-- cod_* / update_updated_at : search_path fixé (bonne pratique SECURITY).
-- ============================================================

REVOKE ALL ON FUNCTION public.encrypt_totp_secret(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_decrypted_totp_secret(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.encrypt_totp_secret(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_decrypted_totp_secret(UUID) TO service_role;

ALTER FUNCTION public.cod_driver_float_limit()      SET search_path = public;
ALTER FUNCTION public.cod_max_orders_in_progress()  SET search_path = public;
ALTER FUNCTION public.cod_max_refusals_per_month()  SET search_path = public;
ALTER FUNCTION public.update_updated_at()           SET search_path = public;
