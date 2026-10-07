from pydantic import BaseModel


class ValidationResult(BaseModel):
    verified: bool
    decision: str
    reason: str
    # Machine-readable. The app can map this later; this response does not
    # change any screen.
    reason_code: str = ""
    value_token_reward: int
    daily_cap_applied: bool = False
    trial_run_count: int | None = None
    trial_milestone_reached: bool = False
    forfeit_deposit: bool = False
    # Company won recorded for this run. The phone displays this and does not
    # multiply kilometres itself. The monthly cap is a later change.
    company_donation_won: int = 0
    donation_counted: bool = False
    donation_reason: str = ""
