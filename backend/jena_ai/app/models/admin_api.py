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


class ReferralPayoutMarker(BaseModel):
    amount: int
    createdAt: str | None
    payeeUid: str | None


class ReferralPayouts(BaseModel):
    redeem: ReferralPayoutMarker | None
    trial_referee: ReferralPayoutMarker | None
    trial_referrer: ReferralPayoutMarker | None


class ReferralUserRow(BaseModel):
    uid: str
    referralCode: str | None
    referredBy: str | None
    referredByUid: str | None
    trialRunCount: int
    trialRunsRequired: int
    referralPayoutCount: int
    referralPayoutMax: int
    payouts: ReferralPayouts


class ReferralListResult(BaseModel):
    users: list[ReferralUserRow]
    nextCursor: str | None
    limit: int


class DailyStepRow(BaseModel):
    uid: str
    day: str
    steps: int
    source: str | None
    lastHealth: int | None
    updatedAt: str | None
    anomaly: bool


class DailyStepsResult(BaseModel):
    start: str
    end: str
    uid: str | None
    truncated: bool
    rows: list[DailyStepRow]


class WalletAnomalyRow(BaseModel):
    uid: str
    reason: str
    detail: str
    shareBalance: int | None = None
    diamondBalance: int | None = None
    valueTokenBalance: int | None = None
    receiptId: str | None = None
    amount: int | None = None
    assetType: str | None = None


class WalletAnomalyListResult(BaseModel):
    rows: list[WalletAnomalyRow]
    nextCursor: str | None
    limit: int
    truncated: bool


class WalletLedgerEntry(BaseModel):
    id: str
    timeKst: str | None
    type: str
    currency: str
    amount: int
    relatedId: str | None


class WalletLedgerCurrency(BaseModel):
    currency: str
    balance: int
    ledgerSum: int
    mismatch: bool
    seedGap: bool


class WalletLedgerResult(BaseModel):
    uid: str
    nickname: str | None
    email: str | None
    truncated: bool
    currencies: list[WalletLedgerCurrency]
    entries: list[WalletLedgerEntry]
