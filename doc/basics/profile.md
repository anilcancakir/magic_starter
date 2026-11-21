# Profile

The settings hub and the sub-pages behind it, where a signed-in user edits their profile, security and preferences through `MagicStarterProfileController`.

- [Basic Usage](#basic-usage)
- [Quick Reference](#quick-reference)
- [Profile Photo](#profile-photo)
- [Profile Information](#profile-information)
- [Changing a Password](#changing-a-password)
- [Email Verification](#email-verification)
- [Sessions](#sessions)
- [Timezone and Language](#timezone-and-language)
- [Newsletter](#newsletter)
- [Delete Account](#delete-account)
- [Two-Factor](#two-factor)
- [Gate Abilities](#gate-abilities)
- [Overriding a Page](#overriding-a-page)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="basic-usage"></a>
## Basic Usage

Register the routes from your route provider, beside the other starter routes:

```dart
registerMagicStarterAuthRoutes();
registerMagicStarterProfileRoutes();
```

The hub opens at `MagicStarterConfig.settingsHubRoute()`, which is `magic_starter.routes.profile_prefix` (default `/settings`). Every sub-page is pushed (`.stacked()`) so the back gesture returns to the hub, and the whole group sits behind the `auth` middleware alias inside the `layout.app` shell.

The pages call the controller for you. A page of your own calls it the same way:

```dart
final controller = MagicStarterProfileController.instance;

final saved = await controller.withoutNotifying(
  () => controller.doUpdateProfile(name: 'Alice', email: 'alice@example.com'),
);
```

Every `do*` method answers `bool` (a few two-factor reads answer a map or a list, or `null` on failure), refuses to start while another write is in flight, and keeps its refusal on the controller for the view to show.

<a name="quick-reference"></a>
## Quick Reference

| Page | Route | View key | Shown when |
|:-----|:------|:---------|:-----------|
| Hub | `settingsHubRoute()` | `settings.hub` | Always |
| Profile | `profileRoute()` | `profile.profile` | Always |
| Appearance | `settingsAppearanceRoute()` | `settings.appearance` | Always |
| Password | `settingsPasswordRoute()` | `settings.security.password` | Gate `starter.update-password` |
| Language | `settingsLanguageRoute()` | `settings.language` | `extended_profile` |
| Timezone | `settingsTimezoneRoute()` | `settings.timezone` | `timezones` |
| Email & privacy | `settingsNewsletterRoute()` | `settings.newsletter` | `newsletter` and Gate `starter.manage-newsletter`, or `analytics` |
| What's new | `settingsChangelogRoute()` | `settings.changelog` | `releases` (see [Releases](./releases.md)) |
| Two-factor | `settingsTwoFactorRoute()` | `settings.security.two_factor` | `two_factor` and Gate `starter.manage-two-factor` |
| Sessions | `settingsSessionsRoute()` | `settings.security.sessions` | `sessions` |
| Connected accounts | `settingsConnectedAccountsRoute()` | `settings.security.connected_accounts` | `social_login` and a bridge from `MagicStarter.useSocialAuth` (see [Connected Accounts](./connected-accounts.md)) |

All the route helpers hang off `MagicStarterConfig` and follow `profile_prefix`. A disabled feature registers neither its route nor its default view.

<a name="profile-photo"></a>
## Profile Photo

Gated by `magic_starter.features.profile_photos` and the Gate `starter.update-profile-photo`. The Profile page shows the section.

```dart
final uploaded = await MagicStarterProfileController.instance.doUpdateProfilePhoto(
  file: magicFile,
);
final removed = await MagicStarterProfileController.instance.doDeleteProfilePhoto();
```

Upload is a multipart `POST /user/profile-photo` with the file under the `photo` key; removal is `DELETE /user/profile-photo`. Both call `Auth.restore()` on success, so `profile_photo_url` on the user model is fresh. `magic-starter-laravel` serves these routes only with its `profilePhotos` feature on.

<a name="profile-information"></a>
## Profile Information

`doUpdateProfile()` sends `PUT /user/profile`. `name` and `email` are required arguments; `phone`, `timezone` and `language` are sent only when non-empty, and `language` travels as the `locale` key:

```dart
final success = await controller.withoutNotifying(
  () => controller.doUpdateProfile(
    name: form.get('name'),
    email: form.get('email'),
    phone: form.get('phone'),
    language: form.get('language'),
  ),
);
```

`withoutNotifying()` suppresses `notifyListeners()` for the duration of the action, so a form that already shows its own loading state through `MagicFormData.process()` does not rebuild the whole page.

On success the controller calls `Auth.restore()`, shows a toast and, when `language` is present, hands it to `MagicStarterManager.applyLocale()`, which switches the app's locale after the current frame. `MagicStarterServiceProvider` also applies a signed-in user's saved `locale` on every sign-in and restore, gated by `magic_starter.localization.apply_user_locale` (default `true`); see [Locale Application](../architecture/manager.md#locale-application). Both go through `applyLocale()`, so one save issues one `Lang.setLocale()` call.

The Profile page carries name and email (email behind the Gate `starter.update-email`) and, with `extended_profile`, a phone field behind `starter.update-phone`.

<a name="changing-a-password"></a>
## Changing a Password

```dart
final success = await controller.doUpdatePassword(
  currentPassword: form.get('current_password'),
  password: form.get('password'),
  passwordConfirmation: form.get('password_confirmation'),
);
```

This sends `PUT /user/password` with `current_password`, `password` and `password_confirmation`. It does not call `Auth.restore()`: the user model does not change.

An account created through a provider has no password (`has_password` is `false`): the backend answers `PUT /user/password` with 422 `password_not_set`, and the page shows the **Set password** form instead. See [Set a Password](./set-password.md).

<a name="email-verification"></a>
## Email Verification

Gated by `magic_starter.features.email_verification` and the Gate `starter.verify-email`. The Profile page shows a banner with a resend button while the email is unverified, and a verified badge afterwards.

```dart
await MagicStarterProfileController.instance.sendEmailVerification();
final verified = MagicStarterProfileController.instance.isEmailVerified;
```

`sendEmailVerification()` posts to `/email/verification-notification` and toasts on success. `isEmailVerified` reads `email_verified_at` from `Auth.user()` and is `true` only for a non-empty string. The mailed link is handled by the backend and the app's verify-email view; call `Auth.restore()` to pull the new status.

<a name="sessions"></a>
## Sessions

Gated by `magic_starter.features.sessions`. The Sessions page lists the account's tokens (device, IP address, location and a "current device" badge) from `GET /sessions`:

```dart
final sessions = await controller.getSessions();
```

`getSessions()` answers `null` when the feature is off or the read fails. Revoking is gated by the Gate `starter.logout-sessions` and needs a step-up `proof`:

```dart
final revoked = await controller.doRevokeSession(tokenId: session['id'].toString(), proof: proof);
final others = await controller.doRevokeOtherSessions(proof: proof);
```

Both go out as `POST` with `{'_method': 'DELETE', ...proof}` to `/sessions/{id}` and `/sessions/other`; the backend route is `DELETE`. `proof` is `{'password': ...}`, `{'code': ...}`, `{'confirmation_token': ...}` or `{}` for a guest; [Confirming Identity](./identity-confirmation.md) covers how the right one is produced for the signed-in account.

<a name="timezone-and-language"></a>
## Timezone and Language

Each is its own sub-page and saves through `doUpdateProfile()`, carrying the user's current `name` and `email` so the save does not blank them.

The Timezone page (`timezones` feature) uses `MagicStarterTimezoneSelect`, a searchable dropdown over `GET /timezones?search=&per_page=&page=`. It debounces the search, pages through the endpoint on scroll and keeps the current value in the list. Entries without an `identifier` and a `label` are dropped. The backend serves the route only with its own `timezones` feature on.

The Language page (`extended_profile` feature) selects from `MagicStarter.localeOptions`. Without an override the list is the app's supported locales (`Lang.supportedLocales`) with native language names; register your own with `MagicStarter.useLocaleOptions({'en': 'English', 'tr': 'Türkçe'})`.

<a name="newsletter"></a>
## Newsletter

Gated by `magic_starter.features.newsletter` and the Gate `starter.manage-newsletter`. `MagicStarterNewsletterController` keeps the subscription apart from the profile controller:

```dart
await MagicStarterNewsletterController.instance.getNewsletterStatus();
await MagicStarterNewsletterController.instance.updateNewsletterSubscription(subscribe: true);
```

These call `GET /user/newsletter` and `PUT /user/newsletter`. `MagicStarter.useNewsletterLabel('Subscribe to our updates')` sets the label of the newsletter checkbox on the register view (with `newsletter` on); the profile newsletter section does not read it.

The page is titled "Email & privacy" (`magic_starter.privacy.title`). With `magic_starter.features.analytics` on, it also shows a "Share usage data" switch for the whole account (the starter imports no analytics package, so the host connects its own through [`applyAnalyticsOptOut`](../architecture/manager.md#analytics-preference-callback)); the newsletter section shows only with `newsletter` on. The registry key `settings.newsletter`, the route and `MagicStarterNewsletterView` keep the newsletter name for compatibility. `MagicStarterAnalyticsPreferenceController` reads and saves the choice:

```dart
await MagicStarterAnalyticsPreferenceController.instance.getAnalyticsPreference();
await MagicStarterAnalyticsPreferenceController.instance.updateAnalyticsPreference(optedOut: true);
```

These call `GET /user/analytics` and `PUT /user/analytics` with `{"opted_out": bool}` (the backend's `analytics-preference` feature). Only an accepted save is applied on the device: a vault copy under `magic_starter.analytics_opted_out`, the host's `applyAnalyticsOptOut` hook, then the host's [`onAnalyticsPreferenceChanged`](../architecture/manager.md#analytics-preference-callback). `MagicStarterServiceProvider` applies the vault copy on boot, applies the account's answer after every sign-in and confirmed restore, and drops the copy (lifting an opt-out it held) on sign-out. With the feature off, nothing reads `/user/analytics`.

<a name="delete-account"></a>
## Delete Account

Account deletion lives on the Sessions page. It asks first whether the account goes after the grace period or now, then confirms identity, then calls the controller:

```dart
final proof = await confirmIdentity(context);
if (proof == null) return; // the user cancelled

final success = await MagicStarterProfileController.instance.doDeleteAccount(
  proof: proof,
  immediately: false, // true purges now instead of after the grace period
);
```

The controller sends `POST /user` with `{'_method': 'DELETE', ...proof}` and, for the second choice, `'immediately': true`. The backend answers `202`: by default it schedules the deletion, revokes every token and purges after a grace period, and a sign-in within it cancels the deletion (the next sign-in shows an "Account deletion cancelled" toast; the user carries `deletion_scheduled_at`). With `immediately` it purges at once. Either way the controller toasts the server's sentence, calls `Auth.logout()` and navigates to the login page.

A refusal keeps the user signed in and shows its own sentence, read by `code`: `owns_shared_teams`, `team_has_active_subscription`, `subscription_active`, `step_up_required`, or a wrong password. A subscription refusal can carry one action that clears it: the store's subscription screen for a store plan, or the page at `magic_starter.account.deletion_url` for a card plan (without that key the sentence stands alone).

<a name="two-factor"></a>
## Two-Factor

Enabling, confirming, disabling and recovery codes run through the same controller (`doEnableTwoFactor`, `doConfirmTwoFactor`, `doDisableTwoFactor`, `getRecoveryCodes`, `doRegenerateRecoveryCodes`), on the Two-factor page. `controller.isTwoFactorEnabled` reads `two_factor_enabled` from the user. See [Authentication](./authentication.md#two-factor-authentication).

<a name="gate-abilities"></a>
## Gate Abilities

`MagicStarterServiceProvider` defines these abilities, all denying a guest. Feature flags decide whether a feature exists; the abilities decide whether this user sees it. Re-define one with `Gate.define` after the provider boots to change the rule.

| Ability | Controls |
|:--------|:---------|
| `starter.update-profile-photo` | The photo section |
| `starter.update-email` | The email field |
| `starter.update-phone` | The phone field |
| `starter.update-password` | The Password row and page |
| `starter.verify-email` | The verification banner |
| `starter.manage-two-factor` | The Two-factor row |
| `starter.manage-newsletter` | The newsletter section of Email & privacy, and the row unless the analytics switch renders (`analytics` on) |
| `starter.logout-sessions` | The revoke buttons on Sessions |
| `starter.delete-account` | The delete section; a guest is denied and sees an upgrade prompt instead |

<a name="overriding-a-page"></a>
## Overriding a Page

Replace any page through the view registry, and add content around the hub and the Profile page with their `header` and `footer` slots:

```dart
MagicStarter.view.register('settings.security.password', () => const MyPasswordView());
MagicStarter.view.slot('settings.hub', 'footer', (context) => const MyAboutSection());
```

`MagicStarterSettingsAccountGroup`, `MagicStarterSettingsSecurityGroup` and `MagicStarterSettingsPreferencesGroup` are the hub's sections, each with its own gating; a host that registers its own `settings.hub` composes them instead of copying the rows.

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Expecting a single long profile page under `profile.settings` | The default is the hub and its sub-pages. `profile.settings` is a publishable view that no default registers, and `MagicStarterProfileController.profile()` throws a `StateError` until you register it. |
| Calling `doUpdateProfile` with only a timezone or a language | `name` and `email` are required. Carry them from `Auth.user()`, as the Timezone and Language pages do. |
| Passing `password:` to `doRevokeSession`, `doRevokeOtherSessions` or `doDeleteAccount` | They take `proof:`. Produce it with `confirmIdentity`. |
| Turning on `extended_profile` and expecting a Timezone row | The row needs the `timezones` flag. `extended_profile` adds the Language row and the phone field. |
| Reading `language` in the backend's profile payload | The client sends it as `locale`. |
| Showing the photo section with `profile_photos` off on the backend | `magic-starter-laravel` registers the photo routes only with its own feature on; turn on both sides. |

<a name="related-documentation"></a>
## Related Documentation

- [Authentication](./authentication.md): sign-in, two-factor and guest sessions.
- [Confirming Identity](./identity-confirmation.md): the `proof` the gated methods take.
- [Set a Password](./set-password.md): the first password of a social-only account.
- [Connected Accounts](./connected-accounts.md): linking and unlinking providers.
- [Teams](./teams.md): team creation and switching.
- [Releases](./releases.md): the What's new page.
- [Views and Layouts](./views-and-layouts.md): the view registry and the app shell.
- [Configuration](../getting-started/configuration.md): the feature flags and route keys.
