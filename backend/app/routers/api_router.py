from datetime import datetime
import hashlib
import re
import uuid
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.services.vargani_service import vargani_service
from app.schemas.schemas import (
    HouseholdCreate,
    HouseholdResponse,
    PaymentCreate,
    ReceiptResponse,
    ReceiptCancelRequest,
    HandoverCreate,
    HandoverProcessRequest,
    ExpenseCreate,
    ExpenseApprovalRequest,
    ComplaintCreate,
    ComplaintResponseRequest,
    CampaignRateUpdate,
    FinancialSummaryResponse,
    UserRegisterRequest,
    UserLoginRequest,
    AuthResponse,
    OrganizationCreate,
    OrganizationUpdate,
    GroupCreate,
    GroupUpdate,
    RoleCreate,
    RoleUpdate,
    UserCreateAdmin,
    UserUpdateAdmin,
    UserStatusUpdate,
    SelectGroupRequest,
)

api_router = APIRouter()

AUTH_SALT = "vargani_pro_secure_salt_2026"

def hash_password(pwd: str) -> str:
    return hashlib.sha256((pwd + AUTH_SALT).encode("utf-8")).hexdigest()

USER_PASSWORD_HASHES = {
    "9699342811": hash_password("vargani@123"),
    "9822054321": hash_password("admin@123"),
    "9888811111": hash_password("super@123"),
    "9850077889": hash_password("treasurer@123"),
    "9765432100": hash_password("collector@123"),
    "9922144556": hash_password("collector@123"),
    "9823401122": hash_password("citizen@123"),
}

def get_user_by_id(user_id: str) -> Optional[dict]:
    for u in vargani_service.store.get("users", []):
        if u.get("id") == user_id:
            return u
    return None

def get_user_permissions(user: dict) -> List[str]:
    role_code = user.get("role", "citizen")
    if role_code == "superAdmin":
        return ["*"]
    for r in vargani_service.store.get("roles", []):
        if r.get("code") == role_code:
            return r.get("permissions", [])
    return ["households.view", "reports.view"]

def check_permission(actor_id: Optional[str], permission: str) -> bool:
    if not actor_id:
        return True  # fallback if header not passed
    actor = get_user_by_id(actor_id)
    if not actor or not actor.get("is_active", True):
        return False
    perms = get_user_permissions(actor)
    return "*" in perms or permission in perms

# 0. Authentication Endpoints
@api_router.get("/auth/check-phone", tags=["Authentication"])
def check_phone(phone: str = Query(...)):
    clean_phone = re.sub(r"\D", "", phone)[-10:]
    for u in vargani_service.store.get("users", []):
        u_phone = re.sub(r"\D", "", u.get("phone", ""))[-10:]
        if u_phone == clean_phone:
            return {"exists": True, "message": "Mobile number is already registered"}
    return {"exists": False, "message": "Mobile number is available"}

@api_router.post("/auth/register", response_model=AuthResponse, tags=["Authentication"])
def register_user(data: UserRegisterRequest):
    clean_phone = re.sub(r"\D", "", data.phone)[-10:]
    if len(clean_phone) != 10:
        raise HTTPException(status_code=400, detail="कृपया वैध १० अंकी मोबाईल नंबर टाका.")

    if data.role == "superAdmin":
        raise HTTPException(status_code=403, detail="Super Admin भूमिका स्वतःहून घेता येत नाही (Unauthorized role).")

    for u in vargani_service.store.get("users", []):
        u_phone = re.sub(r"\D", "", u.get("phone", ""))[-10:]
        if u_phone == clean_phone:
            raise HTTPException(status_code=400, detail="हा मोबाईल नंबर आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.")

    if data.password_hash:
        hashed = data.password_hash
    elif data.password:
        hashed = hash_password(data.password)
    else:
        raise HTTPException(status_code=400, detail="कृपया पासवर्ड टाका.")

    full_name = f"{data.first_name.strip()} {data.last_name.strip()}".strip()
    new_user = {
        "id": f"usr_{uuid.uuid4().hex[:8]}",
        "name": full_name,
        "phone": clean_phone,
        "email": data.email or f"{clean_phone}@varganipro.in",
        "role": data.role,
        "organizationId": "org_001",
        "organization_id": "org_001",
        "group_ids": ["grp_001"],
        "is_active": True,
        "created_at": datetime.now().isoformat(),
    }
    vargani_service.store.setdefault("users", []).append(new_user)
    USER_PASSWORD_HASHES[clean_phone] = hashed

    return AuthResponse(
        success=True,
        message=f"स्वागत आहे, {full_name}! नोंदणी यशस्वी झाली.",
        user=new_user,
        token=f"tok_{uuid.uuid4().hex}"
    )

