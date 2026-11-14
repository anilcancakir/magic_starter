<p align="center">
  <img src="https://raw.githubusercontent.com/anilcancakir/magic_starter/master/.github/magic-logo.svg" width="120" alt="Magic Starter logo" />
</p>

<h1 align="center">Magic Starter</h1>

<p align="center">
  <strong>Ship sign-in, settings and teams without writing the screens.</strong><br/>
  Ready-made Magic screens for authentication, profile and security settings, teams, notifications, billing and support, each behind an opt-in feature toggle and each replaceable from your app through a view registry. The screens are the client of <code>magic-starter-laravel</code>'s <code>api/v1</code> routes.
</p>

<p align="center">
  <a href="https://pub.dev/packages/magic_starter"><img src="https://img.shields.io/pub/v/magic_starter.svg" alt="pub package"></a>
  <a href="https://github.com/anilcancakir/magic_starter/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/anilcancakir/magic_starter/ci.yml?branch=master&label=CI" alt="CI"></a>
  <a href="https://codecov.io/gh/anilcancakir/magic_starter"><img src="https://codecov.io/gh/anilcancakir/magic_starter/graph/badge.svg" alt="codecov"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://pub.dev/packages/magic_starter/score"><img src="https://img.shields.io/pub/points/magic_starter" alt="pub points"></a>
</p>

<p align="center">
  <a href="https://anilcancakir.com/magic_starter">Documentation</a> ·
  <a href="https://pub.dev/packages/magic_starter">pub.dev</a> ·
  <a href="https://github.com/anilcancakir/magic_starter/issues">Issues</a>
</p>

## At a glance

