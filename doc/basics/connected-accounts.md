# Connected Accounts

The settings sub-page where a signed-in user links a social provider to the account they already have, or removes a link.

- [Introduction](#introduction)
- [Requirements](#requirements)
- [The Page](#the-page)
- [Connecting a Provider](#connecting-a-provider)
- [Disconnecting a Provider](#disconnecting-a-provider)
- [Controller Methods](#controller-methods)
- [User Data](#user-data)
- [Overriding the Page](#overriding-the-page)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

The providers listed are the ones the registered bridge offers; the `magic_social_auth` bridge covers Google, Apple, GitHub and Microsoft. The page is drilled into from the Security group of the Settings hub and stacked over it.

<a name="requirements"></a>
## Requirements

The route exists while `magic_starter.features.social_login` is `true`. It is registered on the feature alone: the app's bridge is set by a provider that boots after the one that registers routes, so the route cannot wait for it. The hub row additionally needs a bridge registered with `MagicStarter.useSocialAuth(...)` (see [Social Login](./authentication.md#social-login)); a page opened without one lists no provider.

The route is `MagicStarterConfig.settingsConnectedAccountsRoute()`, `<profile_prefix>/security/connected-accounts` (`/settings/security/connected-accounts` by default), titled `magic_starter.titles.connected_accounts`. The view registry key is `settings.security.connected_accounts`.

The backend is `magic-starter-laravel` with its social login feature on. The starter itself sends `DELETE /user/social-accounts/{provider}` when a link is removed; `POST /user/social-accounts/link-ticket`, which starts a connect, is sent by the bridge inside `beginConnect`.

<a name="the-page"></a>
## The Page

One row per provider the bridge offers (`MagicStarterSocialAuth.providers()`), with the provider's icon and label.

| State | Row shows | Action |
|:------|:----------|:-------|
| Linked (an entry in `social_accounts` with `revoked_at` null) | The address the provider was linked with (`email_at_link`) | **Disconnect** |
| Not linked | Nothing more | **Connect** |

A link the provider revoked (`revoked_at` set) is treated as not linked: it no longer counts as a way to sign in. A refusal appears as a sentence above the list.

<a name="connecting-a-provider"></a>
## Connecting a Provider

A linked identity is a new way into the account, so **Connect** confirms the user's identity first.

1. [`confirmIdentity`](./identity-confirmation.md) asks for the proof the account can give (the password, a TOTP code or a provider confirmation; none for a guest). The proof is minted for this attempt only.
2. `MagicStarterProfileController.beginSocialConnect(provider, proof:)` asks the bridge to begin: the network half (the backend link ticket) happens here, and it answers the call that opens the provider.
3. On iOS and Android the provider opens at once. **On the web the page shows a "Continue with <provider>" button instead**, because a popup opened after the awaits behind steps 1 and 2 is blocked as not user-initiated; the user's tap runs the opener.
4. `doConnectSocialAccount(opener)` runs the opener, then `Auth.restore()` so the new link shows.

Every retry starts over at step 1: a new proof, a new link ticket, a new PKCE pair. A cancelled flow shows nothing. A refusal shows its `social.<code>` sentence: `social_email_taken`, `social_account_taken` (the provider account is already linked to another user, or the caller already holds another account of that provider), `step_up_required`, `flow_expired`.

<a name="disconnecting-a-provider"></a>
## Disconnecting a Provider

**Disconnect** calls `doDisconnectSocialAccount(provider)`, which sends `DELETE /user/social-accounts/{provider}` and restores the user. No proof is asked.

The last way to sign in cannot be removed. For an account with no password and at most one active link, the page disables **Disconnect** as a courtesy and swaps the footer for the `social.last_login_method` sentence. The backend holds that line whatever the page shows (422 `last_login_method`), and the refusal is read by its `code`. Set a password first (see [Set a Password](./set-password.md)) or link another provider.

<a name="controller-methods"></a>
## Controller Methods

On `MagicStarterProfileController`:

| Method | Does |
|:-------|:-----|
| `doDisconnectSocialAccount(provider)` | `DELETE /user/social-accounts/{provider}`, then `Auth.restore()`. Returns `true` on success. |
| `beginSocialConnect(provider, {proof})` | Asks the bridge to begin a connect; answers the opener, or `null` when the bridge refused or the user backed out. |
| `doConnectSocialAccount(opener)` | Runs the opener, then `Auth.restore()`. Calls the opener before anything is awaited, so call it straight from a tap on the web. |

<a name="user-data"></a>
## User Data

`MagicStarterAuthUser` carries what the page reads:

| Getter | Source | Meaning |
|:-------|:-------|:--------|
| `hasPassword` | `has_password` | Whether the account can sign in with a password. `true` when a backend that predates social login does not send the field. |
| `isGuest` | `is_guest` | A device-bound guest account. |
| `socialAccounts` | `social_accounts` | Linked identities: `provider`, `email_at_link`, `created_at`, `revoked_at`. |
| `deletionScheduledAt` | `deletion_scheduled_at` | When a scheduled account deletion runs, or `null`. |

<a name="overriding-the-page"></a>
## Overriding the Page

Replace the view through the registry like any other starter screen:

```dart
MagicStarter.view.register(
  'settings.security.connected_accounts',
  () => const MyConnectedAccountsView(),
);
```

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Enabling `social_login` and expecting providers to appear | The page lists what `MagicStarter.socialAuth.providers()` returns; without a registered bridge it lists none, and the Settings hub row is absent. |
| Calling the opener from `doConnectSocialAccount` after an `await` on the web | The popup is blocked as not user-initiated. The page shows "Continue with <provider>" and runs the opener from that tap; a custom view must do the same. |
| Reusing a proof or link ticket for a retry | Each attempt starts at `confirmIdentity`: a new proof, a new link ticket, a new PKCE pair. |
| Relying on the disabled **Disconnect** button as the guard | It is a courtesy. The backend refuses the last sign-in method with 422 `last_login_method`; read the refusal's `code`. |
| Assuming `has_password` is always sent | `hasPassword` defaults to `true` when the field is missing, so the last-method check only fires on a backend that sends `has_password: false`. |
| Registering the view only when a bridge exists | The route and registry key are registered on the feature flag alone, so the bridge may be set later, from a provider that boots after the routes. |

<a name="related-documentation"></a>
## Related Documentation

- [Authentication](./authentication.md#social-login): the `MagicStarterSocialAuth` bridge contract.
- [Identity Confirmation](./identity-confirmation.md): the proof a connect asks for.
- [Set a Password](./set-password.md): the first-password form for a provider account.
- [View Registry](../architecture/view-registry.md): overriding the page.
- [Social Auth Flows](https://anilcancakir.com/magic_social_auth/docs/basics/flows): the connect flow on the bridge side.
