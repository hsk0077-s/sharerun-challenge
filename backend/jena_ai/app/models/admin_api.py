from pydantic import BaseModel


class WhoAmIResult(BaseModel):
    uid: str
    email: str | None
    admin: bool


class AuditPingRequest(BaseModel):
    reason: str | None = None


class AuditPingResult(BaseModel):
    accepted: bool
    log_id: str
    action: str
