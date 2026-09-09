# Share Run Challenge — E2E Scenarios

Manual end-to-end checks for staging and production releases. Run on a physical
device with Firebase, Cloud Run, and PG configured.

## Prerequisites

- Firebase project with Email/Password auth enabled
- Firestore rules and indexes deployed
- Cloud Run service deployed with `PG_WEBHOOK_SECRET` and `OPS_ADMIN_SECRET`
- Flutter build with `JENA_BASE_URL` and `PG_BASE_URL`
- Test user account (email/password)

## 1. Authentication

| Step | Action | Expected |
| --- | --- | --- |
| 1.1 | Launch app while signed out | Login screen appears |
| 1.2 | Sign in with invalid password | Korean error snackbar |
| 1.3 | Create account or sign in (email / Google / Apple) | Onboarding screen if terms not accepted |
| 1.4 | Accept required terms on onboarding | Redirect to Home tab |
| 1.5 | Kill and relaunch app | Session restored, Home tab |
| 1.6 | MyPage → Sign out | Redirect to Login screen |
| 1.7 | MyPage → Delete account | Auth user removed, profile anonymized via API |
| 1.8 | Unverified email login | Verification banner visible, resend works |
| 1.9 | Unverified user → Join / Share top-up / Sponsor pay | Email verification dialog blocks action |
| 1.10 | Verify email → retry join/payment | Action proceeds normally |

## 1b. Push notifications (optional)

| Step | Action | Expected |
| --- | --- | --- |
| 1b.1 | Enable push on onboarding or MyPage | OS permission prompt |
| 1b.2 | Grant permission | `users/{uid}.fcmToken` saved in Firestore |
| 1b.3 | Disable push on MyPage | `pushNotificationsEnabled: false` |
| 1b.4 | Join tournament with push enabled | Client subscribes to `tournament_{id}` FCM topic |
| 1b.5 | BEP refund ops call | Joined users receive tournament topic notification |
| 1b.6 | `POST /ops/tournaments/{id}/activate` with ops secret | Tournament `active`, joined users notified |

## 2. Run validation (effort Value)

| Step | Action | Expected |
| --- | --- | --- |
| 2.1 | MyPage → enable sensitive data consent | Consent saved in Firestore |
| 2.2 | Home → START → approve permissions | Tracking screen active |
| 2.3 | Outdoor run with GPS movement | Distance updates |
| 2.4 | Finish & Validate Run | Jena result screen |
| 2.5 | Verified run | Activity in Firestore, Value minted once |
| 2.6 | Retry same activity validate API | Idempotent stored result, no double mint |

## 3. Tournament

| Step | Action | Expected |
| --- | --- | --- |
| 3.1 | Home → Active Challenge card | Tournament tab opens on selected room |
| 3.2 | Join recruiting room with enough Share | Entry locked, participant doc created |
| 3.3 | Re-open tournament list | Joined room shows `Joined` chip, join disabled |
| 3.4 | Join full room | 409 / Korean "정원이 가득" message |
| 3.5 | Join lower-tier locked room | Join disabled with lock copy |
| 3.6 | Tournament → My Tournaments | Joined rooms list opens |
| 3.7 | Tap joined room | Detail screen shows entry, status, run CTA |
| 3.8 | Open `/tournaments/{id}` while not joined | Room info + Join button (or capacity/tier message) |

## 4. Wallet and payments

| Step | Action | Expected |
| --- | --- | --- |
| 4.1 | Wallet → Share top-up (10,000 KRW) | Payment intent + PG WebView opens |
| 4.2 | PG webhook `paid` with valid HMAC | Share balance +10,000, intent `credited` |
| 4.3 | PG WebView auto-closes on `credited` | Wallet snackbar confirms balance update |
| 4.4 | Repeat webhook for same intent | Idempotent, no duplicate credit |
| 4.4 | Wallet → cash refund request | Share deducted, `cash_refund_requested` tx log |
| 4.5 | Wallet → Recent Activity list | Latest `walletTransactions` entries visible |

## 5. Sponsor payment

| Step | Action | Expected |
| --- | --- | --- |
| 5.1 | Tournament → sponsor icon | Sponsor payment screen |
| 5.2 | Pay 1,000 / 3,000 / 5,000 Share option | Intent uses authenticated `uid`/`sponsorId` |
| 5.3 | PG webhook success | Tournament sponsor support fields updated |

## 6. Map & Crew

| Step | Action | Expected |
| --- | --- | --- |
| 6.1 | Open Map & Crew near seeded diamond box | Collect enabled in range |
| 6.2 | Collect box | Diamond balance increases once |
| 6.3 | Collect again | Idempotent success, no duplicate diamond |

## 7. Winner reward

| Step | Action | Expected |
| --- | --- | --- |
| 7.1 | Complete verified tournament win flow | Reward dialog appears |
| 7.2 | Claim / 50% donate / 100% donate | Value wallet and donation totals correct |
| 7.3 | Repeat reward action | Idempotent, no duplicate allocation |

## 8. Operations (BEP refund & activation)

| Step | Action | Expected |
| --- | --- | --- |
| 8.1 | `POST /ops/tournaments/{id}/cancel-bep-refund` with ops secret | Tournament `cancelled_bep_not_met` |
| 8.2 | Check participants | Share refunded, participant `refundStatus` set |
| 8.3 | Repeat ops call | Idempotent for already-refunded participants |
| 8.4 | `POST /ops/tournaments/{id}/activate` when BEP met | Tournament `active`, FCM topic notification sent |

## 8b. Operations (deleted account purge)

| Step | Action | Expected |
| --- | --- | --- |
| 8b.1 | Delete account via `POST /actions/account/delete` | `accountStatus: deleted`, Auth user removed |
| 8b.2 | `POST /ops/users/{uid}/purge-data` with ops secret | Activities removed, `accountStatus: purged` |
| 8b.3 | Repeat purge for same uid | `already_purged` idempotent response |
| 8b.4 | `POST /ops/users/purge-deleted` batch | Up to 50 deleted accounts purged |

## 9. API health

| Step | Action | Expected |
| --- | --- | --- |
| 9.1 | `GET /health` | `{"status":"ok"}` |
| 9.2 | `GET /health/ready` (prod) | `{"status":"ready"}` when env vars set |
| 9.3 | `scripts/check-cloud-run-health.ps1 -ServiceUrl <url> -RequireReady` | Script exits 0 |

## Dev-only shortcut

For local UI work without Email/Password setup:

```powershell
flutter run --dart-define=ALLOW_ANONYMOUS_BOOTSTRAP=true
```

Do not use anonymous bootstrap in production builds.
