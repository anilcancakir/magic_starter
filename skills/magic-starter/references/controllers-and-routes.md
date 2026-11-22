# Controllers and routes

## Controllers

Each is a `MagicController` reached through `.instance` (`Magic.findOrPut`), except billing, which the host registers with `Magic.put`. All but four mix in `MagicStateMixin`: support, feedback, handoff and billing do not. A view resolves its controller; it never constructs one.

| Controller | Owns |
|:-----------|:-----|
| `MagicStarterAuthController` | `doLogin`, `doRegister`, `doSocialSignIn`, `doForgotPassword`, `doResetPassword`, `doVerifyEmail`, `doTwoFactorChallenge`, `logout` |
| `MagicStarterGuestAuthController` | `doGuestLogin` (navigates home), `openGuestSession()` (answers whether a session exists, navigates nowhere, keeps a session already held) |
| `MagicStarterOtpController` | Send and verify a phone one-time code |
| `MagicStarterHandoffController` | Trading a handoff code for a session |
| `MagicStarterProfileController` | `doUpdateProfile`, `doUpdatePassword`, `doSetPassword`, photo upload and removal, two-factor, recovery codes, sessions, `beginSocialConnect`, `doConnectSocialAccount`, `doDisconnectSocialAccount`, `doDeleteAccount` |
| `MagicStarterTeamController` | `doCreate`, `doUpdate`, `doInvite`, members, invitations, `switchTeam`, `doAcceptInvitation`; implements `SessionScoped` |
| `MagicStarterNewsletterController` | The newsletter subscription |
| `MagicStarterAnalyticsPreferenceController` | The account's "Share usage data" choice; an accepted save applies the vault copy, the host's `applyAnalyticsOptOut` hook and `onAnalyticsPreferenceChanged`; every device apply (`applyOnDevice(optedOut, {isCurrent})`, `applyCachedOnDevice()`, `forgetOnDevice()`) runs one at a time in a queue that includes the hook, so a hook must not call them or `updateAnalyticsPreference` |
| `MagicStarterSupportController` | Conversations, threads, replies, ratings, attachments, seen receipts |
| `MagicStarterFeedbackController` | The 0 to 10 feedback card |
| `MagicStarterReleasesController` | The release feed; `readFeed()` is the stateless read the update banner uses |
| `MagicStarterBillingController` | Plans, usage, both billing rails. Constructed by the host with `usageCopy` and `formatNumber` (required) and put with `Magic.put(...)` before the billing page is reached; implements `SessionScoped` |

Methods answer `bool` (or a map) so a caller branches without reading state; errors land in the controller's state through `handleApiError`. The gated profile methods take `proof:` (see `SKILL.md`, Sign-in and identity rules).

A controller of your own follows the same shape: [State Management](https://anilcancakir.com/magic/docs/starter/guides/state-management).

## Routes

| Function | Group | Paths (defaults) |
|:---------|:------|:-----------------|
| `registerMagicStarterAuthRoutes()` | `guest` middleware, `layout.guest`, prefix `routes.auth_prefix` | `/auth/login`, `/auth/forgot-password`, `/auth/reset-password`; `/auth/register` (`registration`), `/auth/two-factor-challenge` (`two_factor`), `/auth/otp` (`phone_otp`) |
| (same function, own groups) | outside `guest` | `/auth/verify-email` (`email_verification`), `/auth/handoff` (`handoff`) |
| `registerMagicStarterProfileRoutes()` | `auth`, `layout.app` | `/settings` (hub), `/settings/profile`, `/settings/appearance`, `/settings/security/password`; `/settings/language`, `/settings/timezone`, `/settings/newsletter`, `/settings/changelog`, `/settings/security/two-factor`, `/settings/security/sessions`, `/settings/security/connected-accounts` behind their toggles |
| `registerMagicStarterTeamRoutes()` | `auth`, `layout.app`; no-op without `teams` | `/teams/create`, `/teams/settings`, `/invitations/:token/accept` |
| `registerMagicStarterNotificationRoutes()` | `auth`, `layout.app`; no-op without `notifications` | `routes.notifications_prefix` (`/notifications`), `/settings/notifications` |
| `registerMagicStarterSupportRoutes()` | `auth`, `layout.app`; no-op without `support` | `/support`, `/support/new`, `/support/:id`, `/support/feedback` (`support_feedback`) |

Build a link with the matching `MagicStarterConfig.*Route()` (`settingsHubRoute()`, `profileRoute()`, `settingsPasswordRoute()`, `teamCreateRoute()`, `notificationsRoute()`, `supportRoute()`, `handoffRoute()`, `billingRoute()`, ...); a changed prefix moves every path built from it. The settings sub-pages, team create and settings, the notification pages and the support create, thread and feedback pages are `.stacked()`, so they push and pop; the hub, the auth pages and the invitation page replace. A stacked route names no transition, so it follows `MagicRouter.defaultTransition`.

## Middleware

- `EnsureAuthenticated` (`auth`): a signed-out visitor goes to `routes.login`, and the location is recorded with `MagicRouter.setIntendedUrl` (not for the guest-only auth routes themselves). The redirect runs before the page builds.
- `RedirectIfAuthenticated` (`guest`): a signed-in account goes to `routes.home`; a guest session (`is_guest`) is let through, since the auth pages are where it becomes an account.
- Both describe the package classes. `starter:install` registers its own `handle`-based copies from `lib/app/middleware/`, which redirect after the build, record no intended URL and do not let a guest through.

## What the provider wires

`MagicStarterServiceProvider.register()` binds the manager under `'magic_starter'`, registers the `AuthRestored` reload (only when the restore changed the user) and the `onLogin` call on `AuthLogin`, the guest record and claim listeners when `guest_auth` is on, the analytics preference listeners when `analytics` is on (apply the account's choice on sign-in and restore, drop the device copy on sign-out), and declares the session identity (user plus team) and the store billable. `boot()` warns when `teams` is on without a resolver, defines the `starter.*` Gate abilities (each denies a guest; redefine one after this provider to change it), installs the modal theme's overlay presentation on magic's router, primes the web build info for `releases` and `app_update`, and attaches the auth-state listeners: forget the intended URL on sign-out, declare or release the push identity, apply the user's saved locale (`localization.apply_user_locale`), and the before-logout hooks that release the push device and revoke the token. With `analytics` on, `boot()` first throws a `StateError` when `applyAnalyticsOptOut` is unset, and last applies an opt-out cached on the device.
