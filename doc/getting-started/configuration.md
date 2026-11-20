# Configuration

The `magic_starter` config file turns features on, sets the route prefixes and carries the billing, push, handoff and legal keys, read at runtime through `MagicStarterConfig`.

- [Introduction](#introduction)
- [The Config File](#config-file)
- [Feature Toggles](#feature-toggles)
- [Route Customisation](#route-customization)
- [Billing](#billing)
- [The push external id](#push-external-id)
- [Auth Identity Modes](#auth-identity-modes)
- [Locale & Timezone Defaults](#locale-timezone-defaults)
- [Accessing Values](#accessing-values)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

The plugin is configured by one Dart file in your app, `lib/config/magic_starter.dart`, which `starter:install` generates from the features you chose. Every feature defaults to `false` (an absent key reads `false`, and the template `starter:publish --tag=config` copies on a host without the file writes every feature `false` too, see [CLI](../basics/cli.md#publish-tags)): a toggle decides whether its routes are registered, its views are put in the view registry and its UI shows.

```bash
dart run magic:dowel starter:install
```

To flip toggles later, edit the file, or run `dart run magic:dowel starter:configure` for the toggles it has a flag for; see [CLI Commands](../basics/cli.md).

<a name="config-file"></a>
## The Config File

The file exports one top-level getter that returns a nested `Map<String, dynamic>`:

```dart
Map<String, dynamic> get magicStarterConfig => {
  'magic_starter': {
    'features': {
      'teams': false,
      'registration': false,
      'extended_profile': false,
      'profile_photos': false,
      'social_login': false,
      'two_factor': false,
      'sessions': false,
      'phone_otp': false,
      'newsletter': false,
      'analytics': false,
      'notifications': false,
      'email_verification': false,
      'guest_auth': false,
      'timezones': false,
      'billing': false,
      'support': false,
      'support_csat': false,
      'support_feedback': false,
      'support_attachments': false,
      'support_client_context': false,
      'support_chat': false,
      'store_review': false,
      'releases': false,
      'app_update': false,
      'handoff': false,
    },
    'auth': {
      'email': true,
      'phone': false,
    },
    'defaults': {
      'locale': 'en',
      'timezone': 'UTC',
    },
    'localization': {
      'apply_user_locale': true,
    },
    'supported_locales': [
      'en',
      'tr',
    ],
    'routes': {
      'home': '/',
      'login': '/auth/login',
      'auth_prefix': '/auth',
      'teams_prefix': '/teams',
      'profile_prefix': '/settings',
      'notifications_prefix': '/notifications',
      'billing': '/teams/billing',
    },
    'billing': {
      'web_origin': null,
      'billable': 'user',
    },
    'notifications': {
      'external_id_prefix': 'user_',
    },
    'handoff': {
      'confirm_without_session': true,
      'signed_out_route': null,
    },
    'legal': {
      'terms_url': null,
      'privacy_url': null,
    },
    'account': {
      'deletion_url': null,
    },
  },
};
```

Register it with `Magic.init()` next to your other config factories (the installer does this for you):

```dart
await Magic.init(
  configFactories: [
    () => appConfig,
    () => magicStarterConfig,
  ],
);
```

Every key under `'magic_starter'` is readable with `Config.get('magic_starter.<key>')` using dot notation. The support and store review screens read further keys, listed in [Support](../basics/support.md).

<a name="feature-toggles"></a>
## Feature Toggles

Each toggle controls whether routes are registered, views are put in the registry and UI sections render.

| Key | Default | Description |
|:----|:--------|:------------|
| `teams` | `false` | Team creation, management, member invitations and team switching. Needs a team resolver, see [Installation](installation.md#bootstrapping-the-starter). |
| `registration` | `false` | The registration screen and route. |
| `extended_profile` | `false` | Additional profile fields (phone, timezone, language) and the Language settings page. |
| `profile_photos` | `false` | Profile photo upload and removal in the profile settings. |
| `social_login` | `false` | Provider buttons on the login and register screens, the Connected accounts settings page and the provider option of the identity-confirmation dialog. Needs a bridge registered with `MagicStarter.useSocialAuth(...)`, see [Social Login](../basics/authentication.md#social-login); the flag alone renders nothing. |
| `two_factor` | `false` | Two-factor setup, the challenge screen and recovery codes. |
| `sessions` | `false` | The browser sessions list with revoke. |
| `phone_otp` | `false` | The phone-based one-time code flow (send, verify). |
| `newsletter` | `false` | The newsletter subscribe toggle on the Email & privacy settings page. |
| `analytics` | `false` | The account-level "Share usage data" switch on the Email & privacy page, and applying the account's choice to `magic_analytics` on boot, sign-in and sign-out. Needs `AnalyticsServiceProvider` registered; without it the switch is hidden. |
| `notifications` | `false` | The in-app notification list, unread badge and preferences screen, and the push identity this package declares. |
| `email_verification` | `false` | The email verification page and resend flow. |
| `guest_auth` | `false` | The login screen's "Continue as guest" button, plus the listeners that record a guest sign-in and claim that guest's data when an account signs in. It adds no routes or screens. |
| `timezones` | `false` | The Timezone settings page with debounced async search. |
| `billing` | `false` | The `teams.billing` view; see [Billing](#billing). |
| `support` | `false` | The support desk (`/support`, `/support/new`, `/support/:id`). The host registers the routes with `registerMagicStarterSupportRoutes()`; see [Support](../basics/support.md). |
| `support_csat` | `false` | A thumbs rating under a resolved conversation. |
| `support_feedback` | `false` | The feedback card and the `/support/feedback` page. |
| `support_attachments` | `false` | Image and PDF attachments on a message. |
| `support_client_context` | `false` | App version, platform and locale sent with a new conversation. |
| `support_chat` | `false` | The chat launcher and its floating panel. Needs `support`. |
| `store_review` | `false` | The native store review prompt. |
| `releases` | `false` | The "What's new" changelog page (`/settings/changelog`) and the version caption, read from the backend's `GET releases`. Needs `Features::releases()` on `magic-starter-laravel`; see [Releases](../basics/releases.md). |
| `app_update` | `false` | `MagicStarterAppUpdateBanner` in the app layout: Reload when a new web deploy appears in `version.json`, Update when the store has a newer build. The store path reads `GET releases`; see [Releases](../basics/releases.md). |
| `handoff` | `false` | The sign-in handoff page `/auth/handoff?code=&next=`: it trades a one-time code for a session, after asking "Sign in as ...?", and opens `next`. See [Sign-in handoff](../basics/authentication.md#handoff). |

The handoff keys sit beside the toggle. `handoff.confirm_without_session` (default `true`) keeps the question when nobody is signed in, which is what stops a link carrying an attacker's own code from signing a visitor in to the attacker's account; `false` only saves the tap. `handoff.signed_out_route` (default `null`, meaning `routes.login`) is where a signed-out visit without a code goes, carrying `?next=`.

To enable features, set their values to `true`:

```dart
'features': {
  'teams': true,
  'registration': true,
  'notifications': true,
  // ... remaining features stay false
},
```

> [!TIP]
> A disabled feature registers no route and no view, so asking the view registry for its key (`MagicStarter.view.make('teams.create')`) throws a `StateError`. Check `MagicStarterConfig.hasTeamFeatures()` and its siblings before building a link to a gated page. The one shared page is Email & privacy: its route and `settings.newsletter` key register while either `newsletter` or `analytics` is on, so turning `newsletter` off alone does not remove it.

<a name="route-customization"></a>
## Route Customisation

The `routes` block controls the URL paths the starter registers:

```dart
'routes': {
  'home': '/',
  'login': '/auth/login',
  'auth_prefix': '/auth',
  'teams_prefix': '/teams',
  'profile_prefix': '/settings',
  'notifications_prefix': '/notifications',
  'billing': '/teams/billing',
},
```

| Key | Default | Description |
|:----|:--------|:------------|
| `home` | `'/'` | Where a successful sign-in lands (unless an intended URL or a `next` path says otherwise) and where `RedirectIfAuthenticated` sends a signed-in visitor. |
| `login` | `'/auth/login'` | Where `EnsureAuthenticated` sends a signed-out visitor. |
| `auth_prefix` | `'/auth'` | Prefix of the auth routes (login, register, forgot and reset password, two-factor challenge, OTP, verify email, handoff). |
| `teams_prefix` | `'/teams'` | Prefix of the team routes (create, settings). |
| `profile_prefix` | `'/settings'` | Prefix of the settings hub and its sub-pages. |
| `notifications_prefix` | `'/notifications'` | The notifications list page. |
| `billing` | `'/teams/billing'` | The billing page, also where the upgrade prompts send the user. |

`MagicStarterConfig` also builds the paths that depend on a prefix:

```dart
MagicStarterConfig.teamCreateRoute();           // '/teams/create'
MagicStarterConfig.teamSettingsRoute();         // '/teams/settings'
MagicStarterConfig.profileRoute();              // '/settings/profile'
MagicStarterConfig.settingsHubRoute();          // '/settings'
MagicStarterConfig.notificationsRoute();        // '/notifications'
MagicStarterConfig.notificationPreferencesRoute(); // '/settings/notifications'
MagicStarterConfig.twoFactorChallengeRoute();   // '/auth/two-factor-challenge'
MagicStarterConfig.handoffRoute();              // '/auth/handoff'
```

Changing a prefix updates every path built from it: setting `profile_prefix` to `'/account'` makes `profileRoute()` return `'/account/profile'` and `notificationPreferencesRoute()` return `'/account/notifications'`.

<a name="billing"></a>
## Billing

The `billing` feature gates the `teams.billing` view, which sells subscriptions through [`magic_payments`](https://pub.dev/packages/magic_payments). It has its own toggle rather than hanging on `teams`: a subscription is bought by whoever holds the account, so an app with no team features can still sell one.

```dart
'features': {
  'billing': true,
},
'routes': {
  'billing': '/teams/billing',
},
'billing': {
  'web_origin': 'https://app.example.com',
  'billable': 'user',
},
```

| Key | Default | Description |
|:----|:--------|:------------|
| `billing.web_origin` | `null` | The host app's own web origin, with no trailing slash. Required once billing is on; read on the web rail only. |
| `billing.billable` | `'user'` | What a store purchase is billed to: `'user'` or `'team'`. It must match `magic-starter-laravel`'s `billable` key. Any other value throws a `StateError`. |

> [!WARNING]
> `billing.web_origin` carries no default on purpose. The billing view builds Stripe's `successUrl`, `cancelUrl` and the portal `returnUrl` by concatenating this origin with a path, and Stripe requires absolute urls. Left unset or empty, the screen hides the web checkout button rather than build a relative url, and the portal still opens, without a return url. Set to a relative value, the checkout reaches Stripe, which refuses it; the resulting `BillingException` is logged rather than shown, so the customer sees a button that does nothing. `dart run magic:dowel starter:doctor` reports the missing key.

A store purchase on iOS or Android never reads `web_origin`. See [Teams](../basics/teams.md) for what `billable` changes.

<a name="push-external-id"></a>
## The push external id

With the `notifications` feature on, this package declares who the device is subscribed as every time a session begins, and releases it on every sign-out, including the ones no call site performs (account deletion, and a session that simply expires). You wire nothing.

What it declares is the prefix below followed by the authenticated user's id:

```dart
'notifications': {
  'external_id_prefix': 'user_',
},
```

> [!WARNING]
> This has to match what your backend addresses. `magic-starter-laravel`'s `HasNotifications` composes `user_<id>`, so the default is correct against that backend, and changing one side alone means the server sends to an id no device carries. Nothing fails visibly when they disagree: the notification is accepted and delivered to nobody, and only a zero-recipient report on the server says so.
>
> A blank value resolves to `user_` rather than to no prefix, and surrounding whitespace is trimmed, because OneSignal rejects a bare numeric external id outright and the PHP side normalises the same way. Emptying this key does not switch the prefix off; it restores the default.

Change it when one OneSignal app serves more than one kind of subject, and change the backend with it. On the backend the key is `onesignal.external_id_prefix` in `config/magic-starter.php`.

`dart run magic:dowel starter:doctor` prints the prefix this config resolves to, so the two sides can be read against each other:

```text
Push external id prefix: user_ (default, key not set)
Push external id prefix: user_ (blank, using default)
Push external id prefix: operator-
```

The first two resolve to the same prefix and are not the same situation: the second means the value you wrote is being discarded, which "key not set" would hide.

It is printed rather than checked, and never fails: any prefix is valid as long as the backend uses the same one, and nothing inside this repository can see the other side. `--verbose` adds the key name and the backend key to compare it against. The value comes from the config file text, so an app that writes the key at runtime through `Config.set` is not covered (the command boots nothing and has no container to ask), and a whole-line `//` comment above the live key is skipped.

<a name="auth-identity-modes"></a>
## Auth Identity Modes

The `auth` block controls which identity fields the login and registration forms show:

```dart
'auth': {
  'email': true,
  'phone': false,
},
```

| `email` | `phone` | Result |
|:--------|:--------|:-------|
| `true` | `false` | Email only (default). |
| `false` | `true` | Phone only. |
| `true` | `true` | Both fields are offered; the payload carries every non-empty identity field and the backend decides which one identifies the account. |

Read the modes at runtime:

```dart
final emailEnabled = MagicStarterConfig.emailIdentity();
final phoneEnabled = MagicStarterConfig.phoneIdentity();
```

<a name="locale-timezone-defaults"></a>
## Locale & Timezone Defaults

```dart
'defaults': {
  'locale': 'en',
  'timezone': 'UTC',
},
'localization': {
  'apply_user_locale': true,
},
'supported_locales': [
  'en',
  'tr',
],
```

| Key | Default | Description |
|:----|:--------|:------------|
| `defaults.locale` | `'en'` | The language a release note or campaign falls back to when the backend sent none in the reader's own. |
| `defaults.timezone` | `'UTC'` | Read through `MagicStarterConfig.defaultTimezone()`; no screen in the package consumes it. |
| `localization.apply_user_locale` | `true` | Whether a signed-in user's saved `locale` attribute is applied to the running app automatically, on sign-in and on restore. Set `false` to own locale switching yourself. See [Locale Application](../architecture/manager.md#locale-application). |
| `supported_locales` | `['en', 'tr']` | Read through `MagicStarterConfig.supportedLocales()`; no screen in the package consumes it. The language picker lists `MagicStarter.localeOptions`, which comes from `useLocaleOptions()` or, without it, from magic's own `Lang.supportedLocales`. |

The `legal` block carries optional links shown on the registration screen and the billing page:

```dart
'legal': {
  'terms_url': 'https://example.com/terms',
  'privacy_url': 'https://example.com/privacy',
},
```

Both default to `null`, and a blank string reads as unset. `MagicStarterConfig.hasLegalLinks()` says whether at least one is set.

The `account` block names where a card-billed subscription is cancelled and the account deleted:

```dart
'account': {
  'deletion_url': 'https://app.example.com/account',
},
```

A refused account deletion offers that page as its one action; with `null` (the default), or a blank string, it offers none.

<a name="accessing-values"></a>
## Accessing Values

`MagicStarterConfig` carries the defaults and the types, so prefer it to raw `Config.get()`:

```dart
// Feature checks
final teamsEnabled = MagicStarterConfig.hasTeamFeatures();
final registrationEnabled = MagicStarterConfig.hasRegistrationFeatures();
final twoFactorEnabled = MagicStarterConfig.hasTwoFactorFeatures();

// Route paths
final loginPath = MagicStarterConfig.loginRoute();
final profilePath = MagicStarterConfig.profileRoute();

// Identity, defaults and legal links
final emailAuth = MagicStarterConfig.emailIdentity();
final locale = MagicStarterConfig.defaultLocale();
final termsUrl = MagicStarterConfig.termsUrl();
```

For dynamic access, or when you need the raw value, use dot notation:

```dart
final teamsEnabled = Config.get<bool>('magic_starter.features.teams', false);
final authPrefix = Config.get<String>('magic_starter.routes.auth_prefix', '/auth');
final termsUrl = Config.get<String?>('magic_starter.legal.terms_url', null);
```

<a name="related-documentation"></a>
## Related Documentation

- [Installation](installation.md): running the installer and bootstrapping the starter.
- [CLI Commands](../basics/cli.md): `starter:configure` and `starter:doctor`.
- [Authentication](../basics/authentication.md): the identity modes, social login and handoff in use.
- [Teams](../basics/teams.md): the team resolver and the billable subject.
- [Support](../basics/support.md): the support and store review keys.
- [Releases](../basics/releases.md): the changelog page and the update banner.
