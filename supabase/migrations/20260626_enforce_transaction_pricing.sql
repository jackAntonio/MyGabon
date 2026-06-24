-- ============================================================
-- Anti-manipulation de prix : createTransaction() (client Dart)
-- envoyait gross_amount/visible_fee/actual_fee/net_to_seller/
-- delivery_fee tels que calculés CÔTÉ CLIENT, sans aucune
-- vérification serveur contre le vrai prix du produit. Un client
-- modifié (ou un appel REST direct avec le JWT d'un utilisateur)
-- pouvait donc créer une transaction à 1 FCFA pour un produit
-- valant 850 000 FCFA : le vendeur aurait été crédité sur cette
-- fausse base une fois le paiement confirmé.
--
-- Ce trigger recalcule ces colonnes à partir de products.price et
-- du taux de frais fixe (5%) au moment de l'INSERT, quoi que le
-- client ait envoyé — la confiance se déplace du client vers la
-- base, comme pour le reste des montants d'argent de l'app.
-- ============================================================

CREATE OR REPLACE FUNCTION enforce_transaction_pricing()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_price NUMERIC;
BEGIN
  SELECT price INTO v_price FROM products WHERE id = NEW.product_id;
  IF v_price IS NULL THEN
    RAISE EXCEPTION 'Produit introuvable';
  END IF;

  NEW.gross_amount := v_price;
  NEW.visible_fee := v_price * 0.05;
  NEW.actual_fee := v_price * 0.05;
  NEW.net_to_seller := v_price * 0.95;

  -- Frais de livraison : tarif plat unique (PaymentService.standardDeliveryFee
  -- côté Dart) ou 0 — jamais un montant arbitraire envoyé par le client.
  NEW.delivery_fee := CASE WHEN NEW.delivery_fee > 0 THEN 5000 ELSE 0 END;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_transaction_pricing ON transactions;
CREATE TRIGGER trg_enforce_transaction_pricing
  BEFORE INSERT ON transactions
  FOR EACH ROW EXECUTE FUNCTION enforce_transaction_pricing();
