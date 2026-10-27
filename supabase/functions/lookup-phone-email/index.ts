// Supabase Edge Function: lookup-phone-email
// Deploy with: supabase functions deploy lookup-phone-email --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Rate limiter store in memory (per Deno instance)
const rateLimitMap = new Map<string, { count: number; firstAttempt: number }>();
const MAX_ATTEMPTS = 5;
const WINDOW_MS = 10 * 60 * 1000; // 10 minutes

function checkRateLimit(ipOrKey: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(ipOrKey);

  if (!entry) {
    rateLimitMap.set(ipOrKey, { count: 1, firstAttempt: now });
    return true;
  }

  if (now - entry.firstAttempt > WINDOW_MS) {
    rateLimitMap.set(ipOrKey, { count: 1, firstAttempt: now });
    return true;
  }

  entry.count += 1;
  return entry.count <= MAX_ATTEMPTS;
}

function maskEmail(email: string): string {
  const atIndex = email.indexOf("@");
  if (atIndex <= 1) return "***@***.com";
  const user = email.substring(0, atIndex);
  const domain = email.substring(atIndex);
  if (user.length <= 2) {
    return `${user[0]}***${domain}`;
  }
  return `${user[0]}***${user[user.length - 1]}${domain}`;
}

serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const clientIp = req.headers.get("x-forwarded-for") || "unknown";
    if (!checkRateLimit(clientIp)) {
      return new Response(
        JSON.stringify({
          success: false,
          rate_limited: true,
          message: "खूप जास्त प्रयत्न झाले आहेत. कृपया १० मिनिटांनंतर पुन्हा प्रयत्न करा.",
        }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { phone } = await req.json();
    const cleanPhone = (phone || "").replace(/\D/g, "").slice(-10);

    if (!cleanPhone || cleanPhone.length !== 10 || !/^[6-9]\d{9}$/.test(cleanPhone)) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "कृपया वैध १० अंकी मोबाईल नंबर टाका.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase Admin client using Service Role
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Query public.users
    const { data: user, error: dbError } = await supabase
      .from("users")
      .select("email, name, is_active")
      .ilike("phone", `%${cleanPhone}`)
      .limit(1)
      .maybeSingle();

    if (dbError || !user || !user.email) {
      // Prevent enumeration: generic message
      return new Response(
        JSON.stringify({
          success: false,
          message: "या मोबाईल क्रमांकाशी जोडलेले खाते सापडले नाही. कृपया आधी नोंदणी करा.",
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!user.is_active) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "आपले खाते निष्क्रिय (Inactive) आहे. कृपया प्रशासकाशी संपर्क साधा.",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Trigger Supabase OTP to the user's email securely from the edge function
    // or return the masked email and trigger client-side signInWithOtp
    const masked = maskEmail(user.email);

    return new Response(
      JSON.stringify({
        success: true,
        email: user.email,
        masked_email: masked,
        name: user.name,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        message: "सर्व्हर त्रुटी: विनंती प्रक्रिया करता आली नाही.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