@api_router.post("/auth/login", response_model=AuthResponse, tags=["Authentication"])
def login_user(data: UserLoginRequest):
    clean_phone = re.sub(r"\D", "", data.phone)[-10:]
    if len(clean_phone) != 10:
        raise HTTPException(status_code=400, detail="कृपया वैध १० अंकी मोबाईल नंबर टाका.")

    user = None
    for u in vargani_service.store.get("users", []):
        u_phone = re.sub(r"\D", "", u.get("phone", ""))[-10:]
        if u_phone == clean_phone:
            user = u
            break

    if not user:
        raise HTTPException(status_code=404, detail="हा मोबाईल नंबर नोंदणीकृत नाही. कृपया प्रथम नोंदणी करा.")

    # Check Active / Inactive status
    if not user.get("is_active", True):
        raise HTTPException(
            status_code=403,
            detail="खाते निष्क्रिय (Inactive) आहे. कृपया प्रशासकाशी संपर्क साधा."
        )

    # Make sure organizationId / group_ids exist
    user.setdefault("organizationId", user.get("organization_id", "org_001"))
    user.setdefault("group_ids", ["grp_001"])

    if data.login_type == "otp":
        if data.otp in ["992224", "123456"]:
            return AuthResponse(
                success=True,
                message="OTP पडताळणी यशस्वी! लॉगिन झाले.",
                user=user,
                token=f"tok_{uuid.uuid4().hex}"
            )
        else:
            raise HTTPException(status_code=401, detail="चुकीचा OTP! कृपया 992224 प्रविष्ट करा.")

    incoming_hash = data.password_hash or (hash_password(data.password) if data.password else None)
    stored_hash = USER_PASSWORD_HASHES.get(clean_phone)

    if not stored_hash or incoming_hash != stored_hash:
        raise HTTPException(status_code=401, detail="चुकीचा पासवर्ड! कृपया पुन्हा तपासा.")

    return AuthResponse(
        success=True,
        message=f"स्वागत आहे, {user.get('name')}! लॉगिन यशस्वी झाले.",
        user=user,
        token=f"tok_{uuid.uuid4().hex}"
    )

# 1. Healthcheck
@api_router.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "service": "Vargani Pro FastAPI & Supabase Backend",
        "version": "1.0.0",
    }

# 2. Organization Management (Super Admin & PBAC)
@api_router.get("/organization", tags=["Organization"])
def get_organization():
    return vargani_service.store.get("organization")

@api_router.get("/organizations", tags=["Organization"])
def list_organizations():
    return vargani_service.store.get("organizations", [vargani_service.store.get("organization")])

@api_router.get("/organizations/{org_id}", tags=["Organization"])
def get_organization_by_id(org_id: str):
    orgs = vargani_service.store.get("organizations", [])
    for o in orgs:
        if o.get("id") == org_id:
            return o
    if vargani_service.store.get("organization", {}).get("id") == org_id:
        return vargani_service.store.get("organization")
    raise HTTPException(status_code=404, detail="Organization not found")

@api_router.post("/organizations", tags=["Organization"])
def create_organization(data: OrganizationCreate, actor_id: Optional[str] = Query(None)):
    if actor_id:
        actor = get_user_by_id(actor_id)
        if not actor or actor.get("role") != "superAdmin":
            raise HTTPException(status_code=403, detail="फक्त Super Admin ला नवीन संस्था तयार करण्याची परवानगी आहे (Access Denied).")

    new_id = f"org_{str(len(vargani_service.store.get('organizations', [])) + 1).zfill(3)}"
    new_org = {
        "id": new_id,
        "name": data.name,
        "registration_number": data.registration_number or f"MH/2026/PUN/{new_id[-3:]}",
        "contact_person": data.contact_person,
        "phone": data.phone,
        "address": data.address,
        "village": data.village or "Pune",
        "taluka": data.taluka or "Haveli",
        "district": data.district or "Pune",
        "state": data.state or "Maharashtra",
        "status": "Active",
    }
    vargani_service.store.setdefault("organizations", []).append(new_org)

    # Seed default group for this new organization
    new_grp = {
        "id": f"grp_{uuid.uuid4().hex[:6]}",
        "organization_id": new_id,
        "name": f"{data.name} Central Group",
        "code": f"GRP-{new_id.upper()}-01",
        "description": "Primary branch & committee jurisdiction",
        "status": "Active",
    }
    vargani_service.store.setdefault("groups", []).append(new_grp)

    return new_org

