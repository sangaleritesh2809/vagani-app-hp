-- ==============================================================================
-- VARGANI PRO (वर्गणी) - COMPLETE SUPABASE POSTGRESQL SCHEMA (WITH SAFE ALTERS)
-- According to Software Requirements Specification (SRS v1.0) & RBAC Extensions
-- ==============================================================================
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/lqeohtminzfjhqclcnkm/sql/new
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. Organizations Table (SRS Section 4)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) NOT NULL UNIQUE,
    contact_person VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    village VARCHAR(100) NOT NULL,
    taluka VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    state VARCHAR(100) DEFAULT 'Maharashtra',
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe column additions if organizations table already existed
ALTER TABLE IF EXISTS public.organizations ADD COLUMN IF NOT EXISTS state VARCHAR(100) DEFAULT 'Maharashtra';
ALTER TABLE IF EXISTS public.organizations ADD COLUMN IF NOT EXISTS registration_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE IF EXISTS public.organizations ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Active';
ALTER TABLE IF EXISTS public.organizations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 1b. Groups / Mandals Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    location TEXT,
    status VARCHAR(50) DEFAULT 'Active',
    contribution_settings JSONB DEFAULT '{"suggested_amount": 500, "allow_partial": true, "per_person_rate": 200}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe column additions if groups table already existed (Fixes error 42703)
ALTER TABLE IF EXISTS public.groups ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE IF EXISTS public.groups ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Active';
ALTER TABLE IF EXISTS public.groups ADD COLUMN IF NOT EXISTS contribution_settings JSONB DEFAULT '{"suggested_amount": 500, "allow_partial": true, "per_person_rate": 200}'::jsonb;
ALTER TABLE IF EXISTS public.groups ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 1c. Permissions Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID DEFAULT uuid_generate_v4(),
    code VARCHAR(100) PRIMARY KEY,
    permission_key VARCHAR(100),
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT NOT NULL
);

ALTER TABLE IF EXISTS public.permissions ADD COLUMN IF NOT EXISTS id UUID DEFAULT uuid_generate_v4();
ALTER TABLE IF EXISTS public.permissions ADD COLUMN IF NOT EXISTS permission_key VARCHAR(100);

-- ==============================================================================
-- 1d. Roles Table (Dynamic RBAC)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL UNIQUE,
    role_key VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    scope_type VARCHAR(20) DEFAULT 'system',
    is_system BOOLEAN DEFAULT FALSE,
    is_system_role BOOLEAN DEFAULT FALSE,
    description TEXT,
    permissions TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS role_key VARCHAR(50);
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS scope_type VARCHAR(20) DEFAULT 'system';
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS is_system_role BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS permissions TEXT[] DEFAULT '{}';

-- ==============================================================================
-- 2. Users Table with Roles, Groups, Address, Notes and Active/Inactive Status
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'citizen',
    group_ids TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    address TEXT,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS group_id UUID;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS group_ids TEXT[] DEFAULT '{}';
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2b. Profiles Table (Linked to Supabase Auth & Users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    avatar_url TEXT,
    account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'inactive', 'suspended')),
    address TEXT,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS account_status VARCHAR(20) DEFAULT 'active';
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2c. User Roles junction table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    organization_id UUID,
    group_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure Foreign Keys for PostgREST resource embedding
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_user') THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_role') THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- 2d. Group Members table
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    membership_status VARCHAR(20) NOT NULL DEFAULT 'active',
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2e. Join Requests table
CREATE TABLE IF NOT EXISTS public.join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    request_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    user_notes TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 3. Campaigns Table (SRS Section 4 & 5)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    vargani_type VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    per_person_rate NUMERIC(10, 2) NOT NULL DEFAULT 100.0,
    suggested_amount NUMERIC(10, 2) DEFAULT 0.0,
    allow_partial_payment BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) DEFAULT 'Active',
    rate_effective_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.campaigns ADD COLUMN IF NOT EXISTS target_amount NUMERIC(12, 2) DEFAULT 0.0;
ALTER TABLE IF EXISTS public.campaigns ADD COLUMN IF NOT EXISTS per_person_rate NUMERIC(10, 2) DEFAULT 100.0;
ALTER TABLE IF EXISTS public.campaigns ADD COLUMN IF NOT EXISTS suggested_amount NUMERIC(10, 2) DEFAULT 0.0;
ALTER TABLE IF EXISTS public.campaigns ADD COLUMN IF NOT EXISTS allow_partial_payment BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.campaigns ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Active';

