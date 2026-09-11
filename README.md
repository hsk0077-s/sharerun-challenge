# Share Run Challenge

Commercial Flutter application for SRC (Share Run Challenge).

## Local MVP (no cloud deploy)

Use the project-root `.env` for all local secrets and endpoints. **Do not put real
production keys in chat or source code.**

```powershell
Copy-Item .env.example .env   # safe local defaults already in .env.example
```

| Mode | Command | What you get |
| --- | --- | --- |
| **Emulator (recommended)** | `.\scripts\start-local-mvp.ps1` | Auth + Firestore emulators, seeded data, local API |
| **UI mock only** | `.\scripts\start-local-mvp.ps1 -Mode mock` | Static demo lists, no Firebase |
| **Backend only** | `.\scripts\run-local-backend.ps1` | FastAPI on `http://127.0.0.1:8080` |

Then in a second terminal:

```powershell
flutter pub get
flutter run
```

Environment flags (`.env`):

- `USE_FIREBASE_EMULATOR=true` — connect Flutter to local Auth/Firestore emulators
- `USE_LOCAL_MOCK_DATA=true` — skip Firebase, use in-app mock data (UI preview)
- `ALLOW_ANONYMOUS_BOOTSTRAP=true` — auto anonymous sign-in for emulator testing
- `JENA_BASE_URL` — omit for debug defaults: physical Android / iOS / desktop `http://127.0.0.1:8080` (use `adb reverse tcp:8080 tcp:8080` on a USB phone). Android emulator: `--dart-define=ANDROID_EMULATOR=true` or `--dart-define=JENA_BASE_URL=http://10.0.2.2:8080`

Emulator UI: `http://127.0.0.1:4000` · Firestore port `8085` · Auth port `9099`

Backend reads the same root `.env` (`LOCAL_DEV_MODE=true` relaxes `/health/ready`).

## Local Run (full Firebase project)

```powershell
flutter create --project-name share_run_challenge --platforms=android,ios .
flutter pub get
flutterfire configure
flutter run
```

Set `JENA_BASE_URL` in `.env` instead of `--dart-define` when using the new config layer.

Enable **Email/Password** in Firebase Console → Authentication → Sign-in method before
testing the login screen. Also enable **Google** and **Apple** providers for social login.

Social login setup:

- **Google (Android/iOS)**: add platform OAuth client IDs in Firebase, run `flutterfire configure`
- **Apple (iOS)**: enable Apple provider in Firebase, add Sign in with Apple capability in Xcode

Push notifications (FCM):

- Enable Cloud Messaging in Firebase Console
- iOS: upload APNs key, enable Push Notifications capability
- Android 13+: `POST_NOTIFICATIONS` permission is declared in the manifest

For UI-only local work without email accounts:

```powershell
flutter run `
  --dart-define=ALLOW_ANONYMOUS_BOOTSTRAP=true
# Physical Android: adb reverse tcp:8080 tcp:8080  (default Jena http://127.0.0.1:8080)
# Emulator Jena:    --dart-define=ANDROID_EMULATOR=true
#                   or --dart-define=JENA_BASE_URL=http://10.0.2.2:8080
```

Production builds must not set `ALLOW_ANONYMOUS_BOOTSTRAP`.

Use a real iOS/Android device for run validation. Simulators often do not provide
HealthKit, Health Connect, GPS, and gyroscope signals needed by SRC.

Validation flow:

1. Open Home and tap START.
2. Approve location and health data permissions.
3. Move outdoors until GPS distance updates.
4. Tap Finish & Validate Run.
5. Confirm Jena result and Firestore activity result fields.

Before route-map testing, configure Google Maps API keys for Android and iOS.
The MyPage recent activity stream may also require a Firestore composite index
for `activities.userId + updatedAt desc`; create the index from the Firebase
console link if Firestore reports it.

Map & Crew Firestore seed:

```json
diamondBoxes/{boxId}: {
  "title": "Park Gate Diamond",
  "latitude": 37.5665,
  "longitude": 126.9780,
  "rewardDiamond": 3,
  "active": true
}

crewRankings/{crewId}: {
  "name": "Neon Runners",
  "totalValue": 3200,
  "memberCount": 12
}
```

Tournament Firestore seed:

```json
tournaments/{tournamentId}: {
  "title": "Rookie 3K UNICEF Run",
  "targetDistanceKm": 3,
  "entryFeeShare": 100,
  "winnerRewardValue": 500,
  "donationValue": 200,
  "minParticipantsBep": 10,
  "maxParticipants": 100,
  "participantCount": 0,
  "requiredTier": 1,
  "status": "recruiting",
  "sponsorName": "UNICEF Partner",
  "createdAt": "<server timestamp>"
}
```

Tournament queries order by `createdAt desc`. Firestore creates the single-field
index automatically; use the console link if Firebase requests one.
Joining a room writes `tournaments/{id}/participants/{uid}` and a
`walletTransactions` record with type `tournament_entry`.
`minParticipantsBep` is the minimum start threshold. `maxParticipants` is an
optional hard capacity; when present and positive, the secured join API rejects
new entries after `participantCount >= maxParticipants`.

Payment flow notes:

- `paymentIntents` are created in Firestore before opening the external PG URL.
- Configure the PG host with `--dart-define=PG_BASE_URL=https://<pg-host>` on Flutter
  builds. The default demo host is `https://pg.example.com`.
