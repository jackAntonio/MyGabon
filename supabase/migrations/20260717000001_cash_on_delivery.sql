-- ============================================================
-- Paiement à la livraison (cash on delivery).
--
-- À ne pas confondre avec le 'cash' déjà en place : celui-ci n'est qu'un
-- accord de gré à gré entre acheteur et vendeur (rendez-vous physique,
-- aucun livreur, transaction laissée 'pending' à vie, aucun mouvement
-- d'argent dans l'app). Ici, le livreur MyGabon encaisse physiquement à
-- la remise du colis, et c'est SA confirmation qui crédite le vendeur.
--
-- La difficulté propre au COD, qui explique tout ce fichier : l'argent
-- est en espèces dans la poche du livreur alors que le vendeur, lui, est
-- crédité en wallet. La plateforme avance donc ce montant et détient une
-- créance sur le livreur. D'où :
--   • driver_cash_collections : le ledger de ce que chaque livreur doit
--     encore remettre (sans lui, la créance n'existe nulle part et la
--     recette disparaît silencieusement) ;
--   • cod_driver_float_limit() : plafond d'encours non remis, qui borne
--     la perte maximale si un livreur part avec la caisse ;
--   • éligibilité acheteur (téléphone vérifié, nb de commandes en cours,
--     historique de refus) : le COD est le seul mode où l'acheteur peut
--     mobiliser un vendeur et un livreur sans avoir rien payé d'avance.
-- ============================================================


-- ═══════════════════════════════════════════════════════════
-- SECTION 0 — Prérequis sécurité (bloquant pour le COD)
-- ═══════════════════════════════════════════════════════════
-- La policy UPDATE "Participants can update own transaction" n'a AUCUN
-- WITH CHECK : acheteur et vendeur peuvent réécrire n'importe quelle
-- colonne de leur propre ligne — y compris driver_id, delivery_status,
-- status et net_to_seller. C'est déjà exploitable aujourd'hui (se poser
-- driver_id = soi-même + delivery_status = 'claimed' via un UPDATE REST
-- direct, puis appeler complete_delivery : 50% des frais de livraison
-- crédités sur une course jamais faite). Avec le COD ce serait bien pire :
-- confirm_cash_on_delivery créditerait net_to_seller au vendeur sans
-- qu'un centime n'ait jamais été encaissé.
--
-- Aucun écran ne fait d'UPDATE direct sur transactions (vérifié : le
-- client ne fait que select/insert/stream + RPC), la policy ne sert donc
-- rien de légitime. On la supprime : deny by default, tout passe par les
-- RPC SECURITY DEFINER qui, elles, vérifient qui appelle.
DROP POLICY IF EXISTS "Participants can update own transaction" ON public.transactions;


-- ═══════════════════════════════════════════════════════════
-- SECTION 1 — Valeurs autorisées
-- ═══════════════════════════════════════════════════════════
-- payment_method et delivery_status étaient des TEXT libres : une faute de
-- frappe ('cash_on_delivry') passait l'INSERT et sortait silencieusement la
-- ligne de tous les filtres COD — donc du plafond d'encours et du ledger.
-- Un mode de paiement inconnu du serveur ne doit pas pouvoir exister.
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_payment_method_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_payment_method_check
  CHECK (payment_method IN (
    'mygabon_wallet', 'airtel_money', 'moov_money',
    'apple_pay', 'google_pay', 'cash', 'cash_on_delivery'
  ));

-- 'returned' = colis rapporté faute de paiement à la remise (nouveau, propre au COD).
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_delivery_status_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_delivery_status_check
  CHECK (delivery_status IN ('none', 'pending', 'claimed', 'delivered', 'returned'));


-- ═══════════════════════════════════════════════════════════
-- SECTION 2 — Paramètres du COD (source unique de vérité)
-- ═══════════════════════════════════════════════════════════
-- Des fonctions plutôt que des littéraux disséminés : ces seuils sont lus
-- à la fois par les contrôles serveur et par l'UI (qui doit afficher le
-- même plafond que celui réellement appliqué).

-- Encours d'espèces qu'un livreur peut détenir avant de devoir remettre sa
-- recette. Plafonne la perte en cas de livreur indélicat.
CREATE OR REPLACE FUNCTION cod_driver_float_limit()
RETURNS NUMERIC LANGUAGE sql IMMUTABLE AS $$ SELECT 150000::NUMERIC $$;

