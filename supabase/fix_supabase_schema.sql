-- ==============================================================================
-- VARGANI PRO (वर्गणी) - SUPABASE MASTER FIX & SCHEMA REPAIR SCRIPT
-- Project URL: https://lqeohtminzfjhqclcnkm.supabase.co
-- Dashboard SQL Editor: https://supabase.com/dashboard/project/lqeohtminzfjhqclcnkm/sql/new
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. ENSURE ALL TABLES EXIST
-- ==============================================================================

-- 2.1 Organizations
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
    registration_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.2 Groups / Mandals
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    location TEXT,
    status VARCHAR(50) DEFAULT 'Active',
    contribution_settings JSONB DEFAULT '{"suggested_amount": 500, "allow_partial": true, "per_person_rate": 200}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.3 Permissions
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

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'permissions_id_unique'
    ) THEN
        ALTER TABLE public.permissions ADD CONSTRAINT permissions_id_unique UNIQUE (id);
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 2.4 Roles
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL UNIQUE,
    role_key VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    scope_type VARCHAR(20) DEFAULT 'system',
    is_system BOOLEAN DEFAULT FALSE,
    is_system_role BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    group_id UUID,
    description TEXT,
    permissions TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.5 Role-Permissions Join Table (CRITICAL: Fixes PGRST205 / PGRST200)
CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_role_permissions_permission'
    ) THEN
        ALTER TABLE public.role_permissions
        ADD CONSTRAINT fk_role_permissions_permission
        FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 2.6 Users Table
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

-- 2.7 Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    avatar_url TEXT,
    account_status VARCHAR(20) NOT NULL DEFAULT 'active',
    address TEXT,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE IF EXISTS public.users ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- 2.8 User Roles Assignment Table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    organization_id UUID,
    group_id UUID,
    assigned_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.9 Group Members Table
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    membership_status VARCHAR(20) NOT NULL DEFAULT 'active',
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.10 Join Requests Table
CREATE TABLE IF NOT EXISTS public.join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    request_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    message TEXT,
    user_notes TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.11 Campaigns Table
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
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

-- 2.12 Households Table
CREATE TABLE IF NOT EXISTS public.households (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID,
    organization_id UUID,
    head_of_family_name VARCHAR(255) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    village_area VARCHAR(255) NOT NULL,
    family_member_count INT NOT NULL DEFAULT 4,
    per_person_rate_snapshot NUMERIC(10, 2) NOT NULL DEFAULT 100.0,
    amount_received NUMERIC(12, 2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.13 Collections Table
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_no VARCHAR(50),
    organization_id UUID,
    campaign_id UUID,
    campaign_name VARCHAR(255),
    household_id UUID,
    household_head_name VARCHAR(255),
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    payment_type VARCHAR(50) NOT NULL DEFAULT 'cash',
    reference_id VARCHAR(100),
    collected_by_id UUID,
    collector_id UUID,
    collected_by_name VARCHAR(255),
    received_by_id UUID,
    received_by_name VARCHAR(255),
    verification_status VARCHAR(50) DEFAULT 'verified',
    collection_date_time TIMESTAMPTZ DEFAULT NOW(),
    remarks TEXT
);

-- 2.14 Receipts Table
CREATE TABLE IF NOT EXISTS public.receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_no VARCHAR(50) NOT NULL,
    organization_id UUID,
    campaign_id UUID,
    campaign_name VARCHAR(255),
    household_id UUID,
    household_head_name VARCHAR(255),
    family_member_count INT DEFAULT 1,
    per_person_rate NUMERIC(10, 2) DEFAULT 100.0,
    amount_received NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    payment_type VARCHAR(50) NOT NULL DEFAULT 'cash',
    reference_id VARCHAR(100),
    collector_id UUID,
    collected_by_name VARCHAR(255),
    received_by_name VARCHAR(255),
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    cancelled_by_name VARCHAR(255),
    cancelled_at TIMESTAMPTZ
);

-- 2.15 Cash Handovers Table
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
    confirmed_at TIMESTAMPTZ
);

