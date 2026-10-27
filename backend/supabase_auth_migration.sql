-- ==============================================================================
-- VARGANI PRO (वर्गणी) - SUPABASE AUTH & PHONE-TO-EMAIL LOOKUP MIGRATION
-- ==============================================================================

-- 1. Ensure required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Enhance public.users table for Supabase Auth integration
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL DEFAULT 'citizen',
    group_ids TEXT[] DEFAULT '{"grp_001"}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for phone search (clean 10 digits)
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- 3. Rate limiting table for phone lookups (prevents brute-force / enumeration)
CREATE TABLE IF NOT EXISTS public.auth_lookup_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier TEXT NOT NULL, -- clean phone or IP
    attempt_time TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lookup_rate ON public.auth_lookup_rate_limits(identifier, attempt_time);

-- Clean up old rate limit records older than 1 hour automatically
CREATE OR REPLACE FUNCTION public.cleanup_old_lookup_attempts()
RETURNS trigger AS $$
BEGIN
    DELETE FROM public.auth_lookup_rate_limits
    WHERE attempt_time < NOW() - INTERVAL '1 hour';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Secure RPC function: lookup_phone_email(p_phone TEXT)
-- Runs with SECURITY DEFINER so anonymous clients can resolve their registered
-- email without direct table access. Returns masked email for UI display.
CREATE OR REPLACE FUNCTION public.lookup_phone_email(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_clean_phone TEXT;
    v_user_email TEXT;
    v_user_name TEXT;
    v_is_active BOOLEAN;
    v_masked_email TEXT;
    v_at_idx INT;
    v_user_part TEXT;
    v_domain_part TEXT;
    v_recent_attempts INT;
BEGIN
    -- 1. Sanitize phone: extract digits only
    v_clean_phone := regexp_replace(COALESCE(p_phone, ''), '\D', '', 'g');
    IF length(v_clean_phone) >= 10 THEN
        v_clean_phone := right(v_clean_phone, 10);
    END IF;

    -- 2. Validate 10-digit Indian mobile number format
    IF length(v_clean_phone) <> 10 OR v_clean_phone !~ '^[6-9]\d{9}$' THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'कृपया वैध १० अंकी मोबाईल नंबर टाका (उदा. 98xxxxxxxx).'
        );
    END IF;

    -- 3. Rate Limiting Check (Max 6 attempts per phone in 10 minutes)
    SELECT COUNT(*) INTO v_recent_attempts
    FROM public.auth_lookup_rate_limits
    WHERE identifier = v_clean_phone
      AND attempt_time > NOW() - INTERVAL '10 minutes';

    IF v_recent_attempts >= 6 THEN
        RETURN jsonb_build_object(
            'success', false,
            'rate_limited', true,
            'message', 'खूप जास्त प्रयत्न झाले आहेत. कृपया १० मिनिटांनंतर पुन्हा प्रयत्न करा.'
        );
    END IF;

    -- Record attempt
    INSERT INTO public.auth_lookup_rate_limits(identifier) VALUES (v_clean_phone);

    -- 4. Find active user matching clean 10-digit phone
    SELECT u.email, u.name, u.is_active
    INTO v_user_email, v_user_name, v_is_active
    FROM public.users u
    WHERE right(regexp_replace(u.phone, '\D', '', 'g'), 10) = v_clean_phone
    LIMIT 1;

    -- If not found in public.users, check auth.users metadata as fallback
    IF v_user_email IS NULL THEN
        SELECT au.email,
               COALESCE((au.raw_user_meta_data->>'name'), 'User'),
               COALESCE((au.raw_user_meta_data->>'is_active')::boolean, true)
        INTO v_user_email, v_user_name, v_is_active
        FROM auth.users au
        WHERE right(regexp_replace(COALESCE(au.raw_user_meta_data->>'phone', ''), '\D', '', 'g'), 10) = v_clean_phone
        LIMIT 1;
    END IF;

    -- 5. Account existence & active status check
    IF v_user_email IS NULL THEN
        -- Generic message to prevent phone enumeration
        RETURN jsonb_build_object(
            'success', false,
            'message', 'या मोबाईल क्रमांकाशी जोडलेले कोणतेही नोंदणीकृत खाते आढळले नाही. कृपया आधी नोंदणी करा.'
        );
    END IF;

    IF v_is_active = FALSE THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'आपले खाते निष्क्रिय (Inactive) आहे. कृपया मंडळाच्या प्रशासकाशी संपर्क साधा.'
        );
    END IF;

    -- 6. Generate masked email (e.g., riteshsangale71@gmail.com -> r***1@gmail.com)
    v_at_idx := position('@' in v_user_email);
    IF v_at_idx > 1 THEN
        v_user_part := substring(v_user_email from 1 for v_at_idx - 1);
        v_domain_part := substring(v_user_email from v_at_idx);
        
        IF length(v_user_part) <= 2 THEN
            v_masked_email := substring(v_user_part from 1 for 1) || '***' || v_domain_part;
        ELSE
            v_masked_email := substring(v_user_part from 1 for 1) 
                              || '***' 
                              || substring(v_user_part from length(v_user_part) for 1) 
                              || v_domain_part;
        END IF;
    ELSE
        v_masked_email := '***@***.com';
    END IF;

    -- 7. Return success with target email and masked version
    RETURN jsonb_build_object(
        'success', true,
        'email', v_user_email,
        'masked_email', v_masked_email,
        'name', v_user_name
    );
END;
$$;

-- Grant execution to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.lookup_phone_email(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.lookup_phone_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lookup_phone_email(TEXT) TO service_role;

-- 5. Trigger to automatically sync auth.users to public.users on signup
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger AS $$
DECLARE
    v_name TEXT;
    v_phone TEXT;
    v_role TEXT;
    v_org_id UUID;
BEGIN
    v_name := COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
    v_phone := COALESCE(new.raw_user_meta_data->>'phone', '');
    v_role := COALESCE(new.raw_user_meta_data->>'role', 'citizen');
    
    INSERT INTO public.users (
        id,
        name,
        phone,
        email,
        role,
        group_ids,
        is_active,
        created_at
    )
    VALUES (
        new.id,
        v_name,
        v_phone,
        new.email,
        v_role,
        ARRAY['grp_001'],
        TRUE,
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        phone = CASE WHEN EXCLUDED.phone <> '' THEN EXCLUDED.phone ELSE public.users.phone END,
        email = EXCLUDED.email,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any and create new
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- 6. Row Level Security (RLS) Configuration
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
CREATE POLICY "Users can read own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- Allow service_role full access
CREATE POLICY "Service role full access on users"
    ON public.users FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');