@api_router.put("/organizations/{org_id}", tags=["Organization"])
def update_organization(org_id: str, data: OrganizationUpdate, actor_id: Optional[str] = Query(None)):
    if actor_id:
        actor = get_user_by_id(actor_id)
        if not actor or (actor.get("role") != "superAdmin" and actor.get("role") != "orgAdmin"):
            raise HTTPException(status_code=403, detail="संस्था माहिती बदलण्याची परवानगी नाही.")

    orgs = vargani_service.store.get("organizations", [])
    target = None
    for o in orgs:
        if o.get("id") == org_id:
            target = o
            break
    if not target:
        if vargani_service.store.get("organization", {}).get("id") == org_id:
            target = vargani_service.store.get("organization")

    if not target:
        raise HTTPException(status_code=404, detail="Organization not found")

    for k, v in data.dict(exclude_unset=True).items():
        if v is not None:
            target[k] = v

    return target

# 3. Group Management & Selection Flow
@api_router.get("/groups", tags=["Groups"])
def list_groups(organization_id: Optional[str] = Query(None)):
    groups = vargani_service.store.get("groups", [])
    if organization_id:
        return [g for g in groups if g.get("organization_id") == organization_id]
    return groups

@api_router.post("/groups", tags=["Groups"])
def create_group(data: GroupCreate, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "groups.manage"):
        raise HTTPException(status_code=403, detail="गट तयार करण्याची परवानगी नाही (Access Denied).")

    new_id = f"grp_{uuid.uuid4().hex[:6]}"
    new_group = {
        "id": new_id,
        "organization_id": data.organization_id,
        "name": data.name,
        "code": data.code or f"GRP-{uuid.uuid4().hex[:4].upper()}",
        "description": data.description,
        "status": "Active",
    }
    vargani_service.store.setdefault("groups", []).append(new_group)
    return new_group

@api_router.put("/groups/{group_id}", tags=["Groups"])
def update_group(group_id: str, data: GroupUpdate, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "groups.manage"):
        raise HTTPException(status_code=403, detail="गट सुधारण्याची परवानगी नाही.")

    group = next((g for g in vargani_service.store.get("groups", []) if g["id"] == group_id), None)
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    for k, v in data.dict(exclude_unset=True).items():
        if v is not None:
            group[k] = v
    return group

