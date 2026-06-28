// Edge Function : génère un OTP téléphone et l'envoie réellement par SMS
// (Twilio) — remplace l'ancien RPC SQL request_phone_otp qui générait et
// hachait le code mais ne l'envoyait jamais (RAISE NOTICE uniquement, cf.
// migration 20260624_security_hardening.sql) : Twilio exige un appel HTTP
// sortant avec un Auth Token, qui ne doit jamais être compilé dans l'app
// Flutter (extractible d'un APK/IPA, même règle que pour Kpay — cf.
// kpay-initiate/index.ts) ni stocké en clair dans une migration Postgres.
// Donc génération + hachage + envoi SMS regroupés ici, où le secret reste
// côté serveur (`supabase secrets set`).
//
// confirm_phone_otp (SQL, inchangé) reste l'unique point de vérification :
// cette fonction se contente d'insérer une ligne dans phone_otp_codes avec
// le même schéma de hachage (sha256(code + user.id)), donc compatible.
//
// Sans TWILIO_ACCOUNT_SID/TWILIO_AUTH_TOKEN/TWILIO_PHONE_NUMBER configurés :
// le code est seulement loggé côté serveur (jamais renvoyé au client), pour
// ne pas bloquer le développement avant l'ajout des vrais identifiants.
//
// Déploiement :
//   supabase functions deploy send-otp-sms
//   supabase secrets set TWILIO_ACCOUNT_SID=ACxxx TWILIO_AUTH_TOKEN=xxx TWILIO_PHONE_NUMBER=+1xxx
//   supabase secrets set ALLOWED_ORIGINS=https://app.mygabon.ga  (optionnel, cf. kpay-initiate)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
const TWILIO_PHONE_NUMBER = Deno.env.get("TWILIO_PHONE_NUMBER") ?? "";

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

function generateCode(): string {
  const bytes = new Uint8Array(4);
  crypto.getRandomValues(bytes);
  const n = new DataView(bytes.buffer).getUint32(0);
  return (n % 1000000).toString().padStart(6, "0");
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hashBuffer)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function sendViaTwilio(
  phoneNumber: string,
  code: string,
): Promise<{ sent: boolean; reason?: string }> {
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_PHONE_NUMBER) {
    // Twilio non configuré : le code ne doit jamais finir dans les logs
    // Supabase (persistants, lisibles par quiconque a accès au projet), même
    // en dev — cf. invariant "le client ne voit jamais le code" documenté
    // sur SupabaseService.sendOTP.
    console.log(`[send-otp-sms] Twilio non configuré — SMS non envoyé pour ${phoneNumber}`);
    return { sent: false, reason: "Twilio non configuré côté serveur" };
  }

  const auth = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);
  const body = new URLSearchParams({
    From: TWILIO_PHONE_NUMBER,
    To: phoneNumber,
    Body: `Votre code MyGabon est : ${code} (valable 5 minutes)`,
  });

  try {
    const res = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body,
      },
    );

    if (!res.ok) {
      console.error("[send-otp-sms] Erreur Twilio", res.status, await res.text());
      return { sent: false, reason: "Erreur envoi Twilio" };
    }
    return { sent: true };
  } catch (e) {
    console.error("[send-otp-sms] Erreur connexion Twilio", e);
    return { sent: false, reason: "Erreur connexion Twilio" };
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

  let body: { phoneNumber?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ success: false, message: "JSON invalide" }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  const { phoneNumber } = body;
  // Format Gabon (+241xxxxxxxx ou 0xxxxxxxx) — même règle que
  // PaymentService._isValidGabonPhoneNumber côté Flutter. Sans ce
  // contrôle, n'importe quel utilisateur authentifié pourrait faire
  // envoyer des SMS (coût Twilio) vers un numéro arbitraire de son choix ;
  // la rate-limit ci-dessous (3/15min/compte) borne déjà l'abus, ce
  // contrôle le réduit encore en rejetant les formats non gabonais.
  if (!phoneNumber || !/^(\+241|0)\d{7,8}$/.test(phoneNumber)) {
    return new Response(JSON.stringify({ success: false, message: "Numéro de téléphone invalide" }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  // Client "au nom de l'utilisateur" uniquement pour récupérer son identité
  // (la table phone_otp_codes n'a aucune policy pour authenticated : seul
  // un client service_role peut y écrire, cf. migration security_hardening).
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
  const userId = userData.user.id;

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // Rate limit : 3 demandes / 15 min (même règle que l'ancien request_phone_otp SQL)
  const fifteenMinAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();
  const { count } = await admin
    .from("phone_otp_codes")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", fifteenMinAgo);
  if ((count ?? 0) >= 3) {
    return new Response(JSON.stringify({ success: false, message: "Trop de demandes, réessayez plus tard" }), {
      status: 429,
      headers: corsHeaders,
    });
  }

  const code = generateCode();
  const codeHash = await sha256Hex(code + userId);

  const { error: insertError } = await admin.from("phone_otp_codes").insert({
    user_id: userId,
    phone_number: phoneNumber,
    code_hash: codeHash,
    expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
  });
  if (insertError) {
    console.error("[send-otp-sms] Erreur insertion", insertError);
    return new Response(JSON.stringify({ success: false, message: "Erreur serveur" }), {
      status: 500,
      headers: corsHeaders,
    });
  }

  const smsResult = await sendViaTwilio(phoneNumber, code);

  return new Response(
    JSON.stringify({
      success: true,
      smsSent: smsResult.sent,
      message: smsResult.sent ? undefined : smsResult.reason,
    }),
    { status: 200, headers: corsHeaders },
  );
});
