// Edge Function : seul point d'entrée autorisé à appeler l'API Kpay pour
// initier un paiement mobile money (Airtel Money Gabon).
//
// Pourquoi côté serveur et pas directement depuis l'app Flutter : les
// credentials Kpay (X-API-Key + X-Secret-Key, ce dernier explicitement
// nommé "Secret key" dans la doc Kpay) ne doivent JAMAIS être compilées
// dans l'app mobile (extractibles d'un APK/IPA) — règle explicite du
// projet ("Jamais exposer les clés API paiement dans le code Flutter").
// Le client appelle cette fonction avec son JWT Supabase ; elle vérifie
// que l'appelant est bien l'acheteur de la transaction (RLS), puis relaie
// l'appel à Kpay avec les secrets côté serveur.
//
// Référence API (https://kpay.site/documentation) :
//   POST https://admin.kpay.site/api/v1/payments/init
//   Headers: X-API-Key, X-Secret-Key, Content-Type: application/json
//   Body: { amount, provider, phoneNumber, externalId, description? }
//   Réponse (201): { id, status, reference, amount, currency, provider, phoneNumber }
//   Pas d'étape de confirmation OTP : l'utilisateur valide directement sur
//   son téléphone (USSD). Le webhook (kpay-webhook) reste l'autorité pour
//   le statut final.
//
// Déploiement :
//   supabase functions deploy kpay-initiate
//   supabase secrets set KPAY_API_KEY=kpay_live_xxx KPAY_SECRET_KEY=sk_live_xxx
//   supabase secrets set ALLOWED_ORIGINS=https://app.mygabon.ga  (optionnel,
//   uniquement si cette fonction est aussi appelée depuis un navigateur)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const KPAY_API_KEY = Deno.env.get("KPAY_API_KEY") ?? "";
const KPAY_SECRET_KEY = Deno.env.get("KPAY_SECRET_KEY") ?? "";
const KPAY_BASE_URL = "https://admin.kpay.site/api/v1";

// Seul provider Gabon documenté par Kpay à ce jour (Moov Money Gabon
// n'apparaît dans aucune liste officielle des opérateurs supportés).
const GABON_PROVIDER = "AIRTEL_GAB";

// Origines web autorisées à appeler cette fonction depuis un navigateur
// (ex. "https://app.mygabon.ga,https://admin.mygabon.ga"). Sans configuration,
// aucune origine n'est reflétée : le navigateur bloque alors l'appel
// cross-origin (fail-closed). N'affecte pas l'app mobile/les appels
// serveur-à-serveur, qui n'envoient pas d'en-tête Origin et ne sont pas
// soumis à CORS.
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

function corsHeadersFor(origin: string | null) {
  return {
    "Access-Control-Allow-Origin": origin && ALLOWED_ORIGINS.includes(origin) ? origin : "",
    "Access-Control-Allow-Headers": "authorization, content-type",
    "Vary": "Origin",
  };
}

Deno.serve(async (req) => {
  const corsHeaders = corsHeadersFor(req.headers.get("origin"));
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  if (!KPAY_API_KEY || !KPAY_SECRET_KEY) {
    return new Response(
      JSON.stringify({ success: false, message: "Kpay non configuré côté serveur" }),
      { status: 503, headers: corsHeaders },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ success: false, message: "Non authentifié" }), {
      status: 401,
      headers: corsHeaders,
    });
  }

  let body: { transactionId?: string; phoneNumber?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ success: false, message: "JSON invalide" }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  const { transactionId, phoneNumber } = body;
  if (!transactionId || !phoneNumber) {
    return new Response(
      JSON.stringify({ success: false, message: "transactionId et phoneNumber requis" }),
      { status: 400, headers: corsHeaders },
    );
  }

  // Client "au nom de l'utilisateur" : la RLS s'applique, donc le SELECT
  // ci-dessous ne renverra une ligne que si l'appelant est buyer ou seller
  // de cette transaction.
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: user, error: userError } = await userClient.auth.getUser();
  if (userError || !user?.user) {
    return new Response(JSON.stringify({ success: false, message: "Session invalide" }), {
      status: 401,
      headers: corsHeaders,
    });
  }

  const { data: txn, error: txnError } = await userClient
    .from("transactions")
    .select("id, buyer_id, gross_amount, visible_fee, delivery_fee, status, payment_method")
    .eq("id", transactionId)
    .single();

  if (txnError || !txn) {
    return new Response(JSON.stringify({ success: false, message: "Transaction introuvable" }), {
      status: 404,
      headers: corsHeaders,
    });
  }
  if (txn.buyer_id !== user.user.id) {
    return new Response(
      JSON.stringify({ success: false, message: "Vous n'êtes pas l'acheteur de cette transaction" }),
      { status: 403, headers: corsHeaders },
    );
  }
  if (txn.status !== "pending") {
    return new Response(JSON.stringify({ success: false, message: "Transaction déjà traitée" }), {
      status: 409,
      headers: corsHeaders,
    });
  }
  if (txn.payment_method !== "airtel_money") {
    return new Response(
      JSON.stringify({ success: false, message: "Méthode de paiement non gérée par cette fonction" }),
      { status: 400, headers: corsHeaders },
    );
  }

  // Anti-abus : limite le nombre d'appels Kpay simultanés par utilisateur
  // (évite qu'un client spamme l'initiation et épuise le budget d'appels
  // de notre compte marchand Kpay).
  const { count: pendingCount } = await userClient
    .from("transactions")
    .select("id", { count: "exact", head: true })
    .eq("buyer_id", user.user.id)
    .eq("payment_method", "airtel_money")
    .eq("status", "pending");
  if ((pendingCount ?? 0) > 5) {
    return new Response(
      JSON.stringify({ success: false, message: "Trop de paiements en attente, réessayez plus tard" }),
      { status: 429, headers: corsHeaders },
    );
  }

  const amount = Number(txn.gross_amount) + Number(txn.visible_fee) + Number(txn.delivery_fee ?? 0);

  try {
    const kpayResponse = await fetch(`${KPAY_BASE_URL}/payments/init`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": KPAY_API_KEY,
        "X-Secret-Key": KPAY_SECRET_KEY,
      },
      body: JSON.stringify({
        amount,
        provider: GABON_PROVIDER,
        phoneNumber,
        externalId: transactionId,
        description: `MyGabon - transaction ${transactionId}`,
      }),
    });

    const kpayData = await kpayResponse.json();

    if (!kpayResponse.ok) {
      return new Response(
        JSON.stringify({ success: false, message: kpayData?.message ?? "Erreur Kpay" }),
        { status: 502, headers: corsHeaders },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        paymentId: kpayData.id,
        status: kpayData.status,
        reference: kpayData.reference,
      }),
      { status: 200, headers: corsHeaders },
    );
  } catch (e) {
    console.error("kpay-initiate: erreur appel Kpay", e);
    return new Response(JSON.stringify({ success: false, message: "Erreur connexion Kpay" }), {
      status: 502,
      headers: corsHeaders,
    });
  }
});