@api_router.post("/auth/select-group", tags=["Authentication"])
def select_group(data: SelectGroupRequest):
    user = get_user_by_id(data.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.get("is_active", True):
        raise HTTPException(status_code=403, detail="खाते निष्क्रिय (Inactive) आहे.")

    group = next((g for g in vargani_service.store.get("groups", []) if g["id"] == data.group_id), None)
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Validate Group Access Authorization
    user_role = user.get("role", "citizen")
    user_groups = user.get("group_ids", [])
    user_org = user.get("organization_id", "org_001")

    # SuperAdmin has access to all groups. OrgAdmin has access to all groups in their org.
    # Regular users can only access explicitly assigned groups.
    is_authorized = (
        user_role == "superAdmin"
        or (user_role == "orgAdmin" and group.get("organization_id") == user_org)
        or (data.group_id in user_groups)
    )

    if not is_authorized:
        raise HTTPException(
            status_code=403,
            detail="या गटामध्ये प्रवेश करण्याची परवानगी नाही (Unauthorized Group Access)."
        )

    permissions = get_user_permissions(user)
    return {
        "success": True,
        "message": f"गट '{group.get('name')}' निवडला आहे.",
        "group": group,
        "user_id": user["id"],
        "role": user_role,
        "permissions": permissions,
    }

# 4. Roles & Permissions Management
@api_router.get("/permissions", tags=["Roles & Permissions"])
def list_permissions():
    return vargani_service.store.get("permissions", [])

@api_router.get("/roles", tags=["Roles & Permissions"])
def list_roles(organization_id: Optional[str] = Query(None)):
    roles = vargani_service.store.get("roles", [])
    if organization_id:
        return [r for r in roles if r.get("organization_id") in [organization_id, None]]
    return roles

@api_router.post("/roles", tags=["Roles & Permissions"])
def create_role(data: RoleCreate, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "roles.manage"):
        raise HTTPException(status_code=403, detail="भूमिका व्यवस्थापनाची परवानगी नाही.")

    if data.code == "superAdmin":
        raise HTTPException(status_code=403, detail="Super Admin भूमिका नव्याने तयार करता येत नाही.")

    for r in vargani_service.store.get("roles", []):
        if r["code"].lower() == data.code.lower():
            raise HTTPException(status_code=400, detail="ही भूमिका आधीच अस्तित्वात आहे.")

    new_role = {
        "id": f"role_{uuid.uuid4().hex[:6]}",
        "code": data.code,
        "name": data.name,
        "organization_id": data.organization_id,
        "is_system": False,
        "description": data.description,
        "permissions": data.permissions,
    }
    vargani_service.store.setdefault("roles", []).append(new_role)
    return new_role

@api_router.put("/roles/{role_id}", tags=["Roles & Permissions"])
def update_role(role_id: str, data: RoleUpdate, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "roles.manage"):
        raise HTTPException(status_code=403, detail="भूमिका सुधारण्याची परवानगी नाही.")

    role = next((r for r in vargani_service.store.get("roles", []) if r["id"] == role_id), None)
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")

    if role.get("code") == "superAdmin":
        raise HTTPException(status_code=403, detail="Super Admin भूमिकेच्या परवानग्या बदलता येत नाहीत.")

    for k, v in data.dict(exclude_unset=True).items():
        if v is not None:
            role[k] = v
    return role

# 5. User Management (Active/Inactive, Profile, Roles)
@api_router.get("/users", tags=["Users"])
def get_users(organization_id: Optional[str] = Query(None)):
    users = vargani_service.store.get("users", [])
    if organization_id:
        return [u for u in users if u.get("organization_id") in [organization_id, "org_001"]]
    return users

@api_router.post("/users", tags=["Users"])
def create_user_by_admin(data: UserCreateAdmin, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "users.create"):
        raise HTTPException(status_code=403, detail="वापरकर्ता तयार करण्याची परवानगी नाही.")

    # Rule 1 & 5: Prevent unauthorized creation of additional Super Admin accounts
    if data.role == "superAdmin":
        raise HTTPException(
            status_code=403,
            detail="सिस्टममध्ये फक्त १ Super Admin असू शकतो. अतिरिक्त Super Admin तयार करण्यास सक्त मनाई आहे."
        )

    clean_phone = re.sub(r"\D", "", data.phone)[-10:]
    for u in vargani_service.store.get("users", []):
        u_phone = re.sub(r"\D", "", u.get("phone", ""))[-10:]
        if u_phone == clean_phone:
            raise HTTPException(status_code=400, detail="हा मोबाईल नंबर आधीच अस्तित्वात आहे.")

    new_id = f"usr_{uuid.uuid4().hex[:8]}"
    full_name = f"{data.first_name.strip()} {data.last_name.strip()}".strip()
    new_user = {
        "id": new_id,
        "name": full_name,
        "phone": clean_phone,
        "email": data.email or f"{clean_phone}@varganipro.in",
        "role": data.role,
        "organizationId": data.organization_id,
        "organization_id": data.organization_id,
        "group_ids": data.group_ids if data.group_ids else ["grp_001"],
        "is_active": data.is_active,
        "created_at": datetime.now().isoformat(),
    }
    vargani_service.store.setdefault("users", []).append(new_user)
    USER_PASSWORD_HASHES[clean_phone] = hash_password(data.password or "vargani@123")
    return new_user

@api_router.put("/users/{user_id}", tags=["Users"])
def update_user_by_admin(user_id: str, data: UserUpdateAdmin, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "users.edit"):
        raise HTTPException(status_code=403, detail="वापरकर्ता माहिती सुधारण्याची परवानगी नाही.")

    target = get_user_by_id(user_id)
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    # Prevent assigning Super Admin role to regular users
    if data.role == "superAdmin" and target.get("role") != "superAdmin":
        raise HTTPException(status_code=403, detail="Super Admin भूमिका इतरांना देता येत नाही.")

    # Prevent demoting the single Super Admin
    if target.get("id") == "usr_super" and data.role is not None and data.role != "superAdmin":
        raise HTTPException(status_code=403, detail="मूळ Super Admin ची भूमिका बदलता येत नाही.")

    for k, v in data.dict(exclude_unset=True).items():
        if v is not None:
            target[k] = v
            if k == "organization_id":
                target["organizationId"] = v

    return target

@api_router.put("/users/{user_id}/status", tags=["Users"])
def toggle_user_status(user_id: str, data: UserStatusUpdate, actor_id: Optional[str] = Query(None)):
    if actor_id and not check_permission(actor_id, "users.manage"):
        raise HTTPException(status_code=403, detail="वापरकर्ता स्थिती बदलण्याची परवानगी नाही.")

    target = get_user_by_id(user_id)
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    if target.get("id") == "usr_super" and not data.is_active:
        raise HTTPException(status_code=403, detail="Super Admin खाते निष्क्रिय करता येत नाही.")

    target["is_active"] = data.is_active
    return {
        "success": True,
        "message": f"वापरकर्ता स्थिती {'सक्रिय (Active)' if data.is_active else 'निष्क्रिय (Inactive)'} करण्यात आली आहे.",
        "user_id": user_id,
        "is_active": data.is_active,
    }

# 6. User Profile (Database-backed)
@api_router.get("/user/profile", tags=["User Profile"])
def get_user_profile(user_id: str = Query(...)):
    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User profile not found")

    org_id = user.get("organization_id", "org_001")
    org = next((o for o in vargani_service.store.get("organizations", []) if o["id"] == org_id), None)
    if not org:
        org = vargani_service.store.get("organization")

    user_groups = [
        g for g in vargani_service.store.get("groups", [])
        if g.get("id") in user.get("group_ids", []) or user.get("role") in ["superAdmin", "orgAdmin"]
    ]

    permissions = get_user_permissions(user)

    return {
        "user": user,
        "organization": org,
        "authorized_groups": user_groups,
        "permissions": permissions,
        "is_active": user.get("is_active", True),
    }

@api_router.put("/user/profile", tags=["User Profile"])
def update_user_profile(user_id: str = Query(...), name: Optional[str] = None, email: Optional[str] = None, phone: Optional[str] = None):
    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User profile not found")

    if name:
        user["name"] = name.strip()
    if email:
        user["email"] = email.strip()
    if phone:
        clean = re.sub(r"\D", "", phone)[-10:]
        if len(clean) == 10:
            user["phone"] = clean

    return {"success": True, "message": "Profile updated successfully", "user": user}


@api_router.get("/campaigns", tags=["Campaigns"])
def list_campaigns():
    return vargani_service.store["campaigns"]

@api_router.post("/campaigns/{campaign_id}/rate", tags=["Campaigns"])
def update_campaign_rate(campaign_id: str, data: CampaignRateUpdate):
    campaign = vargani_service.get_campaign(campaign_id)
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    old_rate = campaign["per_person_rate"]
    campaign["per_person_rate"] = data.new_rate
    vargani_service.store["audit_logs"].insert(0, {
        "action": "UPDATE_RATE",
        "performed_by_name": data.performed_by_name,
        "details": f"Updated campaign rate from Rs. {old_rate} to Rs. {data.new_rate}. Past rates preserved (BR-10)."
    })
    return {"message": "Rate updated successfully", "new_rate": data.new_rate}

# 3. Households (SRS Section 5.2 Option A)
@api_router.get("/households", response_model=List[HouseholdResponse], tags=["Households"])
def get_households(campaign_id: str = Query("cmp_ganesh_2026")):
    return vargani_service.get_households(campaign_id)

@api_router.post("/households", response_model=HouseholdResponse, tags=["Households"])
def register_household(data: HouseholdCreate):
    return vargani_service.register_household(data)

# 4. Collections & Digital Receipts (SRS Section 6 & 7)
@api_router.get("/collections", tags=["Collections"])
def get_collections(campaign_id: str = Query("cmp_ganesh_2026")):
    return [c for c in vargani_service.store["collections"] if c["campaign_id"] == campaign_id]

@api_router.post("/collections", response_model=ReceiptResponse, tags=["Collections"])
def record_payment(data: PaymentCreate):
    return vargani_service.record_payment(data)

@api_router.get("/receipts", response_model=List[ReceiptResponse], tags=["Receipts"])
def get_receipts(campaign_id: str = Query("cmp_ganesh_2026")):
    return [r for r in vargani_service.store["receipts"] if r["campaign_id"] == campaign_id]

@api_router.post("/receipts/cancel", response_model=ReceiptResponse, tags=["Receipts"])
def cancel_receipt(data: ReceiptCancelRequest):
    result = vargani_service.cancel_receipt(data.receipt_id, data.reason, data.cancelled_by_name)
    if not result:
        raise HTTPException(status_code=400, detail="Receipt not found or already cancelled")
    return result

# 5. Cash Handovers & Ledger (SRS Section 6.3)
@api_router.get("/handovers", tags=["Cash Handovers"])
def get_handovers(campaign_id: str = Query("cmp_ganesh_2026")):
    return [h for h in vargani_service.store["handovers"] if h["campaign_id"] == campaign_id]

@api_router.post("/handovers", tags=["Cash Handovers"])
def submit_handover(data: HandoverCreate):
    return vargani_service.submit_handover(data)

@api_router.post("/handovers/process", tags=["Cash Handovers"])
def process_handover(data: HandoverProcessRequest):
    result = vargani_service.process_handover(data.handover_id, data.approve, data.confirmed_by_name)
    if not result:
        raise HTTPException(status_code=404, detail="Handover record not found")
    return result

# 6. Expenses (SRS Section 8)
@api_router.get("/expenses", tags=["Expenses"])
def get_expenses(campaign_id: str = Query("cmp_ganesh_2026")):
    return [e for e in vargani_service.store["expenses"] if e["campaign_id"] == campaign_id]

@api_router.post("/expenses", tags=["Expenses"])
def add_expense(data: ExpenseCreate):
    exp = data.dict()
    exp["id"] = f"exp_{len(vargani_service.store['expenses']) + 1}"
    exp["approval_status"] = "pending"
    exp["payment_status"] = "paid"
    vargani_service.store["expenses"].insert(0, exp)
    return exp

@api_router.post("/expenses/approve", tags=["Expenses"])
def approve_expense(data: ExpenseApprovalRequest):
    exp = next((e for e in vargani_service.store["expenses"] if e["id"] == data.expense_id), None)
    if not exp:
        raise HTTPException(status_code=404, detail="Expense not found")
    exp["approval_status"] = data.status
    return exp

# 7. Public Transparency Portal (SRS Section 9)
@api_router.get("/transparency/summary", response_model=FinancialSummaryResponse, tags=["Transparency"])
def get_transparency_summary(campaign_id: str = Query("cmp_ganesh_2026")):
    return vargani_service.get_financial_summary(campaign_id)

# 8. Complaints & Escalations (SRS Section 10)
@api_router.get("/complaints", tags=["Complaints"])
def get_complaints(campaign_id: str = Query("cmp_ganesh_2026")):
    return [c for c in vargani_service.store["complaints"] if c["campaign_id"] == campaign_id]

@api_router.post("/complaints", tags=["Complaints"])
def submit_complaint(data: ComplaintCreate):
    c = data.dict()
    c["id"] = f"cmp_{len(vargani_service.store['complaints']) + 1}"
    c["status"] = "submitted"
    vargani_service.store["complaints"].insert(0, c)
    return c

@api_router.post("/complaints/respond", tags=["Complaints"])
def respond_complaint(data: ComplaintResponseRequest):
    c = next((item for item in vargani_service.store["complaints"] if item["id"] == data.complaint_id), None)
    if not c:
        raise HTTPException(status_code=404, detail="Complaint not found")
    c["admin_response"] = data.response
    c["status"] = data.status
    return c

# 9. Audit Logs (SRS Section 12 FR-15)
@api_router.get("/audit-logs", tags=["Audit Logs"])
def get_audit_logs():
    return vargani_service.store["audit_logs"]
