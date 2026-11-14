# The backend contract

The controllers call `magic-starter-laravel`'s routes through magic's `Http` facade. The paths below are relative to `network.drivers.api.base_url`, which carries the backend's `route_prefix` (`api/v1` by default). The route table is `src/routes/api.php` (plus `support.php`) in that repository; a route the backend has not switched on in `config/magic-starter.php` (`features`) answers 404. Change one side, change the other.

## Endpoints by caller

| Caller | Requests |
|:-------|:---------|
| `MagicStarterAuthController` | `POST /auth/login`, `POST /auth/register`, `POST /auth/forgot-password`, `POST /auth/reset-password`, `POST /auth/two-factor-challenge`, `GET /email/verify/{id}/{hash}` (the mailed signed query replayed) |
| `MagicStarterOtpController` | `POST /auth/otp/send`, `POST /auth/otp/verify` |
| `MagicStarterGuestAuthController` | `POST /auth/guest` |
| `MagicStarterGuestClaim` | `POST /auth/guest/claim` with `guest_token`, on a bare driver built from `network.drivers.api` rather than the `Http` facade |
| `MagicStarterHandoffController` | `POST /auth/handoff/exchange` |
| `MagicStarterServiceProvider` | `POST /auth/logout` before sign-out while a token is held |
| `MagicStarterProfileController` | `PUT /user/profile`, `PUT /user/password`, `POST /user/password/set`, `POST /user` with `_method: DELETE` (account deletion), `POST` and `DELETE /user/profile-photo`, `DELETE /user/social-accounts/{provider}`, `POST /two-factor-authentication` (enable; disable with `_method: DELETE`), `POST /two-factor-authentication/confirm`, `POST /two-factor-recovery-codes/show`, `POST /two-factor-recovery-codes`, `GET /sessions`, `POST /sessions/{token}` and `POST /sessions/other` with `_method: DELETE`, `POST /email/verification-notification` |
| `MagicStarterTeamController` | `POST /teams`, `PUT /teams/{team}`, `GET /teams/{team}/members`, `DELETE /teams/{team}/members/{user}`, `GET` and `POST /teams/{team}/invitations`, `DELETE /teams/{team}/invitations/{invitation}`, `POST /invitations/{token}/accept`, `PUT /user/current-team` |
| `MagicStarterNewsletterController` | `GET` and `PUT /user/newsletter` |
| `MagicStarterTimezoneSelect` | `GET /timezones?search=&per_page=&page=` |
| `MagicStarterSupportController` | `GET` and `POST /support/conversations`, `GET /support/conversations/{id}`, `POST /support/conversations/{id}/messages`, `POST /support/conversations/{id}/seen`, `POST /support/conversations/{id}/rating`, `GET /support/articles`, `POST /support/conversations/{id}/attachments/{attachment}/link` |
| `MagicStarterFeedbackController` | `GET` and `POST /support/feedback` |
| `MagicStarterReleasesController` | `GET /releases` |
| `MagicStarterBillingController` | `GET /billing/campaign` itself; plans, checkout, swap, portal and store purchases through `magic_payments` |

The notification list, preferences and push-state requests are `magic_notifications`' own. Every gated write spreads the step-up proof into its body.

## Values both sides must agree on

| Flutter key | Backend | Failure when they differ |
|:------------|:--------|:-------------------------|
| `magic_starter.notifications.external_id_prefix` (default `user_`) | `MAGIC_STARTER_EXTERNAL_ID_PREFIX` (`onesignal.external_id_prefix`, default `user_`) | OneSignal accepts the id and delivers to nobody |
| `magic_starter.billing.billable` (`'user'` or `'team'`) | `billable` in `config/magic-starter.php` | The app and the backend disagree on what a store purchase is billed to; a Flutter value other than the two throws `StateError` |
| `magic_starter.billing.web_origin` (absolute, no trailing slash) | Stripe return URLs | Unset or empty, the web checkout button is hidden; a relative value makes Stripe refuse it and the error is only logged |
| A feature toggle | The same feature in `features` | The screens call routes that answer 404 |

## Refusal codes

The backend refuses with a machine `code`; the starter maps each to a `social.<code>` sentence and never reads the message to decide. Step-up: `step_up_required` (the dialog narrows to the accepted proofs). Passwords and links: `password_already_set`, `password_not_set`, `last_login_method`. Account deletion: `owns_shared_teams`, `team_has_active_subscription`, `subscription_active`. Social sign-in refusals arrive as `MagicStarterSocialException(code:, message:, cancelled:)` from the bridge; `cancelled` shows nothing.

A plan-gated refusal is a `403` carrying `upgrade.required_plan`; `PlanUpgradeRequirement.fromResponse(response)` answers it and `null` for every other response, so a `403` without the marker is never offered an upgrade.
