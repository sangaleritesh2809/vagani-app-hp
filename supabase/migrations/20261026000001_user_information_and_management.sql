-- ==============================================================================
-- VARGANI COLLECTION APP - USER INFORMATION FORM & MANAGEMENT EXTENSION
-- Migration: 20261026000001_user_information_and_management.sql
-- ==============================================================================

-- 1. ADD ADDRESS, NOTES, AND CREATED_BY TO PROFILES & USERS TABLES
ALTER TABLE IF EXISTS public.profiles 
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_created_by ON public.profiles(created_by);

-- Also add columns to fallback users table if it exists
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
        ALTER TABLE public.users 
            ADD COLUMN IF NOT EXISTS address TEXT,
            ADD COLUMN IF NOT EXISTS notes TEXT,
            ADD COLUMN IF NOT EXISTS created_by UUID;
    END IF;
END $$;

-- 2. UNIQUE CONSTRAINT FOR MOBILE NUMBER ON PROFILES
-- Prevents duplicate mobile numbers in the database
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_profiles_phone'
    ) THEN
        -- Only enforce unique on non-empty phones
        CREATE UNIQUE INDEX IF NOT EXISTS uq_profiles_phone ON public.profiles(phone) WHERE phone IS NOT NULL AND phone != '';
    END IF;
END $$;

