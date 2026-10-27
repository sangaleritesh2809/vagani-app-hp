-- ==============================================================================
-- VARGANI COLLECTION APP - ENTERPRISE MULTI-ORGANIZATION RBAC COMPLETE SETUP
-- Execute this script in your Supabase SQL Editor to initialize all tables,
-- functions, RLS policies, system roles, permissions, and bootstrap RPC.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. TABLES
-- ==============================================================================

-- 2.1 Profiles Table (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    avatar_url TEXT,
    account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(account_status);

-- 2.2 Organizations Table
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_organizations_slug ON public.organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organizations_status ON public.organizations(status);

-- 2.3 Groups Table (Belongs to exactly one Organization)
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    location TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    contribution_settings JSONB NOT NULL DEFAULT '{"suggested_amount": 100, "allow_partial": true, "per_person_rate": 100}'::jsonb,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_groups_org ON public.groups(organization_id);
CREATE INDEX IF NOT EXISTS idx_groups_code ON public.groups(code);
CREATE INDEX IF NOT EXISTS idx_groups_status ON public.groups(status);

-- 2.4 Roles Table (Dynamic RBAC)
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    role_key VARCHAR(50) NOT NULL UNIQUE,
    scope_type VARCHAR(20) NOT NULL CHECK (scope_type IN ('system', 'organization', 'group')),
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_roles_key ON public.roles(role_key);
CREATE INDEX IF NOT EXISTS idx_roles_scope ON public.roles(scope_type);

-- 2.5 Permissions Table
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_key VARCHAR(100) NOT NULL UNIQUE,
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE INDEX IF NOT EXISTS idx_permissions_key ON public.permissions(permission_key);
CREATE INDEX IF NOT EXISTS idx_permissions_module ON public.permissions(module);

-- 2.6 Role-Permissions Join Table
CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- 2.7 User-Roles Assignment Table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_role_scope UNIQUE NULLS NOT DISTINCT (user_id, role_id, organization_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_org ON public.user_roles(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_group ON public.user_roles(group_id);

-- 2.8 Group Members Table
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    membership_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (membership_status IN ('active', 'inactive', 'suspended')),
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_group_user UNIQUE (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);

-- 2.9 Join Requests Table
CREATE TABLE IF NOT EXISTS public.join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    request_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (request_status IN ('pending', 'approved', 'rejected', 'cancelled')),
    message TEXT,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_join_requests 
ON public.join_requests(group_id, user_id) 
WHERE request_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_join_requests_group ON public.join_requests(group_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_user ON public.join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON public.join_requests(request_status);

-- 2.10 Collections Table
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    campaign_id VARCHAR(100) DEFAULT 'cmp_ganesh_2026',
    member_id UUID REFERENCES public.group_members(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('cash', 'online', 'bank_transfer', 'upi', 'other')),
    transaction_reference VARCHAR(100),
    collected_by UUID NOT NULL REFERENCES public.profiles(id),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'verified' CHECK (status IN ('verified', 'pending', 'cancelled')),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collections_group ON public.collections(group_id);
CREATE INDEX IF NOT EXISTS idx_collections_campaign ON public.collections(campaign_id);
CREATE INDEX IF NOT EXISTS idx_collections_collected_by ON public.collections(collected_by);
CREATE INDEX IF NOT EXISTS idx_collections_date ON public.collections(transaction_date);

-- 2.11 Receipts Table
CREATE TABLE IF NOT EXISTS public.receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    campaign_id VARCHAR(100) DEFAULT 'cmp_ganesh_2026',
    collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
    receipt_number VARCHAR(50) NOT NULL,
    issued_by UUID NOT NULL REFERENCES public.profiles(id),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    receipt_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT unique_group_receipt UNIQUE (group_id, receipt_number)
);

CREATE INDEX IF NOT EXISTS idx_receipts_group ON public.receipts(group_id);
CREATE INDEX IF NOT EXISTS idx_receipts_campaign ON public.receipts(campaign_id);
CREATE INDEX IF NOT EXISTS idx_receipts_collection ON public.receipts(collection_id);
CREATE INDEX IF NOT EXISTS idx_receipts_number ON public.receipts(receipt_number);

-- 2.12 Expenses Table
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    campaign_id VARCHAR(100) DEFAULT 'cmp_ganesh_2026',
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    category VARCHAR(100) NOT NULL,
    description TEXT,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(50) NOT NULL,
    vendor_payee VARCHAR(255),
    bill_number VARCHAR(100),
    attachment_url TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    status VARCHAR(20) NOT NULL DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expenses_group ON public.expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_campaign ON public.expenses(campaign_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);

-- 2.13 Complaints / Grievances Table
CREATE TABLE IF NOT EXISTS public.complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    campaign_id VARCHAR(100) DEFAULT 'cmp_ganesh_2026',
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'in_progress', 'resolved', 'closed')),
    resolution TEXT,
    assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaints_group ON public.complaints(group_id);
CREATE INDEX IF NOT EXISTS idx_complaints_campaign ON public.complaints(campaign_id);
CREATE INDEX IF NOT EXISTS idx_complaints_user ON public.complaints(user_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON public.complaints(status);

-- 2.14 Audit Logs Table (Append-only, strictly immutable)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(100),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    safe_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_actor ON public.audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_resource ON public.audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_org ON public.audit_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_group ON public.audit_logs(group_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON public.audit_logs(created_at);

-- 2.15 Campaigns Table
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    vargani_type VARCHAR(100) NOT NULL DEFAULT 'Ganeshotsav',
    description TEXT,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
    target_amount NUMERIC(12, 2) NOT NULL DEFAULT 500000.00,
    per_person_rate NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
    suggested_amount NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    allow_partial_payment BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaigns_org ON public.campaigns(organization_id);

-- 2.16 Households Table
CREATE TABLE IF NOT EXISTS public.households (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id VARCHAR(100) NOT NULL DEFAULT 'cmp_ganesh_2026',
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    head_of_family_name VARCHAR(255) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    village_area VARCHAR(255) NOT NULL,
    family_member_count INT NOT NULL DEFAULT 4,
    per_person_rate_snapshot NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
    amount_received NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_households_campaign ON public.households(campaign_id);
CREATE INDEX IF NOT EXISTS idx_households_org ON public.households(organization_id);

-- ==============================================================================
-- 3. SEED SYSTEM ROLES & PERMISSIONS
-- ==============================================================================

INSERT INTO public.roles (name, role_key, scope_type, is_system_role, description)
VALUES 
    ('Super Admin', 'SUPER_ADMIN', 'system', TRUE, 'System-wide owner with complete authority across all organizations and groups'),
    ('Organization Admin', 'ORG_ADMIN', 'organization', TRUE, 'Administrator managing an organization and its associated groups'),
    ('Group Admin', 'GROUP_ADMIN', 'group', TRUE, 'Manager of a specific group, campaigns, and membership'),
    ('Collection Agent', 'COLLECTOR', 'group', TRUE, 'Field agent authorized to record collections and issue receipts'),
    ('Public User', 'PUBLIC_USER', 'system', TRUE, 'Default citizen account with ability to search groups and request membership'),
    ('Viewer', 'VIEWER', 'group', TRUE, 'Read-only access to permitted group collection summaries and transparency records')
ON CONFLICT (role_key) DO UPDATE 
SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO public.permissions (permission_key, module, action, description)
VALUES
    ('organization.view', 'organization', 'view', 'View organization details and dashboard'),
    ('organization.create', 'organization', 'create', 'Create new organizations'),
    ('organization.update', 'organization', 'update', 'Update organization details'),
    ('organization.deactivate', 'organization', 'deactivate', 'Deactivate or archive organizations'),
    ('group.view', 'group', 'view', 'View group details and summary'),
    ('group.create', 'group', 'create', 'Create new groups under an organization'),
    ('group.update', 'group', 'update', 'Update group parameters and settings'),
    ('group.deactivate', 'group', 'deactivate', 'Deactivate or archive groups'),
    ('user.view', 'user', 'view', 'View user profiles and list'),
    ('user.create', 'user', 'create', 'Create or invite new users'),
    ('user.update', 'user', 'update', 'Edit user profile details'),
    ('user.activate', 'user', 'activate', 'Activate a suspended or inactive user'),
    ('user.deactivate', 'user', 'deactivate', 'Suspend or deactivate user accounts'),
    ('role.view', 'role', 'view', 'View system and custom roles'),
    ('role.create', 'role', 'create', 'Create new custom roles (e.g. TREASURER, AUDITOR)'),
    ('role.update', 'role', 'update', 'Edit role parameters and assigned permissions'),
    ('role.assign', 'role', 'assign', 'Assign or revoke roles to users'),
    ('permission.manage', 'permission', 'manage', 'Manage permission matrix mappings'),
    ('member.view', 'member', 'view', 'View group members list'),
    ('member.approve', 'member', 'approve', 'Approve or reject citizen join requests'),
    ('member.remove', 'member', 'remove', 'Remove a member from a group'),
    ('collection.view', 'collection', 'view', 'View group collection transactions'),
    ('collection.create', 'collection', 'create', 'Record a new vargani collection'),
    ('collection.update', 'collection', 'update', 'Edit a collection entry before closure'),
    ('collection.delete', 'collection', 'delete', 'Cancel or void a collection transaction'),
    ('receipt.view', 'receipt', 'view', 'View issued collection receipts'),
    ('receipt.create', 'receipt', 'create', 'Generate and issue collection receipts'),
    ('expense.view', 'expense', 'view', 'View group expenses and proof documents'),
    ('expense.create', 'expense', 'create', 'Record a new expense with receipt proof'),
    ('expense.update', 'expense', 'update', 'Update expense record details'),
    ('expense.delete', 'expense', 'delete', 'Delete or void an expense record'),
    ('report.view', 'report', 'view', 'View financial analytics and export audit summaries'),
    ('complaint.create', 'complaint', 'create', 'Submit a citizen grievance or complaint'),
    ('complaint.view', 'complaint', 'view', 'View submitted complaints and history'),
    ('complaint.resolve', 'complaint', 'resolve', 'Resolve, assign, or respond to grievances'),
    ('audit_log.view', 'audit_log', 'view', 'Inspect immutable audit logs')
ON CONFLICT (permission_key) DO NOTHING;

-- Associate Super Admin with all permissions
DO $$
DECLARE
    r_id UUID;
    p_id UUID;
BEGIN
    SELECT id INTO r_id FROM public.roles WHERE role_key = 'SUPER_ADMIN';
    FOR p_id IN SELECT id FROM public.permissions LOOP
        INSERT INTO public.role_permissions (role_id, permission_id) 
        VALUES (r_id, p_id) ON CONFLICT DO NOTHING;
    END LOOP;
END $$;

-- ==============================================================================
-- 4. SECURITY & AUTHORIZATION HELPER FUNCTIONS
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.auth_is_user_active()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT (account_status = 'active')
    FROM public.profiles
    WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.auth_is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid()
          AND r.role_key = 'SUPER_ADMIN'
    );
$$;

CREATE OR REPLACE FUNCTION public.auth_has_role(p_role_key TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid()
          AND (r.role_key = p_role_key OR r.role_key = 'SUPER_ADMIN')
    );
$$;

CREATE OR REPLACE FUNCTION public.auth_has_permission(
    p_perm_key TEXT,
    p_org_id UUID DEFAULT NULL,
    p_grp_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_has BOOLEAN;
BEGIN
    IF public.auth_is_super_admin() THEN
        RETURN TRUE;
    END IF;

    IF NOT public.auth_is_user_active() THEN
        RETURN FALSE;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.role_permissions rp ON ur.role_id = rp.role_id
        JOIN public.permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = auth.uid()
          AND p.permission_key = p_perm_key
          AND (
              (ur.organization_id IS NULL AND ur.group_id IS NULL)
              OR (p_org_id IS NOT NULL AND ur.organization_id = p_org_id)
              OR (p_grp_id IS NOT NULL AND ur.group_id = p_grp_id)
          )
    ) INTO v_has;

    RETURN COALESCE(v_has, FALSE);
END;
$$;

CREATE OR REPLACE FUNCTION public.auth_user_organization_ids()
RETURNS TABLE(org_id UUID)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT ur.organization_id
    FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND ur.organization_id IS NOT NULL
    UNION
    SELECT g.organization_id
    FROM public.user_roles ur
    JOIN public.groups g ON ur.group_id = g.id
    WHERE ur.user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.auth_user_group_ids()
RETURNS TABLE(grp_id UUID)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT ur.group_id
    FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND ur.group_id IS NOT NULL
    UNION
    SELECT g.id
    FROM public.groups g
    WHERE g.organization_id IN (
        SELECT ur.organization_id
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid()
          AND r.role_key IN ('SUPER_ADMIN', 'ORG_ADMIN')
    )
    UNION
    SELECT gm.group_id
    FROM public.group_members gm
    WHERE gm.user_id = auth.uid()
      AND gm.membership_status = 'active';
$$;

-- ==============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles viewable by self and admins" 
ON public.profiles FOR SELECT 
USING (
    id = auth.uid() 
    OR public.auth_is_super_admin()
    OR public.auth_has_role('ORG_ADMIN')
    OR public.auth_has_role('GROUP_ADMIN')
);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE 
USING (id = auth.uid())
WITH CHECK (
    id = auth.uid() 
    AND account_status = (SELECT account_status FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "Super Admins can manage all profiles" 
ON public.profiles FOR ALL 
USING (public.auth_is_super_admin());

CREATE POLICY "Organizations are viewable by public and authenticated users" 
ON public.organizations FOR SELECT 
USING (status = 'active' OR public.auth_is_super_admin() OR id IN (SELECT org_id FROM public.auth_user_organization_ids()));

CREATE POLICY "Super admins can manage organizations" 
ON public.organizations FOR ALL 
USING (public.auth_is_super_admin());

CREATE POLICY "Groups viewable by everyone if active" 
ON public.groups FOR SELECT 
USING (status = 'active' OR public.auth_is_super_admin() OR id IN (SELECT grp_id FROM public.auth_user_group_ids()));

CREATE POLICY "Admins can manage groups" 
ON public.groups FOR ALL 
USING (
    public.auth_is_super_admin() 
    OR (public.auth_has_role('ORG_ADMIN') AND organization_id IN (SELECT org_id FROM public.auth_user_organization_ids()))
);

CREATE POLICY "Roles viewable by authenticated users" 
ON public.roles FOR SELECT 
TO authenticated 
USING (TRUE);

CREATE POLICY "Super Admins can manage roles" 
ON public.roles FOR ALL 
USING (public.auth_is_super_admin());

CREATE POLICY "Permissions viewable by authenticated users" 
ON public.permissions FOR SELECT 
TO authenticated 
USING (TRUE);

CREATE POLICY "Role permissions viewable by authenticated users" 
ON public.role_permissions FOR SELECT 
TO authenticated 
USING (TRUE);

CREATE POLICY "User roles viewable by self and admins" 
ON public.user_roles FOR SELECT 
USING (
    user_id = auth.uid() 
    OR public.auth_is_super_admin() 
    OR organization_id IN (SELECT org_id FROM public.auth_user_organization_ids())
);

CREATE POLICY "Admins can assign roles" 
ON public.user_roles FOR INSERT 
WITH CHECK (
    public.auth_is_super_admin() 
    OR (
        public.auth_has_role('ORG_ADMIN') 
        AND organization_id IN (SELECT org_id FROM public.auth_user_organization_ids())
        AND role_id NOT IN (SELECT id FROM public.roles WHERE role_key = 'SUPER_ADMIN')
    )
);

CREATE POLICY "Admins can revoke user roles" 
ON public.user_roles FOR DELETE 
USING (
    public.auth_is_super_admin() 
    OR (
        public.auth_has_role('ORG_ADMIN') 
        AND organization_id IN (SELECT org_id FROM public.auth_user_organization_ids())
        AND role_id NOT IN (SELECT id FROM public.roles WHERE role_key = 'SUPER_ADMIN')
    )
);

CREATE POLICY "Group members viewable by group participants" 
ON public.group_members FOR SELECT 
USING (
    user_id = auth.uid() 
    OR public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Group admins can manage members" 
ON public.group_members FOR ALL 
USING (
    public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Users can view their own join requests" 
ON public.join_requests FOR SELECT 
USING (
    user_id = auth.uid() 
    OR public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Citizens can create join requests" 
ON public.join_requests FOR INSERT 
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Group admins can review join requests" 
ON public.join_requests FOR UPDATE 
USING (
    public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Collections viewable by group members" 
ON public.collections FOR SELECT 
USING (
    public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Collectors can insert collections" 
ON public.collections FOR INSERT 
WITH CHECK (
    public.auth_is_super_admin() 
    OR (
        public.auth_has_permission('collection.create', NULL, group_id) 
        AND collected_by = auth.uid()
    )
);

CREATE POLICY "Collectors and Admins can update collections" 
ON public.collections FOR UPDATE 
USING (
    public.auth_is_super_admin() 
    OR public.auth_has_permission('collection.update', NULL, group_id)
);

CREATE POLICY "Receipts viewable by group members and payers" 
ON public.receipts FOR SELECT 
USING (
    public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Authorized issuers can create receipts" 
ON public.receipts FOR INSERT 
WITH CHECK (
    public.auth_is_super_admin() 
    OR public.auth_has_permission('receipt.create', NULL, group_id)
);

CREATE POLICY "Expenses viewable by authorized users and transparency view" 
ON public.expenses FOR SELECT 
USING (
    public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Authorized staff can insert expenses" 
ON public.expenses FOR INSERT 
WITH CHECK (
    public.auth_is_super_admin() 
    OR public.auth_has_permission('expense.create', NULL, group_id)
);

CREATE POLICY "Admins can update expenses" 
ON public.expenses FOR UPDATE 
USING (
    public.auth_is_super_admin() 
    OR public.auth_has_permission('expense.update', NULL, group_id)
);

CREATE POLICY "Complaints viewable by author and staff" 
ON public.complaints FOR SELECT 
USING (
    user_id = auth.uid() 
    OR public.auth_is_super_admin() 
    OR group_id IN (SELECT grp_id FROM public.auth_user_group_ids())
);

CREATE POLICY "Citizens can file complaints" 
ON public.complaints FOR INSERT 
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update complaints" 
ON public.complaints FOR UPDATE 
USING (
    public.auth_is_super_admin() 
    OR public.auth_has_permission('complaint.resolve', NULL, group_id)
);

CREATE POLICY "Audit logs viewable by Super Admins and Org Admins" 
ON public.audit_logs FOR SELECT 
USING (
    public.auth_is_super_admin() 
    OR (public.auth_has_role('ORG_ADMIN') AND organization_id IN (SELECT org_id FROM public.auth_user_organization_ids()))
    OR auth.role() = 'anon'
);

CREATE POLICY "System can record audit logs" 
ON public.audit_logs FOR INSERT 
WITH CHECK (TRUE);

REVOKE UPDATE, DELETE ON public.audit_logs FROM public, anon, authenticated;

-- Campaigns RLS
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Campaigns viewable by all" ON public.campaigns FOR SELECT USING (TRUE);
CREATE POLICY "Admins can manage campaigns" ON public.campaigns FOR ALL USING (TRUE);

-- Households RLS
ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Households viewable by all" ON public.households FOR SELECT USING (TRUE);
CREATE POLICY "Staff can manage households" ON public.households FOR ALL USING (TRUE);

-- ==============================================================================
-- 6. AUTOMATIC AUTH USER PROFILE & ROLE TRIGGER
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_full_name TEXT;
    v_phone TEXT;
    v_public_role_id UUID;
BEGIN
    v_full_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1),
        'User'
    );
    v_phone := COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone', '');

    INSERT INTO public.profiles (id, full_name, email, phone, account_status)
    VALUES (NEW.id, v_full_name, NEW.email, v_phone, 'active')
    ON CONFLICT (id) DO UPDATE 
    SET full_name = EXCLUDED.full_name,
        email = COALESCE(EXCLUDED.email, public.profiles.email),
        phone = COALESCE(NULLIF(EXCLUDED.phone, ''), public.profiles.phone),
        updated_at = NOW();

    SELECT id INTO v_public_role_id FROM public.roles WHERE role_key = 'PUBLIC_USER';
    
    IF v_public_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (NEW.id, v_public_role_id)
        ON CONFLICT DO NOTHING;
    END IF;

    INSERT INTO public.audit_logs (actor_user_id, action, resource_type, resource_id, safe_metadata)
    VALUES (
        NEW.id,
        'user.registered',
        'profiles',
        NEW.id::text,
        jsonb_build_object('email', NEW.email, 'role_assigned', 'PUBLIC_USER')
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- ==============================================================================
-- 7. SUPER ADMIN BOOTSTRAP FUNCTION
-- ==============================================================================

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
    SELECT public.check_super_admin_initialized() INTO v_already_initialized;
    IF v_already_initialized THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_code', 'ALREADY_BOOTSTRAPPED',
            'message', 'Super Admin bootstrap has already been executed. Repeat initialization is strictly disabled.'
        );
    END IF;

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

    SELECT id INTO v_user_id
    FROM auth.users
    WHERE lower(email) = v_clean_email
    LIMIT 1;

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

    INSERT INTO public.profiles (id, full_name, email, phone, account_status)
    VALUES (v_user_id, COALESCE(p_full_name, 'System Super Administrator'), v_clean_email, v_clean_phone, 'active')
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        account_status = 'active',
        updated_at = NOW();

    INSERT INTO public.user_roles (user_id, role_id, organization_id, group_id, assigned_by)
    VALUES (v_user_id, v_role_id, NULL, NULL, v_user_id)
    ON CONFLICT DO NOTHING;

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

-- =============================================================================
-- 7.3 PERMANENT SUPER ADMIN PROTECTION (9699342811 / Ritesh Sangale)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.protect_permanent_super_admin()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Prevent deleting the primary super admin
    IF (TG_OP = 'DELETE' AND OLD.phone = '9699342811') THEN
        RAISE EXCEPTION 'Primary Super Admin account (9699342811) is permanent and cannot be deleted.';
    END IF;

    -- Prevent deactivating or suspending the primary super admin
    IF (TG_OP = 'UPDATE' AND OLD.phone = '9699342811' AND NEW.account_status != 'active') THEN
        RAISE EXCEPTION 'Primary Super Admin account (9699342811) cannot be deactivated or suspended.';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_permanent_super_admin ON public.profiles;
CREATE TRIGGER trg_protect_permanent_super_admin
BEFORE UPDATE OR DELETE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_permanent_super_admin();

CREATE OR REPLACE FUNCTION public.protect_super_admin_roles()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_phone TEXT;
    v_role_key TEXT;
BEGIN
    SELECT phone INTO v_phone FROM public.profiles WHERE id = OLD.user_id;
    SELECT role_key INTO v_role_key FROM public.roles WHERE id = OLD.role_id;

    IF (v_phone = '9699342811' AND v_role_key = 'SUPER_ADMIN') THEN
        RAISE EXCEPTION 'Primary Super Admin role for 9699342811 is protected and cannot be revoked.';
    END IF;

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_super_admin_roles ON public.user_roles;
CREATE TRIGGER trg_protect_super_admin_roles
BEFORE DELETE OR UPDATE ON public.user_roles
FOR EACH ROW
EXECUTE FUNCTION public.protect_super_admin_roles();

-- =============================================================================
-- 7.4 EMAIL OTP SECURITY TABLE & LOOKUP
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.email_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    otp_hash VARCHAR(128) NOT NULL,
    purpose VARCHAR(100) NOT NULL DEFAULT 'Login Verification',
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_otps_email ON public.email_otps(email);

-- Secure RPC to lookup email by phone for phone OTP login
CREATE OR REPLACE FUNCTION public.lookup_phone_email(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_clean_phone TEXT;
    v_profile RECORD;
BEGIN
    v_clean_phone := regexp_replace(COALESCE(p_phone, ''), '\D', '', 'g');
    IF length(v_clean_phone) >= 10 THEN
        v_clean_phone := right(v_clean_phone, 10);
    END IF;

    SELECT id, email, full_name, phone, account_status
    INTO v_profile
    FROM public.profiles
    WHERE right(regexp_replace(phone, '\D', '', 'g'), 10) = v_clean_phone
    LIMIT 1;

    IF v_profile.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'या मोबाईल क्रमांकाशी जोडलेले खाते सापडले नाही.'
        );
    END IF;

    IF v_profile.account_status != 'active' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'आपले खाते निष्क्रिय (Inactive) आहे. कृपया प्रशासकाशी संपर्क साधा.'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'email', v_profile.email,
        'name', v_profile.full_name,
        'user_id', v_profile.id
    );
END;
$$;


