from pydantic import BaseModel


class ValidationResult(BaseModel):
    verified: bool
    decision: str
    reason: str
    # Machine-readable. The app maps this to plain Korean.
    reason_code: str = ""
    value_token_reward: int
    daily_cap_applied: bool = False
    trial_run_count: int | None = None
    trial_milestone_reached: bool = False
    forfeit_deposit: bool = False


_DECISION_REASON_CODES = {
    "verified": "verified",
    "rejected_kickboard": "kickboard",
    "rejected_bike": "bike",
}


def with_reason_code(result: ValidationResult) -> ValidationResult:
    """Fill a reason code only when an older result omitted one."""
    if (result.reason_code or "").strip():
        return result
    code = _DECISION_REASON_CODES.get(result.decision or "", "")
    if not code:
        return result
    return result.model_copy(update={"reason_code": code})
