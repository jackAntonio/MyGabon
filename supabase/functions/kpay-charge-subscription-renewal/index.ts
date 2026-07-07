// Edge Function : débite via Kpay (Airtel Money) un abonnement Pro/
// Entreprise arrivé à échéance. Appelée UNIQUEMENT par
// process_subscription_renewals() (pg_cron + pg_net, cf. migration
// 20260707_subscription_renewals.sql) — jamais par le client Flutter,
// contrairement à kpay-initiate/kpay-initiate-topup qui valident un JWT
// utilisateur. Ici l'appelant est le job système lui-même : on exige
// directement le service_role key en Authorization, pas de session
// utilisateur (il n'y en a pas, personne n'est connecté à 3h du matin
// pour déclencher son propre renouvellement).
//
// Comme kpay-initiate/kpay-initiate-topup : initie seulement le
// prélèvement (déclenche le prompt USSD côté opérateur). Le statut
// final (COMPLETED/FAILED) n'arrive que via kpay-webhook, qui appelle
// alors confirm_subscription_renewal / fail_subscription_renewal.
//
// Déploiement :
//   supabase functions deploy kpay-charge-subscription-renewal
//   (réutilise KPAY_API_KEY/KPAY_SECRET_KEY déjà configurés pour
//   kpay-initiate/kpay-initiate-topup — rien de nouveau côté secrets Kpay)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const KPAY_API_KEY = Deno.env.get("KPAY_API_KEY") ?? "";
const KPAY_SECRET_KEY = Deno.env.get("KPAY_SECRET_KEY") ?? "";
const KPAY_BASE_URL = "https://admin.kpay.site/api/v1";

const GABON_PROVIDER = "AIRTEL_GAB";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Pas de CORS ici : cette fonction n'est jamais appelée depuis un
  // navigateur/l'app Flutter, seulement server-to-server par pg_net.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (authHeader !== `Bearer ${SERVICE_ROLE_KEY}`) {
    console.error("kpay-charge-subscription-renewal: appel non autorisé (service_role attendu)");
    return new Response("Unauthorized", { status: 401 });
  }

  if (!KPAY_API_KEY || !KPAY_SECRET_KEY) {
    return new Response(
      JSON.stringify({ success: false, message: "Kpay non configuré côté serveur" }),
      { status: 503 },
    );
  }

  let body: { renewalId?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("JSON invalide", { status: 400 });
  }

  const { renewalId } = body;
  if (!renewalId) {
    return new Response("renewalId requis", { status: 400 });
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const { data: renewal, error: renewalError } = await admin
    .from("subscription_renewals")
    .select("id, amount, phone_number, status")
    .eq("id", renewalId)
    .single();

  if (renewalError || !renewal) {
    return new Response("Renouvellement introuvable", { status: 404 });
  }
  if (renewal.status !== "pending") {
    return new Response("OK", { status: 200 }); // déjà traité
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
        amount: Number(renewal.amount),
        provider: GABON_PROVIDER,
        phoneNumber: renewal.phone_number,
        externalId: renewalId,
        description: `MyGabon - renouvellement abonnement ${renewalId}`,
      }),
    });

    const kpayData = await kpayResponse.json();

    if (!kpayResponse.ok) {
      // Rejet immédiat par Kpay (ex: numéro invalide) : aucun webhook ne
      // viendra jamais pour ce paiement, on échoue tout de suite.
      await admin.rpc("fail_subscription_renewal", {
        p_renewal_id: renewalId,
        p_reason: kpayData?.message ?? "Erreur Kpay",
      });
      return new Response(JSON.stringify({ success: false, message: kpayData?.message ?? "Erreur Kpay" }), {
        status: 502,
      });
    }

    return new Response(
      JSON.stringify({ success: true, paymentId: kpayData.id, status: kpayData.status }),
      { status: 200 },
    );
  } catch (e) {
    console.error("kpay-charge-subscription-renewal: erreur appel Kpay", e);
    await admin.rpc("fail_subscription_renewal", {
      p_renewal_id: renewalId,
      p_reason: "Erreur connexion Kpay",
    });
    return new Response(JSON.stringify({ success: false, message: "Erreur connexion Kpay" }), {
      status: 502,
    });
  }
});
