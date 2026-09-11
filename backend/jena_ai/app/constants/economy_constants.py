"""Onboarding rewards, referral limits, and daily SRV mining cap."""

SIGNUP_REWARD_SRV = 100
TRIAL_RUNS_REQUIRED = 5
TRIAL_COMPLETION_REWARD_SRV = 500
REFERRAL_REWARD_SRV = 300
MAX_REFERRAL_PAYOUTS = 10

DAILY_CAP_KM = 5.0
DAILY_CAP_SRV_TOKENS = 50
SRV_TOKENS_PER_KM = 10

# Walking challenge harvest: 0.1 SHARE per 10 steps (1 SHARE / 100 steps).
PEDOMETER_SHARE_PER_STEP = 0.01
PEDOMETER_DAILY_HARVEST_SHARE_CAP = 60

# Debug one-shot QA grant. Empty UID allowlist = nobody, including debug builds.
TEST_WALLET_GRANT_AMOUNT = 1_000_000
TEST_WALLET_GRANT_FLAG = "testGrant1mDone"
TEST_WALLET_GRANT_ELIGIBLE_FLAG = "testGrant1mEligible"
# Put the tester Firebase Auth UID(s) here. Leave empty so other users never get it.
TEST_WALLET_GRANT_UIDS: frozenset[str] = frozenset()
