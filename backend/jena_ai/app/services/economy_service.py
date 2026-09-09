from dataclasses import dataclass
from datetime import date, datetime, timezone
import hashlib

from app.constants.economy_constants import (
    DAILY_CAP_KM,
    DAILY_CAP_SRV_TOKENS,
    MAX_REFERRAL_PAYOUTS,
    REFERRAL_REWARD_SRV,
    SIGNUP_REWARD_SRV,
    SRV_TOKENS_PER_KM,
    TRIAL_COMPLETION_REWARD_SRV,
    TRIAL_RUNS_REQUIRED,
)


@dataclass(frozen=True)
class DailyMiningAllowance:
    reward_tokens: int
    counted_km: float
    daily_cap_reached: bool


class EconomyService:
    def today_key(self, now: datetime | None = None) -> str:
        current = now or datetime.now(timezone.utc)
        return current.date().isoformat()

    def generate_referral_code(self, uid: str) -> str:
        digest = hashlib.sha256(uid.encode("utf-8")).hexdigest()
        return digest[:8].upper()

    def compute_mining_reward(
        self,
        distance_km: float,
        daily_earned_km: float,
        daily_earned_tokens: int,
    ) -> DailyMiningAllowance:
        remaining_km = max(0.0, DAILY_CAP_KM - daily_earned_km)
        remaining_tokens = max(0, DAILY_CAP_SRV_TOKENS - daily_earned_tokens)
        if remaining_km <= 0 or remaining_tokens <= 0:
            return DailyMiningAllowance(
                reward_tokens=0,
                counted_km=0.0,
                daily_cap_reached=True,
            )

        counted_km = min(distance_km, remaining_km)
        raw_reward = int(counted_km * SRV_TOKENS_PER_KM)
        reward_tokens = min(raw_reward, remaining_tokens)
        if reward_tokens < raw_reward and SRV_TOKENS_PER_KM > 0:
            counted_km = reward_tokens / SRV_TOKENS_PER_KM
        capped = (
            counted_km < distance_km
            or reward_tokens < int(distance_km * SRV_TOKENS_PER_KM)
        )
        return DailyMiningAllowance(
            reward_tokens=reward_tokens,
            counted_km=counted_km,
            daily_cap_reached=capped and reward_tokens == 0,
        )

    def provisional_run_reward(self, distance_km: float) -> int:
        return int(distance_km * SRV_TOKENS_PER_KM)

    def should_count_trial_run(self, economy: dict) -> bool:
        return not bool(economy.get("trialMilestoneRewardClaimed"))

    def next_trial_run_count(self, economy: dict) -> int:
        return int(economy.get("trialRunCount") or 0) + 1

    def trial_milestone_reached(self, trial_run_count: int) -> bool:
        return trial_run_count >= TRIAL_RUNS_REQUIRED

    def signup_reward_amount(self) -> int:
        return SIGNUP_REWARD_SRV

    def trial_completion_reward_amount(self) -> int:
        return TRIAL_COMPLETION_REWARD_SRV

    def referral_reward_amount(self) -> int:
        return REFERRAL_REWARD_SRV

    def can_pay_referrer(self, referrer_economy: dict) -> bool:
        payout_count = int(referrer_economy.get("referralPayoutCount") or 0)
        return payout_count < MAX_REFERRAL_PAYOUTS

    def normalize_daily_mining(self, daily_mining: dict | None, today: str) -> dict:
        daily_mining = daily_mining or {}
        if daily_mining.get("dateKey") != today:
            return {"dateKey": today, "earnedKm": 0.0, "earnedSrvTokens": 0}
        return {
            "dateKey": today,
            "earnedKm": float(daily_mining.get("earnedKm") or 0),
            "earnedSrvTokens": int(daily_mining.get("earnedSrvTokens") or 0),
        }