-- 2.16 Expenses Table
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
    campaign_id UUID,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    date DATE DEFAULT CURRENT_DATE,
    vendor_payee VARCHAR(255) NOT NULL,
    payment_mode VARCHAR(50) NOT NULL,
    bill_number VARCHAR(100),
    has_proof BOOLEAN DEFAULT FALSE,
    attachment_url TEXT,
    entered_by_id UUID,
    entered_by_name VARCHAR(255),
    approval_status VARCHAR(50) DEFAULT 'pending',
    payment_status VARCHAR(50) DEFAULT 'paid',
    is_public_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.17 Complaints Table
CREATE TABLE IF NOT EXISTS public.complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID,
    campaign_id UUID,
    type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    submitted_by_id UUID,
    submitted_by_name VARCHAR(255),
    submitted_by_phone VARCHAR(20),
    submitted_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'submitted',
    admin_response TEXT,
    resolution_notes TEXT,
    resolved_date TIMESTAMPTZ,
    is_escalated BOOLEAN DEFAULT FALSE
);

-- 2.18 Audit Logs Table
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

-- 2.19 Email OTPs Table
CREATE TABLE IF NOT EXISTS public.email_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    otp_hash VARCHAR(128) NOT NULL,
    purpose VARCHAR(100) NOT NULL DEFAULT 'Login Verification',
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes'),
    attempts_remaining INT NOT NULL DEFAULT 3,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 3. SAFE COLUMN ALTERATIONS & REPAIRS (Fixes Error 42703)
-- ==============================================================================

-- 3.1 Roles Columns
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS role_key VARCHAR(50);
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS scope_type VARCHAR(20) DEFAULT 'system';
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS is_system_role BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS group_id UUID;
ALTER TABLE IF EXISTS public.roles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
UPDATE public.roles SET role_key = code WHERE role_key IS NULL;
UPDATE public.roles SET is_active = TRUE WHERE is_active IS NULL;

-- 3.2 Audit Logs Columns & Constraints
ALTER TABLE IF EXISTS public.audit_logs ADD COLUMN IF NOT EXISTS actor_user_id VARCHAR(100);
ALTER TABLE IF EXISTS public.audit_logs ADD COLUMN IF NOT EXISTS resource_type VARCHAR(100) DEFAULT 'System';
ALTER TABLE IF EXISTS public.audit_logs ADD COLUMN IF NOT EXISTS resource_id VARCHAR(100);
ALTER TABLE IF EXISTS public.audit_logs ADD COLUMN IF NOT EXISTS group_id UUID;
ALTER TABLE IF EXISTS public.audit_logs ADD COLUMN IF NOT EXISTS safe_metadata JSONB DEFAULT '{}'::jsonb;
ALTER TABLE IF EXISTS public.audit_logs ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN entity_type DROP NOT NULL;
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN entity_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN performed_by_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN performed_by_name DROP NOT NULL;
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN details DROP NOT NULL;

-- 3.3 User Roles Columns
ALTER TABLE IF EXISTS public.user_roles ADD COLUMN IF NOT EXISTS assigned_by UUID;
ALTER TABLE IF EXISTS public.user_roles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- 3.4 Join Requests Columns
ALTER TABLE IF EXISTS public.join_requests ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE IF EXISTS public.join_requests ADD COLUMN IF NOT EXISTS reviewed_by UUID;
ALTER TABLE IF EXISTS public.join_requests ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.join_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 3.5 Collections Columns & Constraints
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS campaign_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS household_head_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS collected_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS received_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.collections ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'verified';
ALTER TABLE IF EXISTS public.collections ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.collections ALTER COLUMN campaign_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.collections ALTER COLUMN household_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.collections ALTER COLUMN collected_by_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.collections ALTER COLUMN received_by_id DROP NOT NULL;

-- 3.6 Receipts Columns & Constraints
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS campaign_name VARCHAR(255);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS household_head_name VARCHAR(255);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS family_member_count INT DEFAULT 1;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS per_person_rate NUMERIC(10, 2) DEFAULT 100.0;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS is_cancelled BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS cancelled_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.receipts ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.receipts ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.receipts ALTER COLUMN campaign_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.receipts ALTER COLUMN household_id DROP NOT NULL;