-- ==============================================================================
-- 4. Households Table (SRS Section 5.2 Option A)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.households (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL,
    organization_id UUID NOT NULL,
    head_of_family_name VARCHAR(255) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    village_area VARCHAR(255) NOT NULL,
    family_member_count INT NOT NULL DEFAULT 4,
    per_person_rate_snapshot NUMERIC(10, 2) NOT NULL DEFAULT 100.0,
    amount_received NUMERIC(12, 2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 5. Collections / Payments Table (SRS Section 6)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_no VARCHAR(50),
    receipt_number VARCHAR(100),
    organization_id UUID,
    group_id UUID,
    campaign_id UUID,
    household_id UUID,
    payer_name VARCHAR(255),
    payer_phone VARCHAR(20),
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    payment_type VARCHAR(50) NOT NULL DEFAULT 'cash',
    payment_mode VARCHAR(50) DEFAULT 'cash',
    reference_id VARCHAR(100),
    transaction_id VARCHAR(255),
    collected_by_id UUID,
    collected_by_name VARCHAR(255),
    received_by_id UUID,
    received_by_name VARCHAR(255),
    collector_id UUID,
    collector_name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'verified',
    verification_status VARCHAR(50) DEFAULT 'verified',
    collection_date_time TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS receipt_no VARCHAR(50);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(100);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS payment_type VARCHAR(50) DEFAULT 'cash';
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(50) DEFAULT 'cash';
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'verified';
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'verified';
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS collector_id UUID;
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS collector_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS collected_by_id UUID;
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS collected_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS received_by_id UUID;
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS received_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS remarks TEXT;
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS collection_date_time TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 6. Receipts Table (SRS Section 7)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_no VARCHAR(50),
    receipt_number VARCHAR(100),
    organization_id UUID,
    group_id UUID,
    campaign_id UUID,
    household_id UUID,
    household_head_name VARCHAR(255),
    family_member_count INT DEFAULT 1,
    per_person_rate NUMERIC(10, 2) DEFAULT 100.0,
    payer_name VARCHAR(255),
    amount NUMERIC(12, 2),
    amount_received NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    payment_type VARCHAR(50) NOT NULL DEFAULT 'cash',
    payment_mode VARCHAR(50) DEFAULT 'cash',
    reference_id VARCHAR(100),
    collector_id UUID,
    collected_by_name VARCHAR(255),
    received_by_name VARCHAR(255),
    pdf_url TEXT,
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    cancelled_by_name VARCHAR(255),
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS receipt_no VARCHAR(50);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(100);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS payment_type VARCHAR(50) DEFAULT 'cash';
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(50) DEFAULT 'cash';
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS amount_received NUMERIC(12, 2) DEFAULT 0.0;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS collector_id UUID;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS is_cancelled BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS cancelled_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- ==============================================================================
-- 7. Cash Handovers Table (SRS Section 6.3)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.cash_handovers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
    campaign_id UUID,
    handover_from_id UUID,
    handover_from_name VARCHAR(255),
    handover_to_id UUID,
    handover_to_name VARCHAR(255),
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    date_time TIMESTAMPTZ DEFAULT NOW(),
    remarks TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    confirmed_by_id UUID,
    confirmed_by_name VARCHAR(255),
    confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 8. Expenses Table (SRS Section 8)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
    group_id UUID,
    campaign_id UUID,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    expense_date DATE DEFAULT CURRENT_DATE,
    vendor_payee VARCHAR(255) NOT NULL,
    payment_mode VARCHAR(50) NOT NULL DEFAULT 'cash',
    payment_method VARCHAR(50) DEFAULT 'cash',
    bill_number VARCHAR(100),
    has_proof BOOLEAN DEFAULT FALSE,
    attachment_url TEXT,
    entered_by_id UUID,
    entered_by_name VARCHAR(255),
    approval_status VARCHAR(50) DEFAULT 'approved',
    payment_status VARCHAR(50) DEFAULT 'paid',
    is_public_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS expense_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'cash';
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(50) DEFAULT 'cash';
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS entered_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS approval_status VARCHAR(50) DEFAULT 'approved';
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'paid';
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS is_public_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 9. Complaints Table (SRS Section 10)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
    group_id UUID,
    campaign_id UUID,
    type VARCHAR(100) NOT NULL DEFAULT 'general',
    title VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    description TEXT NOT NULL,
    submitted_by_id UUID,
    submitted_by_name VARCHAR(255),
    submitted_by_phone VARCHAR(20),
    submitted_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'submitted',
    admin_response TEXT,
    response TEXT,
    resolution_notes TEXT,
    resolution TEXT,
    resolved_date TIMESTAMPTZ,
    is_escalated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS type VARCHAR(100) DEFAULT 'general';
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS title VARCHAR(255);
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS subject VARCHAR(255);
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS submitted_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS submitted_by_phone VARCHAR(20);
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS resolution TEXT;
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS response TEXT;
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 10. Audit Logs Table (SRS Section 12 FR-15)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
    group_id UUID,
    entity_type VARCHAR(100) DEFAULT 'System',
    resource_type VARCHAR(100) DEFAULT 'System',
    entity_id VARCHAR(100),
    resource_id VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    performed_by_id UUID,
    actor_user_id VARCHAR(100),
    performed_by_name VARCHAR(255) DEFAULT 'Admin',
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    details TEXT DEFAULT '',
    safe_metadata JSONB DEFAULT '{}'::jsonb
);

-- ==============================================================================
-- 11. Email OTPs Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.email_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    otp_hash VARCHAR(128) NOT NULL,
    purpose VARCHAR(100) NOT NULL DEFAULT 'Login Verification',
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 12. INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_households_campaign ON public.households(campaign_id);
CREATE INDEX IF NOT EXISTS idx_collections_campaign ON public.collections(campaign_id);
CREATE INDEX IF NOT EXISTS idx_receipts_receipt_no ON public.receipts(receipt_no);
CREATE INDEX IF NOT EXISTS idx_handovers_from_user ON public.cash_handovers(handover_from_id);
CREATE INDEX IF NOT EXISTS idx_expenses_campaign ON public.expenses(campaign_id);
CREATE INDEX IF NOT EXISTS idx_complaints_campaign ON public.complaints(campaign_id);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);