- Update `pgHostPattern()` in `firestore.rules` to the same host (escape dots:
  `pay\\.example\\.com`) before deploying rules.
- Firestore rules only allow the configured PG host with `/share-top-up` and
  `/sponsor` paths for client-created payment intents.
- Share crediting and sponsor support application happen only inside the server
  webhook transaction; successful intents end as `credited`.
- Wallet cash refund requests create `cash_refund_requested` transaction logs
  and subtract refundable Share from the in-app wallet.

Payment webhook:

```http
POST /payments/webhook
Content-Type: application/json

{
  "payment_intent_id": "intent-id",
  "pg_transaction_id": "pg-tx-id",
  "status": "paid",
  "amount": 10000,
  "currency": "KRW",
  "signature": "hmac-sha256"
}
```

The demo signature payload is:

```text
payment_intent_id.pg_transaction_id.amount.status
```

Local signature helper:

```powershell
python -c "import hmac, hashlib; secret=b'dev-secret'; payload=b'intent-id.pg-tx-id.10000.paid'; print(hmac.new(secret, payload, hashlib.sha256).hexdigest())"
```

Set `PG_WEBHOOK_SECRET` in Cloud Run and grant the Cloud Run service account
Firestore write permission.
Set `OPS_ADMIN_SECRET` for operations-only endpoints.

On paid webhooks:

- Only `KRW` payment webhooks are accepted.
- Webhooks enforce the same allowed amount whitelist as Firestore rules:
  10,000 KRW for Share top-up and 1,000/3,000/5,000 Share for sponsor payment.
- `share_top_up` intents increment `users/{uid}.wallet.shareBalance`.
- `sponsor_payment` intents update either `sponsorPrizeSupportShare` or
  `sponsorDonationSupportShare` on the tournament after verifying `uid` and
  `sponsorId` ownership consistency.
- `share_top_up` intents validate owner identity through `_share_top_up_uid_from_intent`
  and reject conflicting `sponsorId` values before crediting Share.
- Processed intents are idempotent: repeated webhooks for `credited` intents do
  not apply the wallet or sponsor update again.
- Backend tests cover the PG signature payload/HMAC check, KRW-only currency
  validation, allowed amount validation, sponsor/share top-up owner identity
  validation, and the already processed idempotency response.

Winner reward flow:

- Jena verification mints earned Value Token first.
- The reward dialog does not mint again.
- Claim keeps the minted Value in the wallet.
- 50% or 100% donation moves minted Value into `wallet.totalDonationValue`.
- `activities/{activityId}.rewardClaimed` prevents duplicate reward allocation.

Sensitive data consent:

- `users/{uid}.sensitiveDataConsent` must be `true` before run validation starts.
- HealthKit/Health Connect permissions are requested only after this app-level consent.
- Heart-rate and cadence arrays stay inside `EphemeralSensorBuffer` and are
  destroyed after Jena validation.
- Firestore activity documents store only sanitized verification results and
  route summaries, not raw HR/cadence arrays.

## Firebase Security

```powershell
.\scripts\deploy-firestore.ps1
```

Equivalent manual command:

```powershell
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
```

The production rules intentionally block client-side wallet, activity,
tournament participant, and diamond collection mutations. Payment crediting
already happens on the Cloud Run webhook, and the Flutter repositories now call
secured Cloud Run action APIs for:

- tournament entry: `POST /actions/tournaments/join`
- diamond box collection: `POST /actions/diamond-boxes/collect`
- winner reward allocation: `POST /actions/rewards/winner`
- wallet refund request: `POST /actions/wallet/refund`
- account deletion: `POST /actions/account/delete`

Send a Firebase ID token in `Authorization: Bearer <id-token>`.

```http
POST /actions/tournaments/join
POST /actions/runs/validate
POST /actions/diamond-boxes/collect
POST /actions/wallet/refund
POST /actions/account/delete
POST /actions/rewards/winner
```

Tournament join, diamond collection, run validation, and winner reward endpoints
are retry-safe for already processed records and return the stored/same success
status without applying balances again. Wallet refund requests are not auto
deduplicated because repeated requests represent additional cash-out intent and
must be controlled by the user's available Share balance and operations review.

