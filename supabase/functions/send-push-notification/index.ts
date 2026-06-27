// Edge Function : envoie une notification push (OneSignal) au destinataire
// d'un message de chat — cf. SUPABASE_VS_FIREBASE_DECISION.md (le projet a
// écarté Firebase, OneSignal sert de relais push sans réintroduire son SDK
// dans l'app Flutter).
//
// Le titre/corps de la notification sont reconstruits ici à partir du
// message réel (sender_id, content) plutôt qu'acceptés depuis le client :
// un appelant ne peut donc déclencher une notification que pour un message
// qu'il a réellement envoyé (vérifié via sender_id = appelant authentifié),
// jamais forger un titre/corps arbitraire au nom de quelqu'un d'autre
// (même principe que send-otp-sms : le secret OneSignal ne doit jamais
// être compilé dans l'app Flutter).
//
// Ciblage : OneSignal "external_id" = users.id (cf. NotificationService.login
// côté Flutter), donc pas besoin de table de device tokens ici.
//
// Sans ONESIGNAL_APP_ID/ONESIGNAL_REST_API_KEY configurés : no-op silencieux
// (succès renvoyé avec pushSent: false), pour ne pas bloquer l'envoi du
// message si le push n'est pas encore configuré.
//
// Déploiement :
//   supabase functions deploy send-push-notification
//   supabase secrets set ONESIGNAL_APP_ID=xxx ONESIGNAL_REST_API_KEY=xxx
//   supabase secrets set ALLOWED_ORIGINS=https://app.mygabon.ga  (optionnel, cf. kpay-initiate)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";

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

async function sendViaOneSignal(
  externalUserId: string,
  heading: string,
  content: string,
): Promise<{ sent: boolean; reason?: string }> {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.log(`[send-push-notification] OneSignal non configuré (dev only) — notif pour ${externalUserId}: ${heading} / ${content}`);
    return { sent: false, reason: "OneSignal non configuré côté serveur" };
  }

  try {
    const res = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [externalUserId],
        headings: { en: heading },
        contents: { en: content },
        data: { type: "chat_message" },
      }),
    });

    if (!res.ok) {
      console.error("[send-push-notification] Erreur OneSignal", res.status, await res.text());
      return { sent: false, reason: "Erreur envoi OneSignal" };
    }
    return { sent: true };
  } catch (e) {
    console.error("[send-push-notification] Erreur connexion OneSignal", e);
    return { sent: false, reason: "Erreur connexion OneSignal" };
  }
}

Deno.serve(async (req) => {
  const corsHeaders = corsHeadersFor(req.headers.get("origin"));
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ success: false, message: "Non authentifié" }), {
      status: 401,
      headers: corsHeaders,
    });
  }

  let body: { message_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ success: false, message: "JSON invalide" }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  const { message_id } = body;
  if (!message_id) {
    return new Response(JSON.stringify({ success: false, message: "message_id requis" }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData?.user) {
    return new Response(JSON.stringify({ success: false, message: "Session invalide" }), {
      status: 401,
      headers: corsHeaders,
    });
  }
  const callerId = userData.user.id;

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // Le message doit exister et avoir été envoyé par l'appelant : empêche de
  // déclencher une notification pour un message qui n'est pas le sien.
  const { data: message, error: messageError } = await admin
    .from("messages")
    .select("receiver_id, content")
    .eq("id", message_id)
    .eq("sender_id", callerId)
    .single();

  if (messageError || !message) {
    return new Response(JSON.stringify({ success: false, message: "Message introuvable" }), {
      status: 404,
      headers: corsHeaders,
    });
  }

  const { data: sender } = await admin
    .from("users")
    .select("full_name")
    .eq("id", callerId)
    .single();
  const senderName = (sender?.full_name as string | undefined) || "Quelqu'un";

  const result = await sendViaOneSignal(message.receiver_id as string, senderName, message.content as string);

  return new Response(
    JSON.stringify({ success: true, pushSent: result.sent, message: result.sent ? undefined : result.reason }),
    { status: 200, headers: corsHeaders },
  );
});
