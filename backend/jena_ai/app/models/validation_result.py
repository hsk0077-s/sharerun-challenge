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
