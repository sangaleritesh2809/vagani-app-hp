-- ==============================================================================
-- VARGANI COLLECTION APP - SECURE SUPER ADMIN BOOTSTRAP MIGRATION
-- Migration: 20261024000002_super_admin_bootstrap.sql
-- ==============================================================================

-- Function to check if a Super Admin already exists (callable by clients for initial setup status)
CREATE OR REPLACE FUNCTION public.check_super_admin_initialized()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE r.role_key = 'SUPER_ADMIN'
    );
END;
$$;

-- Secure, idempotent one-time bootstrap function
-- Enforces:
-- 1. If any SUPER_ADMIN already exists in public.user_roles, IMMEDIATELY FAILS.
-- 2. Requires service role execution OR initial uninitialized state check.
-- 3. Associates designated user profile and grants SUPER_ADMIN system role.
-- 4. Records action in immutable public.audit_logs.
-- 5. Disables future initialization calls permanently.
CREATE OR REPLACE FUNCTION public.bootstrap_first_super_admin(
    p_email TEXT,
    p_phone TEXT,
    p_full_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_already_initialized BOOLEAN;
    v_user_id UUID;
    v_role_id UUID;
    v_clean_phone TEXT;
    v_clean_email TEXT;
BEGIN
    -- 1. Check idempotency: Has a Super Admin already been configured?
    SELECT public.check_super_admin_initialized() INTO v_already_initialized;
    IF v_already_initialized THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_code', 'ALREADY_BOOTSTRAPPED',
            'message', 'Super Admin bootstrap has already been executed. Repeat initialization is strictly disabled.'
        );
    END IF;

    -- 2. Input sanitization
    v_clean_email := lower(trim(p_email));
    v_clean_phone := regexp_replace(COALESCE(p_phone, ''), '\D', '', 'g');
    IF length(v_clean_phone) >= 10 THEN
        v_clean_phone := right(v_clean_phone, 10);
    END IF;

    IF v_clean_email IS NULL OR v_clean_email = '' OR v_clean_email !~ '^[\w\.-]+@[\w\.-]+\.\w{2,}$' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_code', 'INVALID_EMAIL',
            'message', 'Please provide a valid email address for the initial Super Admin.'
        );
    END IF;

    -- 3. Retrieve or locate auth user
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE lower(email) = v_clean_email
    LIMIT 1;

    -- If the user does not exist in auth.users yet, use auth.uid() if called by an authenticated user
    IF v_user_id IS NULL THEN
        IF auth.uid() IS NOT NULL THEN
            v_user_id := auth.uid();
        ELSE
            RETURN jsonb_build_object(
                'success', FALSE,
                'error_code', 'USER_NOT_FOUND',
                'message', 'Auth user not found. Please sign up or request an OTP for this email in Supabase first.'
            );
        END IF;
    END IF;

    -- 4. Locate SUPER_ADMIN role ID
    SELECT id INTO v_role_id 
    FROM public.roles 
    WHERE role_key = 'SUPER_ADMIN';

    IF v_role_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_code', 'ROLE_NOT_CONFIGURED',
            'message', 'SUPER_ADMIN system role is missing from roles table.'
        );
    END IF;

    -- 5. Upsert profile with active status
    INSERT INTO public.profiles (id, full_name, email, phone, account_status)
    VALUES (v_user_id, COALESCE(p_full_name, 'System Super Administrator'), v_clean_email, v_clean_phone, 'active')
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        account_status = 'active',
        updated_at = NOW();

    -- 6. Assign SUPER_ADMIN role (system scope)
    INSERT INTO public.user_roles (user_id, role_id, organization_id, group_id, assigned_by)
    VALUES (v_user_id, v_role_id, NULL, NULL, v_user_id)
    ON CONFLICT DO NOTHING;

    -- 7. Record immutable audit log
    INSERT INTO public.audit_logs (
        actor_user_id,
        action,
        resource_type,
        resource_id,
        safe_metadata
    ) VALUES (
        v_user_id,
        'system.super_admin_bootstrapped',
        'user_roles',
        v_role_id::text,
        jsonb_build_object(
            'email', v_clean_email,
            'phone', v_clean_phone,
            'full_name', p_full_name,
            'timestamp', NOW()
        )
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_user_id,
        'role', 'SUPER_ADMIN',
        'message', 'Initial Super Admin successfully bootstrapped and system locked.'
    );
END;
$$;