-- ==============================================================================
-- 13. DEFAULT INITIAL DATA (Organization, Mandals, Campaign & Super Admin)
-- ==============================================================================

-- 13.1 Default Organization
INSERT INTO public.organizations (
    id, name, registration_number, contact_person, phone, address, village, taluka, district, state, registration_date, status
) VALUES (
    '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
    'Shree Shiv Chhatrapati Mitra Mandal',
    'MH/2018/PUN/00918',
    'Sachin Kadam (President)',
    '+91 98220 54321',
    'Near Old Maruti Mandir, Main Chowk',
    'Sangvi',
    'Haveli',
    'Pune',
    'Maharashtra',
    '2018-05-12',
    'Active'
) ON CONFLICT (registration_number) DO UPDATE SET name = EXCLUDED.name;

-- 13.2 Default Groups
INSERT INTO public.groups (
    id, organization_id, name, code, description, status, contribution_settings
) VALUES 
    (
        'b6294a50-612f-48d8-9993-4a0e104e1001',
        '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
        'Shivaji Chowk Mandal Group',
        'GRP-SC-01',
        'Main Pandal & Shivaji Chowk collection jurisdiction',
        'Active',
        '{"suggested_amount": 500, "allow_partial": true, "per_person_rate": 200}'::jsonb
    ),
    (
        'b6294a50-612f-48d8-9993-4a0e104e1002',
        '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
        'Maruti Mandir Parisar Group',
        'GRP-MM-02',
        'Maruti Mandir and Gaothan inner lanes',
        'Active',
        '{"suggested_amount": 500, "allow_partial": true, "per_person_rate": 200}'::jsonb
    ),
    (
        'b6294a50-612f-48d8-9993-4a0e104e1003',
        '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
        'Station Road Committee',
        'GRP-SR-03',
        'Station Road and Market line shopkeepers',
        'Active',
        '{"suggested_amount": 1000, "allow_partial": true, "per_person_rate": 300}'::jsonb
    )
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name,
    contribution_settings = EXCLUDED.contribution_settings;