-- 3.7 Cash Handovers Columns & Constraints
ALTER TABLE IF EXISTS public.cash_handovers ADD COLUMN IF NOT EXISTS handover_from_name VARCHAR(255);
ALTER TABLE IF EXISTS public.cash_handovers ADD COLUMN IF NOT EXISTS handover_to_name VARCHAR(255);
ALTER TABLE IF EXISTS public.cash_handovers ADD COLUMN IF NOT EXISTS confirmed_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.cash_handovers ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.cash_handovers ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.cash_handovers ALTER COLUMN campaign_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.cash_handovers ALTER COLUMN handover_from_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.cash_handovers ALTER COLUMN handover_to_id DROP NOT NULL;

-- 3.8 Expenses Columns & Constraints
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS entered_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.expenses ADD COLUMN IF NOT EXISTS is_public_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.expenses ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.expenses ALTER COLUMN campaign_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.expenses ALTER COLUMN entered_by_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.expenses ALTER COLUMN date SET DEFAULT CURRENT_DATE;
ALTER TABLE IF EXISTS public.expenses ALTER COLUMN date DROP NOT NULL;

-- 3.9 Complaints Columns & Constraints
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS submitted_by_name VARCHAR(255);
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS submitted_by_phone VARCHAR(20);
ALTER TABLE IF EXISTS public.complaints ADD COLUMN IF NOT EXISTS is_escalated BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.complaints ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.complaints ALTER COLUMN campaign_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.complaints ALTER COLUMN submitted_by_id DROP NOT NULL;

-- 3.10 Households Columns & Constraints
ALTER TABLE IF EXISTS public.households ADD COLUMN IF NOT EXISTS amount_received NUMERIC(12, 2) DEFAULT 0.0;
ALTER TABLE IF EXISTS public.households ALTER COLUMN organization_id DROP NOT NULL;
ALTER TABLE IF EXISTS public.households ALTER COLUMN campaign_id DROP NOT NULL;

-- ==============================================================================
-- 4. FOREIGN KEY CONSTRAINTS (Fixes PostgREST PGRST200 Embedding Errors)
-- ==============================================================================

DO $$
BEGIN
    -- user_roles -> profiles
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_user') THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;

    -- user_roles -> roles
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_role') THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;
    END IF;

    -- user_roles -> organizations
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_org') THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_org
        FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
    END IF;

    -- user_roles -> groups
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_group') THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_group
        FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;
    END IF;

    -- join_requests -> profiles
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_join_requests_user') THEN
        ALTER TABLE public.join_requests
        ADD CONSTRAINT fk_join_requests_user
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;

    -- join_requests -> groups
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_join_requests_group') THEN
        ALTER TABLE public.join_requests
        ADD CONSTRAINT fk_join_requests_group
        FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;
    END IF;

    -- group_members -> groups
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_group_members_group') THEN
        ALTER TABLE public.group_members
        ADD CONSTRAINT fk_group_members_group
        FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;
    END IF;

    -- group_members -> profiles
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_group_members_user') THEN
        ALTER TABLE public.group_members
        ADD CONSTRAINT fk_group_members_user
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ==============================================================================
-- 5. SEED SYSTEM PERMISSIONS (Fixes Empty Permissions Table)
-- ==============================================================================