-- Commandes COD simultanément en attente de paiement, par acheteur.
CREATE OR REPLACE FUNCTION cod_max_orders_in_progress()
RETURNS INT LANGUAGE sql IMMUTABLE AS $$ SELECT 3 $$;

-- Refus de paiement à la remise tolérés sur 30 jours glissants.
CREATE OR REPLACE FUNCTION cod_max_refusals_per_month()
RETURNS INT LANGUAGE sql IMMUTABLE AS $$ SELECT 2 $$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 3 — Ledger des espèces détenues par les livreurs
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS driver_cash_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL UNIQUE REFERENCES transactions(id),
  driver_id UUID NOT NULL REFERENCES users(id),
  amount_collected NUMERIC NOT NULL,  -- espèces prises en main par le livreur
  driver_payout NUMERIC NOT NULL,     -- sa part, déjà créditée sur son wallet
  amount_owed NUMERIC NOT NULL,       -- reste dû à MyGabon (collecté - part livreur)
  remitted BOOLEAN NOT NULL DEFAULT false,
  remitted_at TIMESTAMP,
  confirmed_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now()
);
ALTER TABLE driver_cash_collections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read own or admin all cash collections" ON driver_cash_collections;
CREATE POLICY "Read own or admin all cash collections" ON driver_cash_collections
  FOR SELECT USING (
    (select auth.uid()) = driver_id
    OR EXISTS (
      SELECT 1 FROM public.admin_users au WHERE au.user_id = (select auth.uid())
    )
  );
-- ⚠️ Volontairement aucune policy INSERT/UPDATE/DELETE : le ledger n'est
-- écrit que par confirm_cash_on_delivery / confirm_cash_remittance
-- (SECURITY DEFINER). Un livreur qui pourrait écrire ici effacerait sa
-- propre dette.

CREATE INDEX IF NOT EXISTS idx_driver_cash_collections_outstanding
  ON driver_cash_collections(driver_id) WHERE NOT remitted;
CREATE INDEX IF NOT EXISTS idx_driver_cash_collections_confirmed_by
  ON driver_cash_collections(confirmed_by);


-- ═══════════════════════════════════════════════════════════
-- SECTION 4 — Éligibilité (fonctions internes)
-- ═══════════════════════════════════════════════════════════

-- Espèces encaissées par un livreur et pas encore remises à MyGabon.
CREATE OR REPLACE FUNCTION driver_cash_float(p_driver_id UUID)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(amount_owed), 0)
    FROM driver_cash_collections
   WHERE driver_id = p_driver_id AND NOT remitted;
$$;