-- 13.3 Default Campaign
INSERT INTO public.campaigns (
    id, organization_id, name, vargani_type, description, start_date, end_date, target_amount, per_person_rate, suggested_amount, allow_partial_payment, status
) VALUES (
    'c0000000-0000-0000-0000-000000000001',
    '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
    'Ganeshotsav 2026',
    'Ganeshotsav',
    'Annual Ganeshotsav Festival Collection 2026',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    500000.00,
    100.00,
    500.00,
    TRUE,
    'Active'
) ON CONFLICT (id) DO NOTHING;

-- 13.4 Default Super Admin User
INSERT INTO public.users (
    id, organization_id, name, phone, email, role, is_active
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
    'Ritesh Sangale (Super Admin)',
    '9699342811',
    'riteshsangale71@gmail.com',
    'super_admin',
    TRUE
) ON CONFLICT (phone) DO UPDATE SET 
    role = 'super_admin',
    is_active = TRUE;

-- 13.5 Default Roles
INSERT INTO public.roles (code, role_key, name, is_system, is_system_role, description, permissions)
VALUES 
    ('SUPER_ADMIN', 'SUPER_ADMIN', 'Super Admin', TRUE, TRUE, 'Full System Access', ARRAY['*']),
    ('ORG_ADMIN', 'ORG_ADMIN', 'Organization Admin', TRUE, TRUE, 'Organization Management', ARRAY['dashboard.view', 'campaigns.view', 'collections.view', 'expenses.view']),
    ('GROUP_ADMIN', 'GROUP_ADMIN', 'Group Admin / Treasurer', TRUE, TRUE, 'Group & Collections Management', ARRAY['dashboard.view', 'collections.view', 'receipts.view']),
    ('COLLECTOR', 'COLLECTOR', 'Collector', TRUE, TRUE, 'Field Collections', ARRAY['collections.create', 'receipts.create']),
    ('MEMBER', 'MEMBER', 'Citizen / Member', TRUE, TRUE, 'Transparency View', ARRAY['dashboard.view', 'receipts.view'])
ON CONFLICT (code) DO NOTHING;

-- ==============================================================================
-- 14. HELPER FUNCTIONS & RPCs
-- ==============================================================================

-- Phone lookup for OTP verification
CREATE OR REPLACE FUNCTION public.lookup_phone_email(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_clean_phone TEXT;
    v_user RECORD;
BEGIN
    v_clean_phone := regexp_replace(COALESCE(p_phone, ''), '\D', '', 'g');
    IF length(v_clean_phone) >= 10 THEN
        v_clean_phone := right(v_clean_phone, 10);
    END IF;

    SELECT id, email, name, phone, is_active
    INTO v_user
    FROM public.users
    WHERE right(regexp_replace(COALESCE(phone, ''), '\D', '', 'g'), 10) = v_clean_phone
    LIMIT 1;

    IF v_user.id IS NULL THEN
        SELECT id, email, full_name as name, phone, (account_status = 'active') as is_active
        INTO v_user
        FROM public.profiles
        WHERE right(regexp_replace(COALESCE(phone, ''), '\D', '', 'g'), 10) = v_clean_phone
        LIMIT 1;
    END IF;

    IF v_user.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'या मोबाईल क्रमांकाशी जोडलेले खाते सापडले नाही.'
        );
    END IF;

    IF NOT v_user.is_active THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'आपले खाते निष्क्रिय (Inactive) आहे. कृपया प्रशासकाशी संपर्क साधा.'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'email', v_user.email,
        'name', v_user.name,
        'user_id', v_user.id
    );
END;
$$;

-- Super admin check function
CREATE OR REPLACE FUNCTION public.check_super_admin_initialized()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users WHERE phone = '9699342811' AND is_active = TRUE
    );
END;
$$;

-- ==============================================================================
-- 15. ROW LEVEL SECURITY (RLS) POLICIES (SAFE DROP & CREATE)
-- ==============================================================================
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_handovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

