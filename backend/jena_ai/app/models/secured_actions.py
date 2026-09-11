from pydantic import BaseModel, Field


class JoinTournamentRequest(BaseModel):
    tournament_id: str
    diamond_deposit: int = Field(default=0, ge=0)
    selected_charity: str = Field(default="UNICEF", min_length=2, max_length=64)


class SettleTournamentFailureRequest(BaseModel):
    tournament_id: str
    distance_achieved_km: float = Field(ge=0)


class CollectDiamondBoxRequest(BaseModel):
    box_id: str
    latitude: float
    longitude: float


class RefundRequest(BaseModel):
    share_amount: int = Field(gt=0)


class DebugTestGrantRequest(BaseModel):
    grant_secret: str = ""


class HarvestPedometerRequest(BaseModel):
    claimed_steps: int = Field(ge=0, le=999999)


class WinnerRewardRequest(BaseModel):
    activity_id: str
    action: str = Field(
        pattern="^(winner_reward_claim_all|winner_reward_donate_half|winner_reward_donate_all)$"
    )


class RoutePointPayload(BaseModel):
    latitude: float
    longitude: float
    recordedAt: str


class ValidateRunRequest(BaseModel):
    activity_id: str
    distance_km: float = Field(gt=0)
    duration_seconds: int = Field(gt=0)
    heart_rates: list[int] = Field(default_factory=list)
    cadence_spm: list[int] = Field(default_factory=list)
    gyro_stability_score: float = Field(ge=0, le=1)
    gps_route: list[RoutePointPayload] = Field(default_factory=list)


class ApplyReferralRequest(BaseModel):
    referral_code: str = Field(min_length=4, max_length=16)


class ShopPurchaseRequest(BaseModel):
    item_id: str = Field(min_length=3)


class Web3TransferRequest(BaseModel):
    destination_address: str = Field(
        pattern=r"^0x[a-fA-F0-9]{40}$",
        description="External wallet address (MetaMask, etc.)",
    )
    amount_srv: int = Field(gt=0)
    transfer_channel: str = Field(
        pattern="^(external_wallet|dex)$",
        description="external_wallet for MetaMask, dex for DEX transfer",
    )


class SecuredActionResult(BaseModel):
    accepted: bool
    status: str
    reason: str
    # Optional wallet snapshot so the client can bind Home SHARE without
    # waiting on a Firestore listener, and without rewriting DIA/VALUE.
    share_credited: int = 0
    share_balance: int | None = None
    diamond_balance: int | None = None
    value_token_balance: int | None = None
