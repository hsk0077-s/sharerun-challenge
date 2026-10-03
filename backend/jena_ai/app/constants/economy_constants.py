"""Onboarding rewards, referral limits, and daily SRV mining cap."""

SIGNUP_REWARD_SRV = 100
TRIAL_RUNS_REQUIRED = 5
TRIAL_COMPLETION_REWARD_SRV = 500
# Legacy SRV figure. /referrals/apply no longer credits this.
REFERRAL_REWARD_SRV = 300
MAX_REFERRAL_PAYOUTS = 10

# SHARE (wallet.shareBalance). Server transaction + referralPayouts marker only.
REFERRAL_REDEEM_SHARE = 1_000
REFERRAL_TRIAL_REFEREE_SHARE = 5_000
REFERRAL_TRIAL_REFERRER_SHARE = 3_000

DAILY_CAP_KM = 5.0
DAILY_CAP_SRV_TOKENS = 50
SRV_TOKENS_PER_KM = 10

# Weekly practice streak. Once per KST week, same transaction as the ledger row.
STREAK_BONUS_DIA = 10

# Walking challenge harvest: 0.1 SHARE per 10 steps (1 SHARE / 100 steps).
PEDOMETER_SHARE_PER_STEP = 0.01
PEDOMETER_DAILY_HARVEST_SHARE_CAP = 60

# Hall of Fame donation. Server ledger only; the device must not debit VALUE.
HALL_OF_FAME_DONATE_VALUE = 500

# SHARE → DIA. One way. Referral SHARE cannot be exchanged for 30 days.
SHARE_PER_DIA = 120
SHARE_TO_DIA_UNIT = 10
SHARE_TO_DIA_WEEKLY_CAP = 20
SHARE_TO_DIA_SIGNUP_LOCK_DAYS = 7
REFERRAL_SHARE_LOCK_DAYS = 30

# Debug one-shot QA grant. Play Store / release clients never send the
# baked debug-client secret. UID allowlist remains an optional extra gate.
TEST_WALLET_GRANT_AMOUNT = 1_000_000
TEST_WALLET_GRANT_FLAG = "testGrant1mDone"
TEST_WALLET_GRANT_ELIGIBLE_FLAG = "testGrant1mEligible"
TEST_WALLET_GRANT_UIDS: frozenset[str] = frozenset()
# Must match Flutter DebugTestWalletGrantHost.debugClientSecret (kDebugMode).
TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET = "sharerun-debug-test-grant-1m"