INSERT INTO public.permissions (code, permission_key, module, action, description)
VALUES
    ('organization.view', 'organization.view', 'organization', 'view', 'View organization details and dashboard'),
    ('organization.create', 'organization.create', 'organization', 'create', 'Create new organizations'),
    ('organization.update', 'organization.update', 'organization', 'update', 'Update organization details'),
    ('organization.delete', 'organization.delete', 'organization', 'delete', 'Deactivate or archive organizations'),
    ('group.view', 'group.view', 'group', 'view', 'View group details and summary'),
    ('group.create', 'group.create', 'group', 'create', 'Create new groups/mandals'),
    ('group.update', 'group.update', 'group', 'update', 'Update group parameters and settings'),
    ('group.delete', 'group.delete', 'group', 'delete', 'Deactivate or delete groups'),
    ('user.view', 'user.view', 'user', 'view', 'View user profiles and list'),
    ('user.create', 'user.create', 'user', 'create', 'Create or invite new users'),
    ('user.update', 'user.update', 'user', 'update', 'Edit user profile details'),
    ('user.deactivate', 'user.deactivate', 'user', 'deactivate', 'Suspend or deactivate user accounts'),
    ('role.view', 'role.view', 'role', 'view', 'View system and custom roles'),
    ('role.create', 'role.create', 'role', 'create', 'Create new roles and permission sets'),
    ('role.update', 'role.update', 'role', 'update', 'Edit permissions and active status of roles'),
    ('role.assign', 'role.assign', 'role', 'assign', 'Assign roles to users in organization/group'),
    ('campaigns.view', 'campaigns.view', 'campaign', 'view', 'View campaigns and targets'),
    ('campaigns.create', 'campaigns.create', 'campaign', 'create', 'Create new festival campaign'),
    ('campaigns.update', 'campaigns.update', 'campaign', 'update', 'Update campaign details'),
    ('collections.view', 'collections.view', 'collection', 'view', 'View collection records and totals'),
    ('collections.create', 'collections.create', 'collection', 'create', 'Collect vargani and register payment'),
    ('collections.verify', 'collections.verify', 'collection', 'verify', 'Verify payments and cash transfers'),
    ('receipts.view', 'receipts.view', 'receipt', 'view', 'View and download receipts'),
    ('receipts.create', 'receipts.create', 'receipt', 'create', 'Issue new receipt for payment'),
    ('receipts.cancel', 'receipts.cancel', 'receipt', 'cancel', 'Cancel issued receipt with audit reason'),
    ('expenses.view', 'expenses.view', 'expense', 'view', 'View expense list and summaries'),
    ('expenses.create', 'expenses.create', 'expense', 'create', 'Add new expense record with bill/proof'),
    ('expenses.approve', 'expenses.approve', 'expense', 'approve', 'Approve or reject submitted expense'),
    ('complaints.view', 'complaints.view', 'complaint', 'view', 'View complaints and grievance list'),
    ('complaints.create', 'complaints.create', 'complaint', 'create', 'Submit grievance or complaint'),
    ('complaints.resolve', 'complaints.resolve', 'complaint', 'resolve', 'Resolve complaint and respond'),
    ('audit.view', 'audit.view', 'audit', 'view', 'View system audit trails and logs'),
    ('dashboard.view', 'dashboard.view', 'dashboard', 'view', 'Access executive and operational dashboards')
ON CONFLICT (code) DO UPDATE SET
    permission_key = EXCLUDED.permission_key,
    module = EXCLUDED.module,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

-- Ensure all permissions have matching permission_key
UPDATE public.permissions SET permission_key = code WHERE permission_key IS NULL;

-- ==============================================================================
-- 6. LINK ROLES TO ROLE_PERMISSIONS
-- ==============================================================================

-- 6.1 SUPER_ADMIN gets all permissions
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.code = 'SUPER_ADMIN'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 6.2 ORG_ADMIN permissions
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
    'dashboard.view', 'organization.view', 'group.view', 'group.create', 'group.update',
    'user.view', 'user.create', 'user.update', 'user.deactivate', 'role.view', 'role.assign',
    'campaigns.view', 'campaigns.create', 'campaigns.update',
    'collections.view', 'receipts.view', 'expenses.view', 'expenses.create', 'expenses.approve',
    'complaints.view', 'complaints.resolve', 'audit.view'
)
WHERE r.code = 'ORG_ADMIN'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 6.3 GROUP_ADMIN permissions
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
    'dashboard.view', 'group.view', 'group.update',
    'campaigns.view', 'collections.view', 'collections.create', 'collections.verify',
    'receipts.view', 'receipts.create', 'receipts.cancel',
    'expenses.view', 'expenses.create', 'complaints.view', 'complaints.create'
)
WHERE r.code = 'GROUP_ADMIN'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 6.4 COLLECTOR permissions
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
    'dashboard.view', 'campaigns.view', 'collections.view', 'collections.create',
    'receipts.view', 'receipts.create'
)
WHERE r.code = 'COLLECTOR'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 6.5 MEMBER permissions
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
    'dashboard.view', 'campaigns.view', 'receipts.view', 'expenses.view', 'complaints.create'
)
WHERE r.code = 'MEMBER'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ==============================================================================
-- 7. SYNC SUPER ADMIN USER (Ritesh Sangale) TO PROFILES & USER_ROLES
-- ==============================================================================

