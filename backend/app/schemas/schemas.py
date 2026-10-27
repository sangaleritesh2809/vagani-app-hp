from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# 1. Household Schemas (SRS Section 5.2 Option A)
class HouseholdCreate(BaseModel):
    campaign_id: str
    head_of_family_name: str
    mobile_number: str
    village_area: str
    family_member_count: int = Field(..., gt=0, description="Family count must be positive integer (BR-02)")

class HouseholdResponse(BaseModel):
    id: str
    campaign_id: str
    head_of_family_name: str
    mobile_number: str
    village_area: str
    family_member_count: int
    per_person_rate_snapshot: float
    amount_received: float
    expected_total: float
    remaining_amount: float
    payment_status: str

# 2. Payment & Receipt Schemas (SRS Section 6 & 7)
class PaymentCreate(BaseModel):
    household_id: str
    campaign_id: str
    amount: float = Field(..., gt=0)
    payment_type: str = Field(..., pattern="^(cash|upi|bankTransfer|other)$")
    reference_id: Optional[str] = None
    collected_by_name: str
    received_by_name: str
    remarks: Optional[str] = ""

class ReceiptResponse(BaseModel):
    id: str
    receipt_no: str
    campaign_id: str
    household_head_name: str
    amount_received: float
    payment_type: str
    reference_id: Optional[str] = None
    collected_by_name: str
    received_by_name: str
    is_cancelled: bool
    cancellation_reason: Optional[str] = None

class ReceiptCancelRequest(BaseModel):
    receipt_id: str
    reason: str
    cancelled_by_name: str

# 3. Cash Handover Schemas (SRS Section 6.3)
class HandoverCreate(BaseModel):
    campaign_id: str
    handover_from_name: str
    handover_to_name: str
    amount: float = Field(..., gt=0)
    remarks: Optional[str] = ""

class HandoverProcessRequest(BaseModel):
    handover_id: str
    approve: bool
    confirmed_by_name: str

# 4. Expense Schemas (SRS Section 8)
class ExpenseCreate(BaseModel):
    campaign_id: str
    category: str
    title: str
    amount: float = Field(..., gt=0)
    vendor_payee: str
    payment_mode: str
    bill_number: Optional[str] = "N/A"
    has_proof: bool = False
    is_public_visible: bool = True

class ExpenseApprovalRequest(BaseModel):
    expense_id: str
    status: str = Field(..., pattern="^(approved|rejected)$")
    performed_by_name: str

# 5. Complaint Schemas (SRS Section 10)
class ComplaintCreate(BaseModel):
    campaign_id: str
    type: str
    title: str
    description: str
    submitted_by_name: str
    submitted_by_phone: str

class ComplaintResponseRequest(BaseModel):
    complaint_id: str
    response: str
    status: str
    performed_by_name: str

# 6. Campaign & Rate Update (SRS Section 5.1 & BR-10)
class CampaignRateUpdate(BaseModel):
    new_rate: float = Field(..., gt=0)
    performed_by_name: str

# 7. Transparency & Financial Metrics (SRS Section 9 & 11)
class FinancialSummaryResponse(BaseModel):
    expected_collection: float
    verified_received: float
    remaining_due: float
    approved_expense: float
    actual_paid_expense: float
    calculated_available_balance: float
    cash_breakdown: dict

# 8. Authentication Schemas (SRS Section 3)
class UserRegisterRequest(BaseModel):
    first_name: str
    last_name: str
    phone: str
    password: Optional[str] = None
    password_hash: Optional[str] = None
    role: str = "citizen"
    email: Optional[str] = None

class UserLoginRequest(BaseModel):
    phone: str
    password: Optional[str] = None
    password_hash: Optional[str] = None
    otp: Optional[str] = None
    login_type: str = "password"  # 'password' or 'otp'

class AuthResponse(BaseModel):
    success: bool
    message: str
    user: Optional[dict] = None
    token: Optional[str] = None

# 9. Organization Schemas
class OrganizationCreate(BaseModel):
    name: str
    registration_number: Optional[str] = ""
    contact_person: str
    phone: str
    address: Optional[str] = ""
    village: Optional[str] = ""
    taluka: Optional[str] = ""
    district: Optional[str] = ""
    state: Optional[str] = "Maharashtra"

class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    registration_number: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    village: Optional[str] = None
    taluka: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    status: Optional[str] = None

# 10. Group Schemas
class GroupCreate(BaseModel):
    organization_id: str
    name: str
    code: Optional[str] = None
    description: Optional[str] = ""

class GroupUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None

# 11. Role & Permission Schemas
class RoleCreate(BaseModel):
    code: str
    name: str
    organization_id: Optional[str] = "org_001"
    description: Optional[str] = ""
    permissions: List[str] = []

class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    permissions: Optional[List[str]] = None

# 12. User Management Schemas
class UserCreateAdmin(BaseModel):
    first_name: str
    last_name: str
    phone: str
    email: Optional[str] = None
    password: Optional[str] = "vargani@123"
    role: str = "collector"
    organization_id: str = "org_001"
    group_ids: List[str] = []
    is_active: bool = True

class UserUpdateAdmin(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None
    organization_id: Optional[str] = None
    group_ids: Optional[List[str]] = None
    is_active: Optional[bool] = None

class UserStatusUpdate(BaseModel):
    is_active: bool

# 13. Group Selection Schema
class SelectGroupRequest(BaseModel):
    user_id: str
    group_id: str

