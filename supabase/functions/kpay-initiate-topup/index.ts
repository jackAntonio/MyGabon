// Edge Function : initie une recharge du MyGabon Wallet via Airtel Money
// (Kpay) — même principe de sécurité que kpay-initiate (cf. son
// commentaire) : les credentials Kpay ne quittent jamais le serveur, le
// client appelle cette fonction avec son JWT Supabase.
//
// Différence avec kpay-initiate : cible `wallet_topups` (recharge de son
// propre wallet) au lieu de `transactions` (achat d'un produit à un
// vendeur) — cf. migration 20260629_wallet_topup.sql pour pourquoi ces
// deux flux ne partagent pas la même table.
//
// Déploiement :
//   supabase functions deploy kpay-initiate-topup
//   (réutilise les mêmes secrets que kpay-initiate : KPAY_API_KEY, KPAY_SECRET_KEY)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const KPAY_API_KEY = Deno.env.get("KPAY_API_KEY") ?? "";
const KPAY_SECRET_KEY = Deno.env.get("KPAY_SECRET_KEY") ?? "";
const KPAY_BASE_URL = "https://admin.kpay.site/api/v1";

const GABON_PROVIDER = "AIRTEL_GAB";

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

  let body: { topupId?: string; phoneNumber?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ success: false, message: "JSON invalide" }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  const { topupId, phoneNumber } = body;
  if (!topupId || !phoneNumber) {
    return new Response(
      JSON.stringify({ success: false, message: "topupId et phoneNumber requis" }),
      { status: 400, headers: corsHeaders },
    );
  }

  // Client "au nom de l'utilisateur" : la RLS limite le SELECT à ses propres recharges.
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

  const { data: topup, error: topupError } = await userClient
    .from("wallet_topups")
    .select("id, user_id, amount, status, payment_method")
    .eq("id", topupId)
    .single();

  if (topupError || !topup) {
    return new Response(JSON.stringify({ success: false, message: "Recharge introuvable" }), {
      status: 404,
      headers: corsHeaders,
    });
  }
  if (topup.user_id !== user.user.id) {
    return new Response(
      JSON.stringify({ success: false, message: "Cette recharge ne vous appartient pas" }),
      { status: 403, headers: corsHeaders },
    );
  }
  if (topup.status !== "pending") {
    return new Response(JSON.stringify({ success: false, message: "Recharge déjà traitée" }), {
      status: 409,
      headers: corsHeaders,
    });
  }
  if (topup.payment_method !== "airtel_money") {
    return new Response(
      JSON.stringify({ success: false, message: "Méthode de paiement non gérée par cette fonction" }),
      { status: 400, headers: corsHeaders },
    );
  }

  // Anti-abus : limite le nombre de recharges simultanées par utilisateur.
  const { count: pendingCount } = await userClient
    .from("wallet_topups")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.user.id)
    .eq("status", "pending");
  if ((pendingCount ?? 0) > 5) {
    return new Response(
      JSON.stringify({ success: false, message: "Trop de recharges en attente, réessayez plus tard" }),
      { status: 429, headers: corsHeaders },
    );
  }

  try {
    const kpayResponse = await fetch(`${KPAY_BASE_URL}/payments/init`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": KPAY_API_KEY,
        "X-Secret-Key": KPAY_SECRET_KEY,
      },
      body: JSON.stringify({
        amount: Number(topup.amount),
        provider: GABON_PROVIDER,
        phoneNumber,
        externalId: topupId,
        description: `MyGabon - recharge wallet ${topupId}`,
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
    console.error("kpay-initiate-topup: erreur appel Kpay", e);
    return new Response(JSON.stringify({ success: false, message: "Erreur connexion Kpay" }), {
      status: 502,
      headers: corsHeaders,
    });
  }
});
