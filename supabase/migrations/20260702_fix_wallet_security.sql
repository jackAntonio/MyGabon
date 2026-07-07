-- ============================================================
-- CRITIQUE : adjust_wallet_balance était GRANT à authenticated
-- → n'importe quel utilisateur pouvait s'auto-créditer via RPC
-- directement, sans passer par Kpay (ex: appel REST direct
-- POST /rest/v1/rpc/adjust_wallet_balance avec amount positif).
--
-- Les seuls chemins légitimes pour créditer un wallet :
--   - confirm_external_payment  (webhook Kpay, service_role)
--   - confirm_wallet_topup      (webhook Kpay, service_role)
--   - complete_marketplace_transaction (SECURITY DEFINER, buyer)
--
-- adjust_wallet_balance reste disponible pour service_role (usage
-- interne futur possible), mais inaccessible depuis le client.
-- ============================================================
REVOKE ALL ON FUNCTION adjust_wallet_balance(UUID, NUMERIC) FROM authenticated;
REVOKE ALL ON FUNCTION adjust_wallet_balance(UUID, NUMERIC) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION adjust_wallet_balance(UUID, NUMERIC) TO service_role;

-- MOYEN : plafond wallet topup — sans contrainte MAX, une recharge
-- de 999 999 999 FCFA crée une ligne pending bloquée indéfiniment
-- (Kpay rejette de son côté mais la ligne reste orpheline).
-- 5 000 000 FCFA correspond à la limite haute réaliste Airtel Money Gabon.
ALTER TABLE wallet_topups
  DROP CONSTRAINT IF EXISTS wallet_topups_amount_check,
  ADD CONSTRAINT wallet_topups_amount_check CHECK (amount > 0 AND amount <= 5000000);
