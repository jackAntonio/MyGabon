-- ============================================================
-- Durcissement sécurité (audit du 2026-06-24) :
-- 1) Empêche le mass assignment sur users (auto-vérification,
--    fausse note...) en restreignant les colonnes modifiables
--    par le client au niveau privilèges Postgres (indépendant
--    de ce que la RLS autorise au niveau ligne).
-- 2) Ajoute la policy INSERT manquante sur users (le INSERT du
--    client à l'inscription échouait silencieusement faute de
--    policy, RLS étant "deny by default").
-- 3) (colonne rating déplacée vers wallet_rpc_and_public_profiles.sql,
--    seul fichier qui la consomme désormais — cf. son commentaire.)
-- 4) Remplace l'OTP téléphone (jusqu'ici généré/vérifié côté
--    client, RNG prévisible) par un flux serveur : phone_otp_codes
--    + RPC request_phone_otp/confirm_phone_otp, seul point
--    d'entrée autorisé pour positionner users.verified = true.
-- ============================================================

-- (colonne rating déplacée vers wallet_rpc_and_public_profiles.sql, qui la
-- consomme et tourne avant cette migration — cf. son commentaire)

-- ✅ Policy INSERT manquante : sans elle, _createUserProfile() échouait pour
-- tout nouvel inscrit (RLS activée, aucune policy INSERT = refus systématique).
CREATE POLICY "Users can insert own row" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ✅ Verrou anti mass-assignment : seules ces colonnes restent modifiables par
-- le client (updateUserProfile). verified/verified_at/rating/email/id ne
-- peuvent plus être écrits que par des fonctions SECURITY DEFINER (qui
-- s'exécutent avec les privilèges du propriétaire de la fonction, pas du
-- rôle authenticated, donc non affectées par ce REVOKE).
REVOKE UPDATE ON users FROM authenticated;
GRANT UPDATE (full_name, phone_number, avatar_url, bio) ON users TO authenticated;

REVOKE INSERT ON users FROM authenticated;
GRANT INSERT (id, email, full_name, phone_number) ON users TO authenticated;

-- ============================================================
-- OTP téléphone côté serveur
-- ============================================================

CREATE TABLE IF NOT EXISTS phone_otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  phone_number TEXT NOT NULL,
  code_hash TEXT NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  consumed BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);
ALTER TABLE phone_otp_codes ENABLE ROW LEVEL SECURITY;
-- ⚠️ Volontairement aucune policy pour authenticated/anon : cette table n'est
-- accessible qu'au travers des fonctions SECURITY DEFINER ci-dessous (mêmes
-- propriétaire/privilèges que la table -> bypass RLS, comme user_wallets).

CREATE INDEX IF NOT EXISTS idx_phone_otp_user_created
  ON phone_otp_codes(user_id, created_at DESC);

-- ✅ RPC : génère un OTP à 6 chiffres côté serveur (pgcrypto, CSPRNG), le
-- hache avant stockage, limite à 3 demandes / 15 min par utilisateur.
-- N'envoie PAS le code au client (RETURNS VOID) : tant que l'envoi SMS réel
-- (Edge Function + Twilio, cf. .env.example) n'est pas branché, le code
-- n'apparaît que dans les logs serveur (RAISE NOTICE), jamais côté client.
CREATE OR REPLACE FUNCTION request_phone_otp(p_phone_number TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code TEXT;
  v_recent_count INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  SELECT COUNT(*) INTO v_recent_count
  FROM phone_otp_codes
  WHERE user_id = auth.uid() AND created_at > now() - INTERVAL '15 minutes';

  IF v_recent_count >= 3 THEN
    RAISE EXCEPTION 'Trop de demandes, réessayez plus tard';
  END IF;

  v_code := lpad((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000)::text, 6, '0');

  INSERT INTO phone_otp_codes (user_id, phone_number, code_hash, expires_at)
  VALUES (
    auth.uid(),
    p_phone_number,
    encode(digest(v_code || auth.uid()::text, 'sha256'), 'hex'),
    now() + INTERVAL '5 minutes'
  );

  -- TODO production : remplacer par un appel Edge Function -> Twilio.
  RAISE NOTICE 'OTP (dev only, ne JAMAIS logguer en prod) pour %: %', p_phone_number, v_code;
END;
$$;
GRANT EXECUTE ON FUNCTION request_phone_otp(TEXT) TO authenticated;

-- ✅ RPC : seul point d'entrée pour confirmer l'OTP et passer users.verified
-- à true. Vérifie expiration (5 min) et nombre de tentatives (max 5).
CREATE OR REPLACE FUNCTION confirm_phone_otp(p_phone_number TEXT, p_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_record RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  SELECT * INTO v_record
  FROM phone_otp_codes
  WHERE user_id = auth.uid()
    AND phone_number = p_phone_number
    AND consumed = false
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND OR v_record.expires_at < now() OR v_record.attempts >= 5 THEN
    RETURN false;
  END IF;

  UPDATE phone_otp_codes SET attempts = attempts + 1 WHERE id = v_record.id;

  IF v_record.code_hash <> encode(digest(p_code || auth.uid()::text, 'sha256'), 'hex') THEN
    RETURN false;
  END IF;

  UPDATE phone_otp_codes SET consumed = true WHERE id = v_record.id;
  UPDATE users SET verified = true, verified_at = now(), phone_number = p_phone_number
    WHERE id = auth.uid();

  RETURN true;
END;
$$;
GRANT EXECUTE ON FUNCTION confirm_phone_otp(TEXT, TEXT) TO authenticated;
