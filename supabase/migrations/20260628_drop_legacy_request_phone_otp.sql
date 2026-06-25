-- ============================================================
-- request_phone_otp (migration 20260624_security_hardening.sql) générait
-- et hachait l'OTP côté SQL mais ne l'envoyait jamais par SMS (RAISE NOTICE
-- uniquement). Remplacé par l'Edge Function send-otp-sms, seul endroit où
-- les credentials Twilio peuvent rester côté serveur en toute sécurité.
-- confirm_phone_otp (vérification) est inchangée et reste compatible :
-- send-otp-sms écrit dans phone_otp_codes avec le même schéma de hachage.
-- ============================================================

DROP FUNCTION IF EXISTS request_phone_otp(TEXT);
