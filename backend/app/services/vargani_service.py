import uuid
from typing import List, Dict, Any, Optional
from app.database import INITIAL_DATA, supabase
from app.schemas.schemas import (
    HouseholdCreate,
    HouseholdResponse,
    PaymentCreate,
    ReceiptResponse,
    HandoverCreate,
    ExpenseCreate,
    ComplaintCreate,
    FinancialSummaryResponse,
)

class VarganiService:
    def __init__(self):
        self.store = INITIAL_DATA

    def get_campaign(self, campaign_id: str) -> Optional[Dict[str, Any]]:
        for c in self.store["campaigns"]:
            if c["id"] == campaign_id:
                return c
        return self.store["campaigns"][0] if self.store["campaigns"] else None

    # 1. Household Logic (Option A - SRS 5.2 & 5.3)
    def register_household(self, data: HouseholdCreate) -> HouseholdResponse:
        campaign = self.get_campaign(data.campaign_id)
        rate = campaign["per_person_rate"] if campaign else 100.0

        hh_id = f"hh_{uuid.uuid4().hex[:8]}"
        record = {
            "id": hh_id,
            "campaign_id": data.campaign_id,
            "head_of_family_name": data.head_of_family_name,
            "mobile_number": data.mobile_number,
            "village_area": data.village_area,
            "family_member_count": data.family_member_count,
            "per_person_rate_snapshot": rate,  # BR-10 rate snapshot
            "amount_received": 0.0,
        }
        self.store["households"].insert(0, record)

        expected = data.family_member_count * rate
        return HouseholdResponse(
            **record,
            expected_total=expected,
            remaining_amount=expected,
            payment_status="Pending",
        )

    def get_households(self, campaign_id: str) -> List[HouseholdResponse]:
        results = []
        for h in self.store["households"]:
            if h["campaign_id"] == campaign_id:
                expected = h["family_member_count"] * h["per_person_rate_snapshot"]
                received = h["amount_received"]
                rem = max(0.0, expected - received)
                status = "Pending" if received <= 0 else ("Paid" if received >= expected else "Partially Paid")
                results.append(HouseholdResponse(
                    **h,
                    expected_total=expected,
                    remaining_amount=rem,
                    payment_status=status,
                ))
        return results

    # 2. Record Payment & Issue Receipt (SRS 6 & 7)
    def record_payment(self, data: PaymentCreate) -> ReceiptResponse:
        pmt_id = f"pmt_{uuid.uuid4().hex[:8]}"
        rcp_id = f"rcp_{uuid.uuid4().hex[:8]}"
        receipt_no = f"VRG-2026-{str(len(self.store['receipts']) + 1).zfill(4)}"

        # Find and update household
        hh = next((h for h in self.store["households"] if h["id"] == data.household_id), None)
        head_name = hh["head_of_family_name"] if hh else "Donor"
        if hh:
            hh["amount_received"] += data.amount

        payment_record = {
            "id": pmt_id,
            "receipt_no": receipt_no,
            "campaign_id": data.campaign_id,
            "household_id": data.household_id,
            "household_head_name": head_name,
            "amount": data.amount,
            "payment_type": data.payment_type,
            "reference_id": data.reference_id,
            "collected_by_name": data.collected_by_name,
            "received_by_name": data.received_by_name,
            "status": "verified",
        }
        self.store["collections"].insert(0, payment_record)

        receipt_record = {
            "id": rcp_id,
            "receipt_no": receipt_no,
            "campaign_id": data.campaign_id,
            "household_head_name": head_name,
            "amount_received": data.amount,
            "payment_type": data.payment_type,
            "reference_id": data.reference_id,
            "collected_by_name": data.collected_by_name,
            "received_by_name": data.received_by_name,
            "is_cancelled": False,
            "cancellation_reason": None,
        }
        self.store["receipts"].insert(0, receipt_record)

        self.store["audit_logs"].insert(0, {
            "id": f"aud_{uuid.uuid4().hex[:8]}",
            "action": "RECORD_PAYMENT",
            "performed_by_name": data.collected_by_name,
            "details": f"Recorded Rs. {data.amount} ({data.payment_type}) for {head_name}. Receipt: {receipt_no}",
        })

        return ReceiptResponse(**receipt_record)

    # 3. Cancel Receipt (SRS 7: Non-destructive, marks cancelled)
    def cancel_receipt(self, receipt_id: str, reason: str, user_name: str) -> Optional[ReceiptResponse]:
        rcp = next((r for r in self.store["receipts"] if r["id"] == receipt_id), None)
        if not rcp or rcp["is_cancelled"]:
            return None

        rcp["is_cancelled"] = True
        rcp["cancellation_reason"] = reason

        self.store["audit_logs"].insert(0, {
            "id": f"aud_{uuid.uuid4().hex[:8]}",
            "action": "CANCEL_RECEIPT",
            "performed_by_name": user_name,
            "details": f"Cancelled receipt {rcp['receipt_no']} for Rs. {rcp['amount_received']}. Reason: {reason}",
        })
        return ReceiptResponse(**rcp)

    # 4. Cash Handover (SRS 6.3)
    def submit_handover(self, data: HandoverCreate) -> Dict[str, Any]:
        h_id = f"hnd_{uuid.uuid4().hex[:8]}"
        record = {
            "id": h_id,
            "campaign_id": data.campaign_id,
            "handover_from_name": data.handover_from_name,
            "handover_to_name": data.handover_to_name,
            "amount": data.amount,
            "remarks": data.remarks,
            "status": "pending",
        }
        self.store["handovers"].insert(0, record)
        return record

    def process_handover(self, handover_id: str, approve: bool, user_name: str) -> Optional[Dict[str, Any]]:
        h = next((item for item in self.store["handovers"] if item["id"] == handover_id), None)
        if not h:
            return None
        h["status"] = "confirmed" if approve else "rejected"
        return h

    # 5. Financial Summary (SRS 9 & 11)
    def get_financial_summary(self, campaign_id: str) -> FinancialSummaryResponse:
        households = [h for h in self.store["households"] if h["campaign_id"] == campaign_id]
        collections = [p for p in self.store["collections"] if p["campaign_id"] == campaign_id]
        expenses = [e for e in self.store["expenses"] if e["campaign_id"] == campaign_id]

        expected = sum(h["family_member_count"] * h["per_person_rate_snapshot"] for h in households)
        verified_received = sum(p["amount"] for p in collections)
        remaining = max(0.0, expected - verified_received)

        approved_expenses = sum(e["amount"] for e in expenses if e["approval_status"] == "approved")
        actual_paid = sum(e["amount"] for e in expenses if e["approval_status"] == "approved" and e.get("payment_status") == "paid")
        balance = verified_received - actual_paid

        cash_breakdown = {
            "cash": sum(p["amount"] for p in collections if p["payment_type"] == "cash"),
            "upi": sum(p["amount"] for p in collections if p["payment_type"] == "upi"),
            "bankTransfer": sum(p["amount"] for p in collections if p["payment_type"] == "bankTransfer"),
        }

        return FinancialSummaryResponse(
            expected_collection=expected,
            verified_received=verified_received,
            remaining_due=remaining,
            approved_expense=approved_expenses,
            actual_paid_expense=actual_paid,
            calculated_available_balance=balance,
            cash_breakdown=cash_breakdown,
        )

vargani_service = VarganiService()