-- 7.1 Sync users to profiles
INSERT INTO public.profiles (
    id, full_name, email, phone, account_status, created_at, updated_at
)
SELECT 
    u.id, 
    u.name, 
    u.email, 
    u.phone, 
    CASE WHEN u.is_active THEN 'active' ELSE 'inactive' END,
    u.created_at,
    u.updated_at
FROM public.users u
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    account_status = EXCLUDED.account_status,
    updated_at = NOW();

-- 7.2 Explicitly ensure Ritesh Sangale profile exists
INSERT INTO public.profiles (
    id, full_name, email, phone, account_status
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Ritesh Sangale (Super Admin)',
    'riteshsangale71@gmail.com',
    '9699342811',
    'active'
) ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    account_status = 'active';

-- 7.3 Assign SUPER_ADMIN role in user_roles
INSERT INTO public.user_roles (
    user_id, role_id, organization_id, group_id, assigned_by
)
SELECT 
    'a0000000-0000-0000-0000-000000000001'::uuid,
    r.id,
    '3609220e-4897-49c9-a2b0-a7e0eb4fc159'::uuid,
    NULL,
    'a0000000-0000-0000-0000-000000000001'::uuid
FROM public.roles r
WHERE r.code = 'SUPER_ADMIN'
AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = 'a0000000-0000-0000-0000-000000000001'::uuid
    AND ur.role_id = r.id
);

-- ==============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_handovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

-- Drop previous policies safely
DROP POLICY IF EXISTS "Allow public read organizations" ON public.organizations;
DROP POLICY IF EXISTS "Allow write organizations" ON public.organizations;
DROP POLICY IF EXISTS "Allow public read groups" ON public.groups;
DROP POLICY IF EXISTS "Allow write groups" ON public.groups;
DROP POLICY IF EXISTS "Allow public read permissions" ON public.permissions;
DROP POLICY IF EXISTS "Allow write permissions" ON public.permissions;
DROP POLICY IF EXISTS "Allow public read roles" ON public.roles;
DROP POLICY IF EXISTS "Allow write roles" ON public.roles;
DROP POLICY IF EXISTS "Allow public read role_permissions" ON public.role_permissions;
DROP POLICY IF EXISTS "Allow write role_permissions" ON public.role_permissions;
DROP POLICY IF EXISTS "Allow public read users" ON public.users;
DROP POLICY IF EXISTS "Allow write users" ON public.users;
DROP POLICY IF EXISTS "Allow public read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow write profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow public read user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Allow write user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Allow public read group_members" ON public.group_members;
DROP POLICY IF EXISTS "Allow write group_members" ON public.group_members;
DROP POLICY IF EXISTS "Allow public read join_requests" ON public.join_requests;
DROP POLICY IF EXISTS "Allow write join_requests" ON public.join_requests;
DROP POLICY IF EXISTS "Allow public read campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Allow write campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Allow public read households" ON public.households;
DROP POLICY IF EXISTS "Allow write households" ON public.households;
DROP POLICY IF EXISTS "Allow public read collections" ON public.collections;
DROP POLICY IF EXISTS "Allow write collections" ON public.collections;
DROP POLICY IF EXISTS "Allow public read receipts" ON public.receipts;
DROP POLICY IF EXISTS "Allow write receipts" ON public.receipts;
DROP POLICY IF EXISTS "Allow public read cash_handovers" ON public.cash_handovers;
DROP POLICY IF EXISTS "Allow write cash_handovers" ON public.cash_handovers;
DROP POLICY IF EXISTS "Allow public read expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow write expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow public read complaints" ON public.complaints;
DROP POLICY IF EXISTS "Allow write complaints" ON public.complaints;
DROP POLICY IF EXISTS "Allow public read audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Allow write audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Allow public read email_otps" ON public.email_otps;
DROP POLICY IF EXISTS "Allow write email_otps" ON public.email_otps;

