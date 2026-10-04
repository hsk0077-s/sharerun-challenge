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
    # Set only by kDebugMode Flutter clients. Release/profile never send this.
    debug_client: bool = False


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


class CrewSpendRequest(BaseModel):
    action: str = Field(min_length=3, max_length=16)


class CrewFoundRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)


class NicknameChangeRequest(BaseModel):
    nickname: str = Field(min_length=2, max_length=12)


class CreateChallengeRoomRequest(BaseModel):
    title: str = Field(min_length=1, max_length=80)
    distance_km: int = Field(ge=1, le=200)


class CoachPlusActivateRequest(BaseModel):
    product_id: str = Field(min_length=3)


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


class InviteCodeResult(BaseModel):
    referral_code: str


class RedeemReferralRequest(BaseModel):
    code: str = Field(min_length=1, max_length=32)


class RedeemReferralResult(BaseModel):
    referred_by: str
    code: str


class ShareToDiaRequest(BaseModel):
    dia_amount: int = Field(gt=0, le=20)


class ShopCatalogItem(BaseModel):
    id: str
    title: str
    diamond_cost: int


class ShopCatalogView(BaseModel):
    items: list[ShopCatalogItem]


class DiaPackGrantRequest(BaseModel):
    product_id: str = Field(min_length=3)
    purchase_token: str = Field(min_length=8, max_length=4096)


class ShareToDiaView(BaseModel):
    accepted: bool
    status: str
    reason: str
    rate_share_per_dia: int = 120
    unit_dia: int = 10
    weekly_cap_dia: int = 20
    remaining_dia: int = 0
    spendable_share: int = 0
    locked_share: int = 0
    lock_reason: str | None = None
    share_balance: int | None = None
    diamond_balance: int | None = None
    value_token_balance: int | None = None


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


class CreateChallengeRoomResult(SecuredActionResult):
    tournament_id: str
    entry_fee_share: int
