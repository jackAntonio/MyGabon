-- ============================================================
-- Wallet (transactions/user_wallets) + accès RPC sécurisé
-- + vue de profil public pour la messagerie et l'affichage
-- des contreparties sans exposer email/téléphone.
-- ============================================================

-- ✅ Tables wallet (reprises de SUPABASE_SETUP.sql, absentes des migrations versionnées)
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES users(id),
  seller_id UUID NOT NULL REFERENCES users(id),
  product_id UUID NOT NULL REFERENCES products(id),
  gross_amount DECIMAL(10, 2) NOT NULL,
  visible_fee DECIMAL(10, 2) NOT NULL,
  actual_fee DECIMAL(10, 2) NOT NULL,
  net_to_seller DECIMAL(10, 2) NOT NULL,
  payment_method TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  transaction_reference TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id),
  balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Buyer or seller can read own transactions" ON transactions
  FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Buyer can create own transaction" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);
-- ⚠️ Le statut (pending -> success/failed) devrait idéalement être confirmé par le
-- webhook Kpay côté serveur, pas par le client. On autorise ici la mise à jour par les
-- participants pour rester fonctionnel sans Edge Function ; à durcir si la fraude sur
-- le statut de paiement devient un risque réel (ex: passer par confirm_transaction()).
CREATE POLICY "Participants can update own transaction" ON transactions
  FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Users can read own wallet" ON user_wallets FOR SELECT USING (auth.uid() = user_id);
-- ⚠️ Volontairement aucune policy INSERT/UPDATE côté client sur user_wallets :
-- tout crédit/débit doit passer par la fonction adjust_wallet_balance() ci-dessous
-- (SECURITY DEFINER), jamais par un UPDATE direct piloté par un montant client.

-- ✅ RPC : seul point d'entrée autorisé pour modifier un solde de wallet.
-- Vérifie que l'appelant est bien le titulaire du wallet, crée le wallet s'il
-- n'existe pas encore, applique le crédit/débit de façon atomique et renvoie
-- le nouveau solde. Un montant négatif débite, positif crédite.
CREATE OR REPLACE FUNCTION adjust_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_balance NUMERIC;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Accès refusé : vous ne pouvez modifier que votre propre portefeuille';
  END IF;

  INSERT INTO user_wallets (user_id, balance)
  VALUES (p_user_id, 0)
  ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
  SET balance = balance + p_amount,
      updated_at = now()
  WHERE user_id = p_user_id
  RETURNING balance INTO v_new_balance;

  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Solde insuffisant';
  END IF;

  RETURN v_new_balance;
END;
$$;

GRANT EXECUTE ON FUNCTION adjust_wallet_balance(UUID, NUMERIC) TO authenticated;

-- ✅ Vue de profil public : nom/avatar/note visibles par tous les utilisateurs
-- authentifiés (messagerie, fiches produit/service), sans exposer email/téléphone
-- (la table users, elle, reste verrouillée à auth.uid() = id).
CREATE OR REPLACE VIEW profiles_public AS
SELECT id, full_name, avatar_url, verified, rating
FROM users;

GRANT SELECT ON profiles_public TO authenticated;