-- 3. SECURE STORED FUNCTION: CREATE OR ASSIGN USER WITH ROLE BY ADMIN
CREATE OR REPLACE FUNCTION public.create_user_by_admin_secure(
    p_full_name TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_organization_id UUID DEFAULT NULL,
    p_group_id UUID DEFAULT NULL,
    p_role_id UUID DEFAULT NULL,
    p_account_status TEXT DEFAULT 'active',
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_actor_id UUID;
    v_is_super_admin BOOLEAN := FALSE;
    v_is_org_admin BOOLEAN := FALSE;
    v_target_role_key TEXT;
    v_target_user_id UUID;
    v_clean_phone TEXT;
BEGIN
    -- 1. Resolve calling actor
    v_actor_id := auth.uid();
    
    -- In development/testing bypass or check actor permissions
    IF v_actor_id IS NOT NULL THEN
        -- Check if actor is super admin
        SELECT EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = v_actor_id AND r.role_key = 'SUPER_ADMIN'
        ) INTO v_is_super_admin;

        -- Check if actor is org admin for the specified organization
        SELECT EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = v_actor_id 
              AND ur.organization_id = p_organization_id 
              AND r.role_key IN ('SUPER_ADMIN', 'ORG_ADMIN')
        ) INTO v_is_org_admin;

        IF NOT v_is_super_admin AND NOT v_is_org_admin THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', 'अनधिकृत: युजर तयार करण्याची परवानगी नाही (Unauthorized).'
            );
        END IF;
    END IF;

    -- 2. Validate Target Role (Prevent privilege escalation)
    SELECT role_key INTO v_target_role_key FROM public.roles WHERE id = p_role_id;
    IF v_target_role_key = 'SUPER_ADMIN' AND NOT v_is_super_admin THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'सामान्य Admin ला Super Admin रोल नियुक्त करण्याची परवानगी नाही.'
        );
    END IF;

    -- 3. Sanitize and validate Indian Phone (10 digits)
    v_clean_phone := regexp_replace(p_phone, '\D', '', 'g');
    IF length(v_clean_phone) > 10 THEN
        v_clean_phone := substring(v_clean_phone from length(v_clean_phone) - 9);
    END IF;

    IF length(v_clean_phone) != 10 OR v_clean_phone !~ '^[6-9]\d{9}$' THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'कृपया वैध 10-अंकी भारतीय मोबाईल नंबर प्रविष्ट करा.'
        );
    END IF;

    -- 4. Check Duplicate Mobile
    IF EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE regexp_replace(phone, '\D', '', 'g') = v_clean_phone
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'या मोबाईल नंबरवर आधीपासून युजर अस्तित्वात आहे (Duplicate Mobile Number).'
        );
    END IF;

    -- 5. Generate Target User ID (UUID)
    v_target_user_id := gen_random_uuid();

    -- 6. Insert Profile
    INSERT INTO public.profiles (
        id,
        full_name,
        phone,
        email,
        address,
        notes,
        account_status,
        created_by,
        created_at,
        updated_at
    ) VALUES (
        v_target_user_id,
        trim(p_full_name),
        v_clean_phone,
        trim(p_email),
        p_address,
        p_notes,
        COALESCE(p_account_status, 'active'),
        v_actor_id,
        NOW(),
        NOW()
    );

    -- 7. Assign Organization Membership
    IF p_organization_id IS NOT NULL THEN
        INSERT INTO public.organization_members (
            organization_id,
            user_id,
            membership_status,
            created_at
        ) VALUES (
            p_organization_id,
            v_target_user_id,
            COALESCE(p_account_status, 'active'),
            NOW()
        ) ON CONFLICT DO NOTHING;
    END IF;

    -- 8. Assign Group Membership
    IF p_group_id IS NOT NULL THEN
        INSERT INTO public.group_members (
            group_id,
            user_id,
            membership_status,
            created_at
        ) VALUES (
            p_group_id,
            v_target_user_id,
            COALESCE(p_account_status, 'active'),
            NOW()
        ) ON CONFLICT DO NOTHING;
    END IF;

    -- 9. Assign Role in user_roles
    IF p_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (
            user_id,
            role_id,
            organization_id,
            group_id,
            assigned_by,
            created_at
        ) VALUES (
            v_target_user_id,
            p_role_id,
            p_organization_id,
            p_group_id,
            v_actor_id,
            NOW()
        );
    END IF;

    -- 10. Audit Log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        resource_type,
        resource_id,
        organization_id,
        group_id,
        metadata
    ) VALUES (
        v_actor_id,
        'CREATE_USER',
        'Profile',
        v_target_user_id::text,
        p_organization_id,
        p_group_id,
        jsonb_build_object(
            'full_name', p_full_name,
            'phone', v_clean_phone,
            'role_id', p_role_id,
            'account_status', p_account_status
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_target_user_id,
        'message', 'नवीन युजर यशस्वीरित्या तयार केला गेला.'
    );
END;
$$;

-- 4. FINANCIAL HISTORY PRESERVATION TRIGGER
-- Protects users with financial transactions from hard deletion
CREATE OR REPLACE FUNCTION public.check_user_financial_records_before_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if collector has receipts or collections
    IF EXISTS (SELECT 1 FROM public.receipts WHERE collector_id = OLD.id) OR
       EXISTS (SELECT 1 FROM public.collections WHERE collector_id = OLD.id) OR
       EXISTS (SELECT 1 FROM public.cash_handovers WHERE handover_from_id = OLD.id OR handover_to_id = OLD.id) THEN
        RAISE EXCEPTION 'या युजरशी संबंधित आर्थिक नोंदी (Receipts/Payments/Handovers) आहेत. आर्थिक इतिहास कायमस्वरूपी नष्ट करता येत नाही. कृपया खाते फक्त निष्क्रिय (Inactive) करा.';
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_financial_user_delete ON public.profiles;
CREATE TRIGGER trg_protect_financial_user_delete
    BEFORE DELETE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.check_user_financial_records_before_delete();

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own profile or profiles within their organization
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT
    USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id IN (
                SELECT id FROM public.roles WHERE role_key IN ('SUPER_ADMIN', 'ORG_ADMIN', 'GROUP_ADMIN', 'TREASURER')
            )
        )
    );

-- Allow authorized admins to update user profiles (including status, address, notes)
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE
    USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id IN (
                SELECT id FROM public.roles WHERE role_key IN ('SUPER_ADMIN', 'ORG_ADMIN')
            )
        )
    );