BEP refund remains an operations/admin batch flow because it must iterate over
tournament participants safely.

```http
POST /ops/tournaments/{tournamentId}/cancel-bep-refund
POST /ops/tournaments/{tournamentId}/activate
X-Ops-Admin-Secret: <OPS_ADMIN_SECRET>
```

`cancel-bep-refund` sets the tournament to `cancelled_bep_not_met`, refunds each non-refunded
participant's `entryFeeShare` to Share with zero fee, marks participant refunds
as `refunded`, and writes `bep_refund` wallet transaction logs. It is idempotent
for already-refunded participants and sends an FCM topic notification to
`tournament_{tournamentId}` subscribers when messaging is configured.

`activate` moves a recruiting tournament to `active` when `participantCount >=
minParticipantsBep`, then notifies subscribed participants on
`tournament_{tournamentId}`. Idempotent when the tournament is already active.

Deleted accounts can be purged from Firestore after anonymization:

```http
POST /ops/users/{uid}/purge-data
POST /ops/users/purge-deleted
X-Ops-Admin-Secret: <OPS_ADMIN_SECRET>
```

`purge-data` requires `accountStatus: deleted`, deletes the user's activities
and collected diamond boxes, clears push token fields, and sets
`accountStatus: purged`. The batch endpoint processes up to 50 deleted accounts
that have not yet been purged.

Tournament join (`POST /actions/tournaments/join`) requires email verification
for password-based accounts. Flutter also blocks join, Share top-up, and sponsor
payment client-side until `emailVerified` is true.

Run validation persistence and effort Value minting now happen through
`POST /actions/runs/validate`, which stores sanitized activity results and mints
earned Value Token server-side. The endpoint is idempotent by `activity_id`:
after an activity has `validationFinalized: true`, repeated requests return the
stored Jena result and do not mint Value Token again.

Client Firestore writes are limited to user profile settings and payment intent
creation. Activity documents, tournament participants, collected diamond boxes,
wallet balances, and wallet transaction logs are backend-owned writes.
Client user bootstrap may only create a zero-balance, tier-1 profile with
`watchType: none`, `sensitiveDataConsent: false`, `termsAccepted: false`, and
`pushNotificationsEnabled: false`; all later wallet and tier changes must come
from backend-controlled flows. Users must accept required terms through onboarding
before accessing the main app shell.
Payment intent creation is constrained by type: clients may create only
`share_top_up` intents for their own UID at 10,000 KRW, or `sponsor_payment`
intents at 1,000/3,000/5,000 Share with a supported sponsor option. Sponsor
intents also store the authenticated user's `uid`/`sponsorId` for ownership and
auditability. Crediting still happens only after the PG webhook verifies the
payment.
Flutter uses `PaymentConstants` for the same client-side amount policy; keep it
in sync with `firestore.rules` when commercial pricing changes. Keep the PG host
in sync across `PG_BASE_URL`, `PaymentConstants.pgBaseUrl`, and
`firestore.rules` `pgHostPattern()`.

## Production Deployment

### 1. Firebase project bootstrap

```powershell
npm install -g firebase-tools
firebase login
firebase use --add
flutterfire configure
.\scripts\deploy-firestore.ps1
```

Required Firestore composite indexes:

- `activities`: `userId ASC`, `updatedAt DESC`
- `walletTransactions`: `uid ASC`, `createdAt DESC`
- `participants` collection group: `uid ASC` (joined tournament lookup)

Both are declared in `firestore.indexes.json`.

Single-field `orderBy` queries on `tournaments.createdAt` and
`crewRankings.totalValue` use Firestore automatic indexes. Create a console
index only if Firebase returns an index-build link at runtime.

### 2. Cloud Run (Jena AI + secured actions + PG webhook)

One-shot production pipeline (Firestore + Cloud Run + IAM + Scheduler):

```powershell
.\scripts\deploy-all.ps1 `
  -ProjectId <gcp-project-id> `
  -PgWebhookSecret <pg-webhook-hmac-secret> `
  -OpsAdminSecret <ops-admin-secret>
```

Install `gcloud` / `firebase` if missing:

```powershell
.\scripts\install-deploy-tools.ps1
```

Individual steps:

```powershell
.\scripts\deploy-cloud-run.ps1 `
  -ProjectId <gcp-project-id> `
  -PgWebhookSecret <pg-webhook-hmac-secret> `
  -OpsAdminSecret <ops-admin-secret>
```

Manual equivalent:

```powershell
gcloud run deploy src-jena-ai `
  --project <gcp-project-id> `
  --region asia-northeast3 `
  --source backend/jena_ai `
  --allow-unauthenticated `
  --set-env-vars PG_WEBHOOK_SECRET=<secret>,OPS_ADMIN_SECRET=<secret>
