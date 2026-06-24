// Edge Function : reçoit les notifications serveur-à-serveur de Kpay
// (paiement Airtel Money Gabon confirmé ou échoué) et c'est ELLE qui
// décide si la transaction passe à "success" — jamais le client mobile.
//
// Pourquoi : un paiement ne doit jamais être validé sur la seule
// parole de l'app Flutter (un appareil rooté/jailbreaké ou un proxy
// MITM pourrait fabriquer une fausse réponse "succès" de Kpay). La
// seule source de vérité est ce webhook serveur-à-serveur, authentifié
// par signature HMAC — c'est explicitement ce que dit la doc Kpay :
// "The webhook remains the authority" pour le statut final.
//
// Format confirmé par https://kpay.site/documentation/webhooks :
// - Header de signature : X-KPAY-Signature
// - HMAC-SHA256 (hex) calculé sur le corps brut JSON reçu (pas re-sérialisé)
// - Payload :
//   {
//     "event": "payment.completed",
//     "paymentId": "pay_abc123",
//     "reference": "KPAY-DEP-12345",   // référence interne Kpay
//     "status": "COMPLETED",            // COMPLETED | FAILED | CANCELLED
//     "amount": 5000,
//     "phoneNumber": "...",
//     "externalId": "ORDER-12345",      // = notre transactions.id (cf. kpay-initiate)
//     "metadata": {...},
//     "completedAt": "...", "failedAt": null, "failureReason": null,
//     "timestamp": "..."
//   }
//   -> on retrouve la transaction Supabase par `externalId`, jamais par
//      `reference` (qui est la référence Kpay, pas la nôtre).
//
// Déploiement :
//   supabase functions deploy kpay-webhook
//   supabase secrets set KPAY_WEBHOOK_SECRET=xxxx
// URL à configurer dans le dashboard Kpay (Settings → Webhooks →
// Callback URL) :
//   https://<project-ref>.supabase.co/functions/v1/kpay-webhook

import { createClient } from "jsr:@supabase/supabase-js@2";

const KPAY_SIGNATURE_HEADER = "x-kpay-signature";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const KPAY_WEBHOOK_SECRET = Deno.env.get("KPAY_WEBHOOK_SECRET") ?? "";

async function verifySignature(rawBody: string, signatureHex: string): Promise<boolean> {
  if (!KPAY_WEBHOOK_SECRET || !signatureHex) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(KPAY_WEBHOOK_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );

  const signatureBytes = hexToBytes(signatureHex);
  if (!signatureBytes) return false;

  return crypto.subtle.verify(
    "HMAC",
    key,
    signatureBytes,
    new TextEncoder().encode(rawBody),
  );
}

function hexToBytes(hex: string): Uint8Array | null {
  const clean = hex.trim().toLowerCase();
  if (!/^[0-9a-f]+$/.test(clean) || clean.length % 2 !== 0) return null;
  const bytes = new Uint8Array(clean.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(clean.substr(i * 2, 2), 16);
  }
  return bytes;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const rawBody = await req.text();
  const signature = req.headers.get(KPAY_SIGNATURE_HEADER) ?? "";

  const isValid = await verifySignature(rawBody, signature);
  if (!isValid) {
    console.error("kpay-webhook: signature invalide ou manquante");
    return new Response("Invalid signature", { status: 401 });
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  // externalId = notre transactions.id, fixé à l'initiation (kpay-initiate).
  // reference/paymentId sont des identifiants internes Kpay, pas les nôtres.
  const transactionId = String(payload.externalId ?? "");
  const status = String(payload.status ?? "").toUpperCase();

  if (!transactionId) {
    return new Response("Missing externalId", { status: 400 });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  try {
    if (status === "COMPLETED") {
      const { error } = await supabase.rpc("confirm_external_payment", {
        p_transaction_id: transactionId,
        p_provider_reference: String(payload.paymentId ?? payload.reference ?? transactionId),
      });
      if (error) throw error;
    } else if (status === "FAILED" || status === "CANCELLED") {
      const { error } = await supabase.rpc("fail_external_payment", {
        p_transaction_id: transactionId,
        p_reason: String(payload.failureReason ?? `Kpay status: ${status}`),
      });
      if (error) throw error;
    } else {
      // PENDING / PROCESSING / inconnu : rien à faire, on attend la
      // prochaine notification.
    }
  } catch (e) {
    console.error("kpay-webhook: erreur RPC", e);
    // 200 quand même : éviter que Kpay retente indéfiniment sur une
    // transaction déjà traitée ou introuvable (cas attendu, pas une
    // erreur de notre côté).
  }

  return new Response("OK", { status: 200 });
});
