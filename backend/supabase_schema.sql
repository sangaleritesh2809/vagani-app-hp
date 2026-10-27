-- ==============================================================================
-- VARGANI PRO (वर्गणी) - SUPABASE POSTGRESQL SCHEMA
-- According to Software Requirements Specification (SRS v1.0)
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Organizations Table (SRS Section 4)
CREATE TABLE IF NOT EXISTS organizations (
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
    registration_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1b. Groups / Mandals Table
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1c. Permissions Table
CREATE TABLE IF NOT EXISTS permissions (
    code VARCHAR(100) PRIMARY KEY,
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT NOT NULL
);

-- 1d. Roles Table (Dynamic RBAC)
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    is_system BOOLEAN DEFAULT FALSE,
    description TEXT,
    permissions TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Users Table with Roles, Groups, and Active/Inactive Status
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255),
    role VARCHAR(50) NOT NULL,
    group_ids TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Campaigns Table (SRS Section 4 & 5)
CREATE TABLE IF NOT EXISTS campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
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

-- 4. Households Table (SRS Section 5.2 Option A)
CREATE TABLE IF NOT EXISTS households (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    head_of_family_name VARCHAR(255) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    village_area VARCHAR(255) NOT NULL,
    family_member_count INT NOT NULL CHECK (family_member_count > 0),
    per_person_rate_snapshot NUMERIC(10, 2) NOT NULL, -- Preserves rate at time of creation (BR-10)
    amount_received NUMERIC(12, 2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Collections / Payments Table (SRS Section 6)
CREATE TABLE IF NOT EXISTS collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_no VARCHAR(50) NOT NULL UNIQUE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_type VARCHAR(50) NOT NULL CHECK (payment_type IN ('cash', 'upi', 'bankTransfer', 'other')),
    reference_id VARCHAR(100),
    collected_by_id UUID NOT NULL REFERENCES users(id),
    received_by_id UUID NOT NULL REFERENCES users(id),
    verification_status VARCHAR(50) DEFAULT 'verified',
    collection_date_time TIMESTAMPTZ DEFAULT NOW(),
    remarks TEXT
);

-- 6. Receipts Table (SRS Section 7)
CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_no VARCHAR(50) NOT NULL UNIQUE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    amount_received NUMERIC(12, 2) NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
    reference_id VARCHAR(100),
    collected_by_name VARCHAR(255) NOT NULL,
    received_by_name VARCHAR(255) NOT NULL,
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    cancelled_by_name VARCHAR(255),
    cancelled_at TIMESTAMPTZ
);

-- 7. Cash Handovers Table (SRS Section 6.3)
CREATE TABLE IF NOT EXISTS cash_handovers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    handover_from_id UUID NOT NULL REFERENCES users(id),
    handover_to_id UUID NOT NULL REFERENCES users(id),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    date_time TIMESTAMPTZ DEFAULT NOW(),
    remarks TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
    confirmed_by_id UUID REFERENCES users(id),
    confirmed_at TIMESTAMPTZ
);

-- 8. Expenses Table (SRS Section 8)
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    date DATE NOT NULL,
    vendor_payee VARCHAR(255) NOT NULL,
    payment_mode VARCHAR(50) NOT NULL,
    bill_number VARCHAR(100),
    has_proof BOOLEAN DEFAULT FALSE,
    attachment_url TEXT,
    entered_by_id UUID NOT NULL REFERENCES users(id),
    approval_status VARCHAR(50) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    payment_status VARCHAR(50) DEFAULT 'paid' CHECK (payment_status IN ('unpaid', 'partiallyPaid', 'paid')),
    is_public_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Complaints Table (SRS Section 10)
CREATE TABLE IF NOT EXISTS complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    submitted_by_id UUID NOT NULL REFERENCES users(id),
    submitted_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'submitted',
    admin_response TEXT,
    resolution_notes TEXT,
    resolved_date TIMESTAMPTZ,
    is_escalated BOOLEAN DEFAULT FALSE
);

-- 10. Audit Logs Table (SRS Section 12 FR-15)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    performed_by_id UUID NOT NULL REFERENCES users(id),
    performed_by_name VARCHAR(255) NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    details TEXT NOT NULL
);

-- Indexes for lightning fast queries
CREATE INDEX IF NOT EXISTS idx_households_campaign ON households(campaign_id);
CREATE INDEX IF NOT EXISTS idx_collections_campaign ON collections(campaign_id);
CREATE INDEX IF NOT EXISTS idx_receipts_receipt_no ON receipts(receipt_no);
CREATE INDEX IF NOT EXISTS idx_handovers_from_user ON cash_handovers(handover_from_id);
CREATE INDEX IF NOT EXISTS idx_expenses_campaign ON expenses(campaign_id);
CREATE INDEX IF NOT EXISTS idx_complaints_campaign ON complaints(campaign_id);