```

| Variable | Required | Purpose |
| --- | --- | --- |
| `PG_WEBHOOK_SECRET` | yes | HMAC key for `POST /payments/webhook` |
| `OPS_ADMIN_SECRET` | yes | Header `X-Ops-Admin-Secret` for BEP refund ops |

Cloud Run uses Application Default Credentials. Grant the service account
Firestore read/write access (for example `roles/datastore.user`) and FCM send
access (for example `roles/firebasecloudmessaging.admin`) so tournament topic
notifications work from ops endpoints.

After deploy:

1. Verify liveness: `GET https://<service-url>/health`
2. Verify readiness: `GET https://<service-url>/health/ready`
3. Optional post-deploy check:
   `.\scripts\deploy-cloud-run.ps1 ... -ServiceUrl https://<service-url>`
4. Configure the PG provider to call `POST https://<service-url>/payments/webhook`
5. Store the same HMAC secret on both PG and Cloud Run
6. Schedule `POST /ops/users/purge-deleted` daily via Cloud Scheduler (same ops secret header)

Use Cloud Monitoring or an external uptime checker against `/health` (liveness) and
`/health/ready` (readiness). Local script:

```powershell
.\scripts\check-cloud-run-health.ps1 -ServiceUrl https://<service-url> -RequireReady
```

Local backend env template: `backend/jena_ai/.env.example`

### 3. Flutter production build

Point the app at the deployed API:

```powershell
flutter build apk `
  --dart-define=JENA_BASE_URL=https://<cloud-run-service-url> `
  --dart-define=PG_BASE_URL=https://<pg-host>
flutter build ios `
  --dart-define=JENA_BASE_URL=https://<cloud-run-service-url> `
  --dart-define=PG_BASE_URL=https://<pg-host>
```

Android emulator local testing: `--dart-define=ANDROID_EMULATOR=true` (Jena `http://10.0.2.2:8080`).
Physical USB debug: `adb reverse tcp:8080 tcp:8080` so the default `http://127.0.0.1:8080` reaches the host. Debug login still grants 1M SHARE/DIA/VALUE from Firestore/`walletProvider` even if Jena is down.

### 4. Post-deploy smoke checks

| Check | Command / action |
| --- | --- |
| API liveness | `GET /health` returns `{"status":"ok"}` |
| API readiness | `GET /health/ready` returns `{"status":"ready"}` when env vars are set |
| Health script | `.\scripts\check-cloud-run-health.ps1 -ServiceUrl https://<url> -RequireReady` |
| Run validation | Finish a run → `POST /actions/runs/validate` stores activity |
| Tournament join | Home challenge card → Tournament tab deep link → join room |
| Share top-up | Create intent → PG webhook → Share balance increments |
| BEP refund | `POST /ops/tournaments/{id}/cancel-bep-refund` with ops secret |
| Tournament activate | `POST /ops/tournaments/{id}/activate` when BEP met |
| Account purge | `POST /ops/users/purge-deleted` (schedule daily via Cloud Scheduler) |

Home challenge cards deep-link to `/tournament?tournamentId=<id>` and scroll to
the selected room card.

### 5. PG provider integration checklist

| Step | Owner | Action |
| --- | --- | --- |
| 1 | Mobile | Build with `PG_BASE_URL` pointing at the live PG checkout host |
| 2 | Firebase | Update `pgHostPattern()` in `firestore.rules`, then redeploy rules |
| 3 | PG | Redirect users to the `pgUrl` stored on each `paymentIntents` document |
| 4 | PG | On successful payment, `POST /payments/webhook` with HMAC signature |
| 5 | Cloud Run | Keep `PG_WEBHOOK_SECRET` identical to the PG signing key |

PG checkout URLs are generated server-side in Firestore intent documents:

```text
https://<pg-host>/share-top-up?intentId=...&uid=...&amount=10000
https://<pg-host>/sponsor?intentId=...&uid=...&sponsorId=...&tournamentId=...&amount=...&option=...
```

## Continuous Integration

GitHub Actions runs on `push`/`pull_request` to `main` or `master`:

- `backend/jena_ai`: `pytest`
- Flutter: `flutter analyze` and `flutter test`

Workflow file: `.github/workflows/ci.yml`

Manual E2E release checklist: `docs/e2e-scenarios.md`

Local equivalent:

```powershell
cd backend\jena_ai
pip install -r requirements-dev.txt
pytest -q

flutter pub get
flutter analyze
flutter test
```

## Jena AI

```powershell
cd backend/jena_ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
Copy-Item .env.example .env
# PowerShell local env for webhook/ops testing:
# $env:PG_WEBHOOK_SECRET = "dev-secret"
# $env:OPS_ADMIN_SECRET = "dev-ops-secret"
uvicorn app.main:app --reload --port 8080
```

Backend validation tests:

```powershell
cd backend/jena_ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements-dev.txt
pytest
```