| Fact | Value |
|---|---|
| Package | [`magic_starter`](https://pub.dev/packages/magic_starter) |
| Install | `flutter pub add magic_starter`, then `dart run magic:dowel plugin:install magic_starter --no-bootstrap` and `dart run magic:dowel starter:install --features=...` |
| Import | `package:magic_starter/magic_starter.dart`; `package:magic_starter/cli.dart` for the dowel provider alone; `package:magic_starter/previews.dart` for dev-only component previews |
| Entry points | `MagicStarterServiceProvider` (wiring), `MagicStarter` (facade: `bootstrap`, `view`, theme setters), `MagicStarterConfig` (toggles and routes), `registerMagicStarter*Routes()`, `EnsureAuthenticated`, `RedirectIfAuthenticated`; the `starter:*` commands |
| Platforms | Pure Dart, no native code: every platform Flutter and `magic` run on. Billing checks out through Stripe on the web and through the store on mobile (`magic_payments`); the store review prompt and the web update banner are platform-specific (see [Features](#features)). |
| Requires | Dart >=3.13, Flutter >=3.47, `magic` ^1.0.0, and a backend serving `magic-starter-laravel`'s `api/v1` routes for anything that signs in |
| Dependencies | `magic`, `magic_notifications`, `magic_payments`, `magic_picker`, `magic_socket`, `wind_kit`, `material_ui`, `dowel`, `in_app_review`, `package_info_plus`, `web`, `args`, `path` |
| License | MIT |

## Install

```bash
flutter pub add magic_starter
dart run magic:dowel plugin:install magic_starter --no-bootstrap
dart run magic:dowel starter:install --features=registration,teams,notifications
```

`plugin:install` registers `MagicStarterDowelProvider` under `.dowel/plugins.json` and injects `MagicStarterServiceProvider` into `lib/config/app.dart`. Pass `--no-bootstrap`: without it, `plugin:install` chains `starter:install` and always forwards `--non-interactive`, so the chained run asks nothing and writes every feature as `false`. A later `starter:install --features=...` then skips the config file that now exists (and `lib/app/models/user.dart`) and still reports success, so the features stay off. Run `starter:install` yourself, with `--features=` naming the keys you want (a key you leave out is written as `false`) or without it to answer one yes/no question per feature. If you already ran the chain, turn features on with `dart run magic:dowel starter:configure --teams`, edit `lib/config/magic_starter.dart`, or re-run `starter:install --features=... --force`, which overwrites the files it generated and replaces `app_service_provider.dart` instead of injecting into it.

`starter:install` writes `lib/config/magic_starter.dart`, the `auth` and `guest` middleware, a `User` model (and `Team` with `teams` on), a dashboard and `lib/routes/app.dart`, and injects the config factory into `lib/main.dart`, the middleware aliases into `lib/app/kernel.dart`, the route registrations into the route service provider, a `MagicStarter.bootstrap(...)` call into `AppServiceProvider` and the starter's English strings into `assets/lang/en.json`. The app must already be a Magic app: run `dart run magic:dowel magic:install` first. `dart run magic:dowel starter:doctor` checks the result.

## Bootstrap

Tell the starter how to build your user, how to sign out and which languages to offer, from `AppServiceProvider.boot()`. The installer writes this call for you.

```dart
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  @override
  void register() {}

  @override
  Future<void> boot() async {
    MagicStarter.bootstrap(
      // Your own model; `User` is the host's class.
      userFactory: (data) => User.fromMap(data),
      onLogout: () async {
        await Auth.logout();
        MagicRoute.to(MagicStarterConfig.loginRoute());
      },
      locales: {
        'en': 'English',
        'tr': 'Türkçe',
      },
    );
  }
}
```

| Member | Meaning |
|--------|---------|
| `MagicStarter.bootstrap(userFactory:, onLogout:, locales:)` | The identity contract in one call. Optional: `onLogin`, `onGuestClaimed`, and the team trio `currentTeam`, `allTeams`, `onSwitch`. |
| `MagicStarter.switchTeam(id)` | Switches the current team on the backend and re-identifies the store billing rail; route the `onSwitch` callback through it. |
| `MagicStarter.beforeLogout(hook)` | Runs before the sign-out, while the token still works. |
| `MagicStarter.isReady` | `false` while `teams` is on and no team resolver is registered. |

Failure modes:

| Situation | What happens |
|-----------|--------------|
| Some but not all three team callbacks | `bootstrap()` throws `ArgumentError` before it changes anything. |
| `teams` on and no team callbacks | `bootstrap()` throws `StateError` naming the flag. |
| No `bootstrap()` or `useUserModel()` at all | Every screen reads the starter's own `MagicStarterAuthUser` instead of your model, silently. |
| `MagicStarterServiceProvider` not registered | `MagicStarter` falls back to a default manager and prints one debug warning; the auth listeners, the push identity and the `starter.*` Gate abilities are never wired. |

## Features

Every toggle in `lib/config/magic_starter.dart` defaults to `false`. A toggle that is off registers no route and no view key and shows no UI.

| Toggle | Turns on |
|--------|----------|
| `registration` | The register route. |
| `email_verification` | The verify-email page and resend. |
| `two_factor` | Two-factor setup, the challenge screen and recovery codes. |
| `phone_otp` | The phone one-time code sign-in. |
| `guest_auth` | "Continue as guest" on login, and claiming the guest's data at the next sign-in. |
| `social_login` | Provider buttons, the Connected accounts page and provider confirmation. Needs a bridge from `MagicStarter.useSocialAuth(...)`; `magic_social_auth` publishes one. |
| `handoff` | `/auth/handoff?code=&next=`: a one-time code from another surface becomes a session after a "Sign in as ...?" question. |
| `extended_profile`, `profile_photos`, `timezones` | Phone, language and timezone fields, the photo upload, the timezone search. |
| `sessions`, `newsletter` | The sessions list with revoke, the newsletter toggle. |
| `teams` | Team create, settings, invitations and switching. Needs the team callbacks. |
| `notifications` | `magic_notifications`' list, bell and preferences in the app shell, and the push identity of a signed-in device. |
| `billing` | The `teams.billing` view over `magic_payments`. Needs `billing.web_origin`. |
| `support`, `support_csat`, `support_feedback`, `support_attachments`, `support_client_context`, `support_chat` | The support desk and its options; every option needs `support`. |
| `store_review` | The native review prompt and the Rate us item; Android, iOS and macOS, never on the web. |
| `releases`, `app_update` | A "What's new" page and version caption; an update banner (a new web deploy from `version.json`, a newer store build). |

Failure modes:

| Situation | What happens |
|-----------|--------------|
| `MagicStarter.view.make(key)` for a feature that is off | Throws `StateError`; check `MagicStarterConfig.has<Feature>Features()` first. |
| `social_login` on, no bridge | No provider buttons and no hub row render. The flag alone does nothing visible. |
| `billing` on, `billing.web_origin` unset or relative | Checkout fails at Stripe and the error is only logged: the button does nothing. `starter:doctor` reports the missing key. |
| `billing` on | `lib/` registers the `teams.billing` view key and no route. Register a page of yours at `MagicStarterConfig.billingRoute()` (`routes.billing`, default `/teams/billing`) that builds `MagicStarter.view.make('teams.billing')`, or the upgrade prompts lead nowhere. |
| `notifications.external_id_prefix` differs from the backend's `MAGIC_STARTER_EXTERNAL_ID_PREFIX` | OneSignal accepts the id and delivers to nobody. Both default to `user_`. |
| `support` turned on after install | Call `registerMagicStarterSupportRoutes()` yourself, or the Support menu item leads nowhere. |

The full key list, the route prefixes and the billing, push, handoff and legal keys: [Configuration](https://anilcancakir.com/magic_starter/docs/getting-started/configuration).

## Routes and middleware

The route groups ask for the `auth` and `guest` middleware by alias, and each registration function returns early when its feature is off.

```dart
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void registerStarter() {
  Kernel.registerAll({
    'auth': () => EnsureAuthenticated(),
    'guest': () => RedirectIfAuthenticated(),
  });

  registerMagicStarterAuthRoutes();
  registerMagicStarterProfileRoutes();
  registerMagicStarterTeamRoutes();
  registerMagicStarterNotificationRoutes();
  registerMagicStarterSupportRoutes();
}
```

| Member | Meaning |
|--------|---------|
| `registerMagicStarterAuthRoutes()` | Login, forgot and reset password always; register, two-factor challenge, OTP, verify email and handoff behind their toggles. Under `routes.auth_prefix`. |
| `registerMagicStarterProfileRoutes()` | The settings hub and its sub-pages under `routes.profile_prefix`. |
| `registerMagicStarterTeamRoutes()`, `registerMagicStarterNotificationRoutes()`, `registerMagicStarterSupportRoutes()` | No-ops while `teams`, `notifications` or `support` is off. |
| `EnsureAuthenticated` | Sends a signed-out visitor to `routes.login` and remembers where they were going. |
| `RedirectIfAuthenticated` | Sends a signed-in visitor to `routes.home`; a guest session is let through. |

Failure mode: an `auth` or `guest` alias nobody registered is unresolvable, and magic's `Kernel.resolveAll` throws `StateError` for it. `starter:install` writes both into `lib/app/kernel.dart`.

## View registry

Replace a screen, a layout or a modal by key, or add a widget to a named slot of a shipped screen, from a provider's `boot()`. Defaults register only when a key is still free, so the order of providers does not matter.

```dart
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void customiseStarter() {
  // Your own screen; `MyLoginView` is the host's widget.
  MagicStarter.view.register('auth.login', () => const MyLoginView());

  MagicStarter.view.slot('auth.login', 'header', (context) {
    return WText('Welcome back', className: 'text-2xl font-bold text-fg');
  });
}
```

| Member | Meaning |
|--------|---------|
| `register(key, builder)`, `registerLayout(key, builder)`, `registerModal(key, builder)` | Replace a view, a layout (`layout.app`, `layout.guest`) or a modal (`modal.confirm`, `modal.password_confirm`, `modal.two_factor`). |
| `make(key)`, `makeLayout(key, child:)`, `makeModal(key)` | Build one; throws `StateError` for a key nobody registered. |
| `has(key)`, `hasLayout(key)`, `hasModal(key)` | Whether a key is registered. |
| `slot(viewKey, slotName, builder)`, `buildSlot(...)` | A widget inside a shipped view; a slot name the view does not read is inert. |

The settings surface is `settings.hub` plus drill-down keys (`profile.profile`, `settings.appearance`, `settings.security.*`, ...). The notification screens are not on this registry: override them on `magic_notifications`' `Notify.view`. Every key and slot: [View Registry](https://anilcancakir.com/magic_starter/docs/architecture/view-registry). To own a screen's source instead, `dart run magic:dowel starter:publish --tag=views:auth.login` copies it into `lib/resources/views/starter/` and registers it; a published copy does not follow later releases.

## Theming

The screens are built with Wind and the `MS`-prefixed components. Adopt your Wind palette in one call, then set the button and field standards, which that call resets.

```dart
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void themeStarter(WindThemeData windTheme) {
  MagicStarter.useWindTheme(windTheme);

  MagicStarter.useButtonTheme(
    const MagicStarterButtonTheme(shapeClassName: 'rounded-full'),
  );

  MagicStarter.manager.pageContainerClassName =
      'max-w-6xl px-4 lg:px-8 pt-6 pb-16';
}
```

| Member | Meaning |
|--------|---------|
| `useWindTheme(WindThemeData)` | Derives every colour-bearing sub-theme from the palette's semantic aliases (`bg-surface`, `text-fg`, `bg-primary`, ...). |
| `useTheme(MagicStarterTheme)` | Sets every sub-theme at once. |
| `useNavigationTheme`, `useModalTheme`, `useFormTheme`, `useAuthTheme`, `useCardTheme`, `usePageHeaderTheme`, `useLayoutTheme`, `useDropdownTheme`, `useButtonTheme`, `useFieldTheme` | Set one sub-theme. |
| `MagicStarter.manager.pageContainerClassName` | The width cap and padding every page shares; set it from your own pages' string. |
| `MagicStarterTokens.defaultAliases` | The semantic aliases the components resolve; pass them as `WindThemeData(aliases: ...)`. |

Failure modes:

| Situation | What happens |
|-----------|--------------|
| `useButtonTheme()` or `useFieldTheme()` before `useWindTheme()` or `useTheme()` | The later call resets them to their defaults, without an error. |
| `useFormTheme(MagicStarterFormTheme(inputClassName: ...))` | Every field you left out goes back to its default; change one with `MagicStarter.formTheme.copyWith(...)` (the modal theme has `copyWith` too). |
| A Wind alias the palette lacks | Wind drops it silently and the class paints nothing. |

The derivation table: [wind_kit Theme Adoption](https://anilcancakir.com/magic_starter/docs/guides/wind-theme-adoption).

## The backend

The controllers call `magic-starter-laravel`'s `api/v1` routes one to one through magic's `Http` facade, with the base URL from `network.drivers.api.base_url`: `POST /auth/login`, `POST /auth/register`, `POST /auth/two-factor-challenge`, `PUT /user/profile`, `GET /teams/{team}/members`, `PUT /user/current-team`, and the rest. A feature you turn on here needs its feature on the backend too (`config/magic-starter.php` there), or its routes answer 404. The billing screen buys through `magic_payments` and the notification screens read through `magic_notifications`, both against the same backend. Without a backend the screens render and every submit shows the request's error.

## CLI

| Command | Does |
|---------|------|
| `dart run magic:dowel starter:install` | Scaffolds and injects the starter; `--features=`, `--non-interactive`, `--force`, `--dry-run`. `--dry-run` is not a full preview: it stages the file writes without writing them, but the in-place edits of `main.dart`, `kernel.dart`, the route provider, `AppServiceProvider`, the translations and `pubspec.yaml` still run. |
| `dart run magic:dowel starter:configure` | `--show` prints the toggles; `--teams`, `--two-factor`, ... turn a toggle on (turn one off by editing the file). |
| `dart run magic:dowel starter:doctor` | Checks the install; also the read-only MCP tool `starter_doctor`. |
| `dart run magic:dowel starter:publish` | `--tag=config`, `views`, `layouts`, `middleware`, `lang` or `all`, with a scope such as `views:auth`. |
| `dart run magic:dowel starter:uninstall` | Removes the config file, the dependency and the injected registrations; lists the `AppServiceProvider` code, middleware files and strings to remove by hand. `--force` skips the prompt. |

## For AI coding agents

| Do | Because |
|----|---------|
| Import only `package:magic_starter/magic_starter.dart` (or `cli.dart` from a pure Dart dispatcher) | Everything under `src/` is private. |
| Call `MagicStarter.bootstrap(...)` with the host's own `userFactory` | Without it every screen reads `MagicStarterAuthUser` and nothing fails. |
| Pass all three team callbacks or none, and route `onSwitch` through `MagicStarter.switchTeam('$id')` | A partial set throws; a direct controller call skips the store rail re-identify. |
| Check `MagicStarterConfig.has<Feature>Features()` before linking to or building a gated view | A key of a feature that is off is not registered and `make()` throws. |
| Override a screen with `MagicStarter.view.register` and a notification screen with `Notify.view.register` | The notification screens live on `magic_notifications`' registry. |
| Use `settings.hub` and the `settings.*` and `profile.profile` keys for the settings surface | `profile.settings` is not a registered default key. |
| Call `useButtonTheme()` and `useFieldTheme()` after `useWindTheme()` or `useTheme()` | The unified calls reset them. |
| Set `billing.web_origin` to an absolute URL with `billing` on | Stripe rejects a relative return URL and the failure is only logged. |
| Keep `notifications.external_id_prefix` equal to the backend's `MAGIC_STARTER_EXTERNAL_ID_PREFIX` | A mismatch delivers pushes to nobody. |
| Run commands as `dart run magic:dowel starter:<command>` | The package has no executable of its own. |
| Never fake a sign-in in a test or a demo; bind a fake `NetworkDriver` and assert the request | Every flow concludes through the backend's answer. |

## Dependencies

`magic` for the container, routing, `Auth`, `Http` and Wind (through `wind_kit` and `material_ui`); `magic_notifications` for the notification screens, polling and push; `magic_payments` for the billing rails; `magic_picker` for photo and attachment picking; `magic_socket` for the support desk's live refresh; `dowel` for the `starter:*` commands; `in_app_review` for the store review prompt; `package_info_plus` for the build number in the version caption and support context; `web` for the web update banner; `args` and `path` for the CLI.

## Links

- [Documentation](https://anilcancakir.com/magic_starter/docs/getting-started/installation): installation, configuration, every feature, the view registry, theming and the CLI
- [API reference](https://pub.dev/documentation/magic_starter/latest/)
- [llms.txt](llms.txt) and the [agent skill](skills/magic-starter/SKILL.md) for AI coding agents: `npx skills add anilcancakir/magic_starter`
- [Changelog](CHANGELOG.md)
- [Report an issue](https://github.com/anilcancakir/magic_starter/issues)
- [Security policy](SECURITY.md)

## License

MIT, see [LICENSE](LICENSE). Built by [Anılcan Çakır](https://anilcancakir.com).