-- Drop any previous conflicting policies safely
DROP POLICY IF EXISTS "Allow public read organizations" ON public.organizations;
DROP POLICY IF EXISTS "Allow public read groups" ON public.groups;
DROP POLICY IF EXISTS "Allow public read permissions" ON public.permissions;
DROP POLICY IF EXISTS "Allow public read roles" ON public.roles;
DROP POLICY IF EXISTS "Allow public read users" ON public.users;
DROP POLICY IF EXISTS "Allow public read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow public read campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Allow public read households" ON public.households;
DROP POLICY IF EXISTS "Allow public read collections" ON public.collections;
DROP POLICY IF EXISTS "Allow public read receipts" ON public.receipts;
DROP POLICY IF EXISTS "Allow public read cash_handovers" ON public.cash_handovers;
DROP POLICY IF EXISTS "Allow public read expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow public read complaints" ON public.complaints;
DROP POLICY IF EXISTS "Allow public read audit_logs" ON public.audit_logs;

DROP POLICY IF EXISTS "Allow write organizations" ON public.organizations;
DROP POLICY IF EXISTS "Allow write groups" ON public.groups;
DROP POLICY IF EXISTS "Allow write permissions" ON public.permissions;
DROP POLICY IF EXISTS "Allow write roles" ON public.roles;
DROP POLICY IF EXISTS "Allow write users" ON public.users;
DROP POLICY IF EXISTS "Allow write profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow write campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Allow write households" ON public.households;
DROP POLICY IF EXISTS "Allow write collections" ON public.collections;
DROP POLICY IF EXISTS "Allow write receipts" ON public.receipts;
DROP POLICY IF EXISTS "Allow write cash_handovers" ON public.cash_handovers;
DROP POLICY IF EXISTS "Allow write expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow write complaints" ON public.complaints;
DROP POLICY IF EXISTS "Allow write audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Allow write email_otps" ON public.email_otps;

-- Re-create policies cleanly
CREATE POLICY "Allow public read organizations" ON public.organizations FOR SELECT USING (true);
CREATE POLICY "Allow public read groups" ON public.groups FOR SELECT USING (true);
CREATE POLICY "Allow public read permissions" ON public.permissions FOR SELECT USING (true);
CREATE POLICY "Allow public read roles" ON public.roles FOR SELECT USING (true);
CREATE POLICY "Allow public read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow public read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow public read campaigns" ON public.campaigns FOR SELECT USING (true);
CREATE POLICY "Allow public read households" ON public.households FOR SELECT USING (true);
CREATE POLICY "Allow public read collections" ON public.collections FOR SELECT USING (true);
CREATE POLICY "Allow public read receipts" ON public.receipts FOR SELECT USING (true);
CREATE POLICY "Allow public read cash_handovers" ON public.cash_handovers FOR SELECT USING (true);
CREATE POLICY "Allow public read expenses" ON public.expenses FOR SELECT USING (true);
CREATE POLICY "Allow public read complaints" ON public.complaints FOR SELECT USING (true);
CREATE POLICY "Allow public read audit_logs" ON public.audit_logs FOR SELECT USING (true);

CREATE POLICY "Allow write organizations" ON public.organizations FOR ALL USING (true);
CREATE POLICY "Allow write groups" ON public.groups FOR ALL USING (true);
CREATE POLICY "Allow write permissions" ON public.permissions FOR ALL USING (true);
CREATE POLICY "Allow write roles" ON public.roles FOR ALL USING (true);
CREATE POLICY "Allow write users" ON public.users FOR ALL USING (true);
CREATE POLICY "Allow write profiles" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Allow write campaigns" ON public.campaigns FOR ALL USING (true);
CREATE POLICY "Allow write households" ON public.households FOR ALL USING (true);
CREATE POLICY "Allow write collections" ON public.collections FOR ALL USING (true);
CREATE POLICY "Allow write receipts" ON public.receipts FOR ALL USING (true);
CREATE POLICY "Allow write cash_handovers" ON public.cash_handovers FOR ALL USING (true);
CREATE POLICY "Allow write expenses" ON public.expenses FOR ALL USING (true);
CREATE POLICY "Allow write complaints" ON public.complaints FOR ALL USING (true);
CREATE POLICY "Allow write audit_logs" ON public.audit_logs FOR ALL USING (true);
CREATE POLICY "Allow write email_otps" ON public.email_otps FOR ALL USING (true);

SELECT 'Vargani Pro Database Schema restored successfully!' AS status;
