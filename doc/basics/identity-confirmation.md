# Confirming Identity

How the starter asks an account to prove who it is again before a sensitive action, and which proof each kind of account gives.

- [Introduction](#introduction)
- [Which Proof an Account Gives](#which-proof-an-account-gives)
- [Gated Controller Methods](#gated-controller-methods)
- [The Step-Up Dialog](#the-step-up-dialog)
- [Refusals](#refusals)
- [Helpers](#helpers)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

A few actions are sensitive enough that the backend asks the caller to prove who they are again: turning two-factor on or off, viewing or regenerating recovery codes, revoking a browser session, deleting the account, linking a provider and setting a first password. An account with a password types it. An account created through a provider has none, so the backend takes a different proof.

<a name="which-proof-an-account-gives"></a>
## Which Proof an Account Gives

| Account | Proof | Request fields |
|:--------|:------|:---------------|
| Has a password | The password, in a password dialog | `password` |
| No password, not a guest | A step-up dialog (below) | `code`, or `confirmation_token` |
| Guest (`is_guest`, no password) | None: the backend lets it through and no dialog is shown | none |

`has_password` and `is_guest` come from the user resource. A proof is **minted per call and never kept**: a confirmation token is single use, so a retry asks again. The proof reaches the controller as a `Map<String, String>` that is spread into the request body.

<a name="gated-controller-methods"></a>
## Gated Controller Methods

These methods on `MagicStarterProfileController` take `proof:`, not `password:`. Where the route is a `DELETE`, the controller sends a `POST` with `_method: DELETE` in the body (Laravel method spoofing) and the proof fields beside it:

| Method | Request |
|:-------|:--------|
| `doEnableTwoFactor(proof:)` | `POST /two-factor-authentication` |
| `doDisableTwoFactor(proof:)` | `POST /two-factor-authentication` with `_method: DELETE` |
| `getRecoveryCodes(proof:)` | `POST /two-factor-recovery-codes/show` |
| `doRegenerateRecoveryCodes(proof:)` | `POST /two-factor-recovery-codes` |
| `doRevokeSession(tokenId:, proof:)` | `POST /sessions/{token}` with `_method: DELETE` |
| `doRevokeOtherSessions(proof:)` | `POST /sessions/other` with `_method: DELETE` |
| `doDeleteAccount(proof:)` | `POST /user` with `_method: DELETE` (schedules the deletion) |
| `doSetPassword(password:, passwordConfirmation:, proof:)` | `POST /user/password/set` (see [Set a Password](./set-password.md)) |

Connecting a provider carries the same proof through `beginSocialConnect(provider, proof:)` to the bridge's `beginConnect`. To pass a password account's proof by hand, use `{'password': password}`.

<a name="the-step-up-dialog"></a>
## The Step-Up Dialog

`MagicStarterStepUpDialog` asks a password-less account for what it can send:

- **A code field**, when two-factor is confirmed on the account (`two_factor_enabled`): a TOTP code, sent as `code`.
- **One "Confirm with <provider>" button per linked provider** (an entry of `social_accounts` with `revoked_at` null that the bridge also offers): it re-authenticates through `MagicStarterSocialAuth.confirm(provider)` and sends the resulting token as `confirmation_token`. A provider row asks the bridge again on every tap.
- With neither, only the `social.step_up_required` sentence ("Please confirm your identity to continue.").

It opens proactively for a password-less account. A refusal keeps it open and shows the error inline so the user can retry with a fresh proof. When the backend answers 422 `step_up_required`, its `accepts` list (`code`, `confirmation_token`) narrows the dialog to the proofs the server takes; `MagicStarterProfileController.stepUpAccepts` exposes it and is cleared with the errors.

The web rule applies here too: the bridge's `confirm` is called before anything is awaited in the tap, so the provider popup opens. Cancel stays available while a provider confirm is pending, since on the web a closed popup only fails after a long timeout; a token that arrives after the dialog closed is discarded.

<a name="refusals"></a>
## Refusals

Gated calls report a refusal by its `code`, never by its message:

| Code | Shown as |
|:-----|:---------|
| `step_up_required` | `social.step_up_required`; the dialog narrows to `accepts`. |
| `password_already_set`, `password_not_set` | The cached user was stale: it is restored first, and the page rebuilds with the other password form. |
| `last_login_method` | `social.last_login_method`. |
| `owns_shared_teams`, `team_has_active_subscription`, `subscription_active` | Their own `social.*` sentences (account deletion refused). |
| anything else | The standard API error handling with the call's fallback sentence. |

<a name="helpers"></a>
## Helpers

The starter's screens use two helpers from `lib/src/support/confirms_identity.dart`. The package barrel exports them, along with `MagicStarterStepUpDialog`, so a host that overrides a registry view can confirm a password-less account the same way.

| Helper | Does |
|:-------|:-----|
| `confirmIdentity(context, {variant, title, description, accepts, attempt})` | Picks the proof by the rules above and answers it as request fields, or `null` when the user cancels. With `attempt`, each proof is handed to it before the dialog closes: a returned error string is shown inline and the dialog stays open for the next, fresh proof. |
| `confirmAndRun(context, controller, {action, variant, title, description})` | Confirms identity, then runs a gated `action(proof)` inside the dialog, so a refusal is shown inline and the user retries without reopening it. The dialog stays open only while the server refuses the proof itself (`step_up_required`, or a field error on `password`, `code` or `confirmation_token`); any other refusal closes it and leaves the controller's error on the page. Resolves to `true` when the action succeeded, `false` when the user cancelled or the action was refused for another reason. |

```dart
final success = await confirmAndRun(
  context,
  controller,
  title: trans('profile.set_password'),
  action: (proof) => controller.doDeleteAccount(proof: proof),
);
```

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Keeping a proof between attempts | A proof is minted per call and a confirmation token is single use; ask again on every retry. |
| Showing a dialog to a guest | `confirmIdentity` answers `{}` for a guest (no password, `is_guest`) without a dialog; the backend lets it through. |
| Switching on a refusal's message | Read its `code` (`step_up_required`, `last_login_method`, ...); the message is localised and not stable. |
| Calling the provider bridge's `confirm` after an `await` on the web | The popup is blocked. The step-up dialog calls `confirm` before anything is awaited in the tap; a bridge of your own must open the provider in that same call. |
| Passing `password:` to a gated method | They take `proof:`; use `{'password': value}` for a password account or let `confirmIdentity` produce it. |
| Treating `has_password` as present on every backend | `MagicStarterAuthUser.hasPassword` defaults to `true` when the field is missing, so a backend that never sends it shows the password dialog. |

<a name="related-documentation"></a>
## Related Documentation

- [Authentication](./authentication.md#social-login): the social bridge contract and `confirm`.
- [Connected Accounts](./connected-accounts.md): the page that asks for a proof before it links a provider.
- [Set a Password](./set-password.md): the first-password form for a provider account.
- [Profile](./profile.md): two-factor, sessions and account deletion, the gated screens.
- [Social Auth Flows](https://anilcancakir.com/magic_social_auth/docs/basics/flows): how the bridge's `confirm` and `beginConnect` run.