-- Create clean policies allowing application operations
CREATE POLICY "Allow public read organizations" ON public.organizations FOR SELECT USING (true);
CREATE POLICY "Allow write organizations" ON public.organizations FOR ALL USING (true);

CREATE POLICY "Allow public read groups" ON public.groups FOR SELECT USING (true);
CREATE POLICY "Allow write groups" ON public.groups FOR ALL USING (true);

CREATE POLICY "Allow public read permissions" ON public.permissions FOR SELECT USING (true);
CREATE POLICY "Allow write permissions" ON public.permissions FOR ALL USING (true);

CREATE POLICY "Allow public read roles" ON public.roles FOR SELECT USING (true);
CREATE POLICY "Allow write roles" ON public.roles FOR ALL USING (true);

CREATE POLICY "Allow public read role_permissions" ON public.role_permissions FOR SELECT USING (true);
CREATE POLICY "Allow write role_permissions" ON public.role_permissions FOR ALL USING (true);

CREATE POLICY "Allow public read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow write users" ON public.users FOR ALL USING (true);

CREATE POLICY "Allow public read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow write profiles" ON public.profiles FOR ALL USING (true);

CREATE POLICY "Allow public read user_roles" ON public.user_roles FOR SELECT USING (true);
CREATE POLICY "Allow write user_roles" ON public.user_roles FOR ALL USING (true);

CREATE POLICY "Allow public read group_members" ON public.group_members FOR SELECT USING (true);
CREATE POLICY "Allow write group_members" ON public.group_members FOR ALL USING (true);

CREATE POLICY "Allow public read join_requests" ON public.join_requests FOR SELECT USING (true);
CREATE POLICY "Allow write join_requests" ON public.join_requests FOR ALL USING (true);

CREATE POLICY "Allow public read campaigns" ON public.campaigns FOR SELECT USING (true);
CREATE POLICY "Allow write campaigns" ON public.campaigns FOR ALL USING (true);

CREATE POLICY "Allow public read households" ON public.households FOR SELECT USING (true);
CREATE POLICY "Allow write households" ON public.households FOR ALL USING (true);

CREATE POLICY "Allow public read collections" ON public.collections FOR SELECT USING (true);
CREATE POLICY "Allow write collections" ON public.collections FOR ALL USING (true);

CREATE POLICY "Allow public read receipts" ON public.receipts FOR SELECT USING (true);
CREATE POLICY "Allow write receipts" ON public.receipts FOR ALL USING (true);

CREATE POLICY "Allow public read cash_handovers" ON public.cash_handovers FOR SELECT USING (true);
CREATE POLICY "Allow write cash_handovers" ON public.cash_handovers FOR ALL USING (true);

CREATE POLICY "Allow public read expenses" ON public.expenses FOR SELECT USING (true);
CREATE POLICY "Allow write expenses" ON public.expenses FOR ALL USING (true);

CREATE POLICY "Allow public read complaints" ON public.complaints FOR SELECT USING (true);
CREATE POLICY "Allow write complaints" ON public.complaints FOR ALL USING (true);

CREATE POLICY "Allow public read audit_logs" ON public.audit_logs FOR SELECT USING (true);
CREATE POLICY "Allow write audit_logs" ON public.audit_logs FOR ALL USING (true);

CREATE POLICY "Allow public read email_otps" ON public.email_otps FOR SELECT USING (true);
CREATE POLICY "Allow write email_otps" ON public.email_otps FOR ALL USING (true);

-- ==============================================================================
-- 9. RELOAD SCHEMA CACHE
-- ==============================================================================
NOTIFY pgrst, 'reload schema';

SELECT 'Vargani Pro Database Schema repaired successfully!' AS status;