-- Motif de refus du COD pour cet acheteur, NULL s'il est éligible.
-- Renvoie un texte directement affichable : c'est ce que l'acheteur voit,
-- aussi bien en pré-contrôle (check_cod_eligibility) qu'en message
-- d'exception si l'INSERT est tenté malgré tout.
CREATE OR REPLACE FUNCTION cod_rejection_reason(p_buyer_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user RECORD;
  v_in_progress INT;
  v_refusals INT;
BEGIN
  SELECT verified, blocked INTO v_user FROM users WHERE id = p_buyer_id;
  IF NOT FOUND THEN
    RETURN 'Compte introuvable';
  END IF;

  IF v_user.blocked THEN
    RETURN 'Votre compte est bloqué : paiement à la livraison indisponible.';
  END IF;

  -- users.verified = numéro confirmé par OTP (cf. confirm_phone_otp). Le
  -- COD engage un livreur sur une adresse : on exige au minimum un numéro
  -- joignable, sinon un compte jetable suffit à mobiliser une course.
  IF NOT COALESCE(v_user.verified, false) THEN
    RETURN 'Vérifiez votre numéro de téléphone pour payer à la livraison.';
  END IF;

  SELECT count(*) INTO v_in_progress
    FROM transactions
   WHERE buyer_id = p_buyer_id
     AND payment_method = 'cash_on_delivery'
     AND status = 'pending';
  IF v_in_progress >= cod_max_orders_in_progress() THEN
    RETURN format(
      'Vous avez déjà %s commande(s) à payer à la livraison en cours. Réglez-les avant d''en passer une autre.',
      v_in_progress
    );
  END IF;

  SELECT count(*) INTO v_refusals
    FROM transactions
   WHERE buyer_id = p_buyer_id
     AND payment_method = 'cash_on_delivery'
     AND delivery_status = 'returned'
     AND created_at > now() - INTERVAL '30 days';
  IF v_refusals >= cod_max_refusals_per_month() THEN
    RETURN 'Trop de commandes refusées à la livraison ce mois-ci. Utilisez un autre moyen de paiement.';
  END IF;

  RETURN NULL;
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 5 — Invariants COD imposés à l'INSERT
-- ═══════════════════════════════════════════════════════════
-- Reprise de enforce_transaction_pricing (20260626) : bloc COD ajouté, le
-- reste inchangé. Ces règles vivent dans le trigger et pas seulement dans
-- create_cash_on_delivery_order() parce que la policy INSERT laisse tout
-- acheteur insérer sa propre ligne en REST direct — la RPC et ses
-- contrôles seraient sinon contournables en une requête curl.
CREATE OR REPLACE FUNCTION enforce_transaction_pricing()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_price NUMERIC;
  v_cod_reason TEXT;
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

  IF NEW.payment_method = 'cash_on_delivery' THEN
    -- Le COD n'existe que porté par un livreur : sans livraison, personne
    -- n'encaisse et la transaction resterait 'pending' indéfiniment.
    IF NEW.delivery_fee <= 0 THEN
      RAISE EXCEPTION 'Le paiement à la livraison exige une livraison MyGabon';
    END IF;

    -- Acheter son propre article en COD = se faire créditer 95% en wallet
    -- contre des espèces remises à un livreur ; avec un livreur complice
    -- qui ne remet jamais la recette, c'est de l'argent créé de rien.
    IF NEW.buyer_id = NEW.seller_id THEN
      RAISE EXCEPTION 'Vous ne pouvez pas commander votre propre article';
    END IF;

    -- Un COD naît toujours non payé et sans livreur, quoi qu'envoie le
    -- client : seule confirm_cash_on_delivery peut faire bouger ces
    -- colonnes ensuite.
    NEW.status := 'pending';
    NEW.delivery_status := 'pending';
    NEW.driver_id := NULL;
    NEW.driver_payout := 0;
    NEW.completed_at := NULL;

    v_cod_reason := cod_rejection_reason(NEW.buyer_id);
    IF v_cod_reason IS NOT NULL THEN
      RAISE EXCEPTION '%', v_cod_reason;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_transaction_pricing ON transactions;
CREATE TRIGGER trg_enforce_transaction_pricing
  BEFORE INSERT ON transactions
  FOR EACH ROW EXECUTE FUNCTION enforce_transaction_pricing();


-- ═══════════════════════════════════════════════════════════
-- SECTION 6 — Passer une commande en paiement à la livraison
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION create_cash_on_delivery_order(p_product_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID := auth.uid();
  v_seller_id UUID;
  v_price NUMERIC;
  v_txn_id UUID;
BEGIN
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  SELECT seller_id, price INTO v_seller_id, v_price
    FROM products WHERE id = p_product_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Produit introuvable';
  END IF;

  -- Montants et invariants COD (re)posés par trg_enforce_transaction_pricing :
  -- ce qui suit n'est qu'un jeu de valeurs NOT NULL cohérentes, pas la
  -- source de vérité.
  INSERT INTO transactions (
    buyer_id, seller_id, product_id, gross_amount, visible_fee, actual_fee,
    net_to_seller, payment_method, status, delivery_fee, delivery_status
  ) VALUES (
    v_buyer_id, v_seller_id, p_product_id, v_price, v_price * 0.05, v_price * 0.05,
    v_price * 0.95, 'cash_on_delivery', 'pending', 5000, 'pending'
  ) RETURNING id INTO v_txn_id;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_seller_id,
    'Nouvelle commande à livrer',
    'Un acheteur a commandé votre article en paiement à la livraison. Vous serez crédité une fois le colis remis et encaissé.',
    'delivery_status',
    jsonb_build_object('transaction_id', v_txn_id, 'delivery_status', 'pending')
  );

  RETURN v_txn_id;
END;
$$;

-- Pré-contrôle pour l'UI : permet d'expliquer pourquoi le COD est grisé
-- au lieu de laisser l'acheteur se heurter à une exception au moment de
-- valider. N'est PAS le contrôle qui fait autorité (cf. trigger).
CREATE OR REPLACE FUNCTION check_cod_eligibility()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reason TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  v_reason := cod_rejection_reason(auth.uid());
  RETURN jsonb_build_object('eligible', v_reason IS NULL, 'reason', v_reason);
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 7 — Prise en charge : plafond d'encours + anti-collusion
-- ═══════════════════════════════════════════════════════════
-- Reprise de claim_delivery (20260707000003, notification conservée) avec
-- les gardes propres au COD.
CREATE OR REPLACE FUNCTION claim_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
  v_to_collect NUMERIC;
  v_float NUMERIC;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM driver_applications WHERE user_id = auth.uid() AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'Accès refusé : réservé aux livreurs approuvés';
  END IF;

  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND OR v_txn.delivery_status <> 'pending' OR v_txn.driver_id IS NOT NULL THEN
    RAISE EXCEPTION 'Livraison déjà prise ou introuvable';
  END IF;

  IF v_txn.payment_method = 'cash_on_delivery' THEN
    -- Livrer sa propre vente/commande en COD, c'est être des deux côtés de
    -- l'encaissement : le vendeur-livreur confirme un paiement fictif, se
    -- crédite net_to_seller et ne remet jamais d'espèces (il n'en a pas
    -- reçu). Les livraisons déjà payées, elles, ne posent pas ce problème.
    IF v_txn.seller_id = auth.uid() THEN
      RAISE EXCEPTION 'Vous ne pouvez pas livrer votre propre vente en paiement à la livraison';
    END IF;
    IF v_txn.buyer_id = auth.uid() THEN
      RAISE EXCEPTION 'Vous ne pouvez pas livrer votre propre commande';
    END IF;

    v_to_collect := v_txn.gross_amount + v_txn.visible_fee + v_txn.delivery_fee;
    v_float := driver_cash_float(auth.uid());
    IF v_float + v_to_collect > cod_driver_float_limit() THEN
      RAISE EXCEPTION
        'Plafond d''encours espèces atteint : % FCFA non remis sur % autorisés. Remettez votre recette à MyGabon avant de prendre cette livraison.',
        v_float::BIGINT, cod_driver_float_limit()::BIGINT;
    END IF;
  END IF;

  UPDATE transactions
    SET driver_id = auth.uid(), delivery_status = 'claimed'
    WHERE id = p_transaction_id;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.buyer_id,
    'Livreur en route',
    CASE WHEN v_txn.payment_method = 'cash_on_delivery'
      THEN format('Un livreur a pris en charge votre commande. Préparez %s FCFA en espèces.',
                  (v_txn.gross_amount + v_txn.visible_fee + v_txn.delivery_fee)::BIGINT)
      ELSE 'Un livreur a pris en charge votre commande.'
    END,
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'claimed')
  );
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 8 — Livraison classique : interdite sur un COD
-- ═══════════════════════════════════════════════════════════
-- Reprise de complete_delivery (20260707000003) + garde COD. Sans elle, un
-- livreur passerait un COD en 'delivered' sans encaisser : le vendeur ne
-- serait jamais crédité (confirm_cash_on_delivery exige 'claimed') et la
-- commande finirait en impasse, colis livré et vendeur impayé.
CREATE OR REPLACE FUNCTION complete_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
  v_payout NUMERIC;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;
  IF v_txn.driver_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Accès refusé : vous n''êtes pas le livreur assigné';
  END IF;
  IF v_txn.delivery_status <> 'claimed' THEN
    RAISE EXCEPTION 'Livraison non réclamée ou déjà terminée';
  END IF;
  IF v_txn.payment_method = 'cash_on_delivery' THEN
    RAISE EXCEPTION 'Commande à encaisser : confirmez le paiement reçu au lieu de marquer livrée';
  END IF;

  v_payout := v_txn.delivery_fee * 0.5;

  INSERT INTO user_wallets (user_id, balance) VALUES (auth.uid(), 0)
    ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
    SET balance = balance + v_payout, updated_at = now()
    WHERE user_id = auth.uid();

  UPDATE transactions
    SET delivery_status = 'delivered', driver_payout = v_payout
    WHERE id = p_transaction_id;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.buyer_id,
    'Commande livrée',
    'Votre commande a été livrée avec succès.',
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'delivered')
  );
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 9 — Encaissement à la remise
-- ═══════════════════════════════════════════════════════════
-- Le seul point où un COD devient 'success'. C'est le livreur qui confirme
-- (et non l'acheteur) : il est le seul témoin de la remise, et c'est lui
-- qui devient comptable des espèces — le ledger transforme sa confirmation
-- en dette envers MyGabon, ce qui rend une fausse confirmation coûteuse
-- pour lui plutôt que gratuite.
CREATE OR REPLACE FUNCTION confirm_cash_on_delivery(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
  v_collected NUMERIC;
  v_payout NUMERIC;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;
  IF v_txn.driver_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Accès refusé : vous n''êtes pas le livreur assigné';
  END IF;
  IF v_txn.payment_method <> 'cash_on_delivery' THEN
    RAISE EXCEPTION 'Cette fonction ne traite que le paiement à la livraison';
  END IF;
  IF v_txn.status <> 'pending' THEN
    RAISE EXCEPTION 'Transaction déjà traitée';
  END IF;
  IF v_txn.delivery_status <> 'claimed' THEN
    RAISE EXCEPTION 'Livraison non réclamée ou déjà terminée';
  END IF;

  -- Exactement ce que l'acheteur voyait en "Total à payer" à la commande.
  v_collected := v_txn.gross_amount + v_txn.visible_fee + v_txn.delivery_fee;
  v_payout := v_txn.delivery_fee * 0.5;

  INSERT INTO user_wallets (user_id, balance) VALUES (v_txn.seller_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_wallets (user_id, balance) VALUES (auth.uid(), 0)
    ON CONFLICT (user_id) DO NOTHING;

  UPDATE user_wallets
    SET balance = balance + v_txn.net_to_seller, updated_at = now()
    WHERE user_id = v_txn.seller_id;
  UPDATE user_wallets
    SET balance = balance + v_payout, updated_at = now()
    WHERE user_id = auth.uid();

  UPDATE transactions
    SET status = 'success',
        completed_at = now(),
        delivery_status = 'delivered',
        driver_payout = v_payout
    WHERE id = p_transaction_id;

  -- Le livreur garde les espèces mais sa part lui a été créditée en wallet :
  -- il doit donc le collecté MOINS sa part. UNIQUE(transaction_id) rend
  -- l'écriture non rejouable même si la RPC était appelée deux fois.
  INSERT INTO driver_cash_collections (
    transaction_id, driver_id, amount_collected, driver_payout, amount_owed
  ) VALUES (
    p_transaction_id, auth.uid(), v_collected, v_payout, v_collected - v_payout
  );

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.buyer_id,
    'Commande livrée et payée',
    format('Votre commande a été remise et réglée (%s FCFA en espèces).', v_collected::BIGINT),
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'delivered')
  );

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.seller_id,
    'Vente encaissée',
    format('Le livreur a encaissé votre vente : %s FCFA crédités sur votre wallet.',
           v_txn.net_to_seller::BIGINT),
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'delivered')
  );
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 10 — Refus de paiement à la remise
-- ═══════════════════════════════════════════════════════════
-- Sortie de secours obligatoire : sans elle, un acheteur absent ou qui
-- refuse de payer laisse la livraison bloquée en 'claimed' à vie (le
-- livreur ne peut ni encaisser ni marquer livrée), et le compteur de
-- commandes COD en cours de cet acheteur ne redescend jamais.
--
-- Le livreur n'est pas rémunéré ici : sa part est adossée aux frais de
-- livraison, qui n'ont pas été encaissés. Le dédommagement d'une course à
-- vide est une décision commerciale, à traiter hors app (admin/wallet).
CREATE OR REPLACE FUNCTION report_cash_on_delivery_refused(
  p_transaction_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn RECORD;
BEGIN
  SELECT * INTO v_txn FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;
  IF v_txn.driver_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Accès refusé : vous n''êtes pas le livreur assigné';
  END IF;
  IF v_txn.payment_method <> 'cash_on_delivery' THEN
    RAISE EXCEPTION 'Cette fonction ne traite que le paiement à la livraison';
  END IF;
  IF v_txn.status <> 'pending' OR v_txn.delivery_status <> 'claimed' THEN
    RAISE EXCEPTION 'Livraison non réclamée ou déjà terminée';
  END IF;

  UPDATE transactions
    SET status = 'failed',
        delivery_status = 'returned',
        notes = COALESCE(p_reason, 'Paiement refusé à la livraison')
    WHERE id = p_transaction_id;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.buyer_id,
    'Commande annulée',
    'Votre commande à payer à la livraison a été annulée faute de paiement. Les refus répétés suspendent l''accès à ce mode de paiement.',
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'returned')
  );

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_txn.seller_id,
    'Commande retournée',
    'L''acheteur n''a pas réglé à la livraison : votre article vous est rapporté.',
    'delivery_status',
    jsonb_build_object('transaction_id', p_transaction_id, 'delivery_status', 'returned')
  );
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 11 — Remise de la recette
-- ═══════════════════════════════════════════════════════════
-- Un admin confirme avoir reçu les espèces d'un livreur, ce qui libère
-- d'autant son plafond d'encours. Réservé aux admins : un livreur qui
-- pourrait solder sa propre dette rendrait le plafond inopérant.
CREATE OR REPLACE FUNCTION confirm_cash_remittance(p_collection_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_driver_id UUID;
  v_amount NUMERIC;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Accès refusé : réservé aux administrateurs';
  END IF;

  UPDATE driver_cash_collections
    SET remitted = true, remitted_at = now(), confirmed_by = auth.uid()
    WHERE id = p_collection_id AND NOT remitted
    RETURNING driver_id, amount_owed INTO v_driver_id, v_amount;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Remise introuvable ou déjà confirmée';
  END IF;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (
    v_driver_id,
    'Recette remise confirmée',
    format('MyGabon a confirmé la remise de %s FCFA. Votre plafond d''encours est libéré d''autant.',
           v_amount::BIGINT),
    'cash_remittance',
    jsonb_build_object('collection_id', p_collection_id, 'amount', v_amount)
  );
END;
$$;

-- Encours du livreur connecté, pour son tableau de bord.
CREATE OR REPLACE FUNCTION my_driver_cash_summary()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owed NUMERIC;
  v_limit NUMERIC := cod_driver_float_limit();
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  v_owed := driver_cash_float(auth.uid());
  RETURN jsonb_build_object(
    'owed', v_owed,
    'limit', v_limit,
    'remaining', GREATEST(v_limit - v_owed, 0)
  );
END;
$$;


-- ═══════════════════════════════════════════════════════════
-- SECTION 12 — Droits d'exécution
-- ═══════════════════════════════════════════════════════════
-- Même règle que 20260712_advisor_hardening : le privilège par défaut du
-- projet accorde EXECUTE à anon/authenticated sur toute nouvelle fonction
-- du schéma public — il faut donc REVOKE explicitement, un simple GRANT
-- ciblé ne restreint rien.

-- 12a. Appelables par un utilisateur connecté (chacune vérifie en interne
--      qui appelle : auth.uid(), livreur assigné, ou admin_users).
DO $$
DECLARE
  fn text;
  rpcs text[] := ARRAY[
    'public.create_cash_on_delivery_order(uuid)',
    'public.check_cod_eligibility()',
    'public.confirm_cash_on_delivery(uuid)',
    'public.report_cash_on_delivery_refused(uuid, text)',
    'public.confirm_cash_remittance(uuid)',
    'public.my_driver_cash_summary()',
    'public.claim_delivery(uuid)',
    'public.complete_delivery(uuid)'
  ];
BEGIN
  FOREACH fn IN ARRAY rpcs LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', fn);
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', fn);
  END LOOP;
END $$;

-- 12b. Fonctions internes : jamais appelables via /rest/v1/rpc. Elles
--      prennent un user_id en paramètre (cod_rejection_reason,
--      driver_cash_float) et diraient donc à n'importe qui si un tiers est
--      bloqué ou combien d'espèces un autre livreur transporte — une
--      information qui désigne une cible physique. Les RPC ci-dessus les
--      appellent en SECURITY DEFINER, donc avec les droits du propriétaire :
--      aucun GRANT client n'est nécessaire pour que ça fonctionne.
DO $$
DECLARE
  fn text;
  internals text[] := ARRAY[
    'public.cod_rejection_reason(uuid)',
    'public.driver_cash_float(uuid)',
    'public.cod_driver_float_limit()',
    'public.cod_max_orders_in_progress()',
    'public.cod_max_refusals_per_month()',
    'public.enforce_transaction_pricing()'
  ];
BEGIN
  FOREACH fn IN ARRAY internals LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', fn);
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', fn);
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', fn);
  END LOOP;
END $$;


COMMENT ON TABLE public.driver_cash_collections IS
  'Espèces encaissées par les livreurs en paiement à la livraison et dues à '
  'MyGabon. Écrite uniquement par confirm_cash_on_delivery / '
  'confirm_cash_remittance (SECURITY DEFINER) : aucune policy INSERT/UPDATE.';
