# Installation

Add `magic_starter` to a Magic app, register its dowel commands with `plugin:install`, and let `starter:install` scaffold the config, middleware, models and routes for the features you choose.

- [Requirements](#requirements)
- [Installing the Package](#installing-the-package)
- [Running the Install Command](#running-the-install-command)
- [Registering the Service Provider](#registering-the-service-provider)
- [Injecting the Config Factory](#injecting-the-config-factory)
- [Bootstrapping the Starter](#bootstrapping-the-starter)
- [Related Documentation](#related-documentation)

<a name="requirements"></a>
## Requirements

The Dart and Flutter floors are inherited from `magic`: a package cannot resolve below its own dependency's floor.

| Dependency | Constraint |
|:-----------|:-----------|
| Dart SDK | `>=3.13.0 <4.0.0` |
| Flutter | `>=3.47.0` |
| `magic` | `^1.0.0` |
| `dowel` | `^1.0.0` |
| `magic_notifications` | `^1.0.0` |
| `magic_payments` | `^1.0.0` |
| `magic_picker` | `^1.0.0` |
| `magic_socket` | `^1.0.0` |
| `args` | `^2.7.0` |
| `path` | `^1.9.1` |
| `in_app_review` | `^2.0.12` |
| `package_info_plus` | `^10.2.2` |
| `web` | `^1.1.2` |

The UI is built on `wind_kit` and `material_ui`, which come with `magic`. The app must already be scaffolded by Magic (`lib/config/app.dart` present): run `dart run magic:dowel magic:install` first, see the [Magic installation guide](https://anilcancakir.com/magic/docs/getting-started/installation).

The package is the client of `magic-starter-laravel`'s `api/v1` routes: its controllers call them one to one, so the screens need that backend, or one that serves the same routes, to work.

<a name="installing-the-package"></a>
## Installing the Package

```bash
flutter pub add magic_starter
dart run magic:dowel plugin:install magic_starter --no-bootstrap
```

`plugin:install` registers `MagicStarterDowelProvider` under `.dowel/plugins.json` and injects `MagicStarterServiceProvider` into `lib/config/app.dart`. Without `--no-bootstrap` it also chains `starter:install` as the plugin's bootstrap command.

> [!WARNING]
> Pass `--no-bootstrap`. The chained run always receives `--non-interactive`, so it asks no questions and writes every feature as `false`. A later `starter:install --features=...` then skips the `lib/config/magic_starter.dart` and `lib/app/models/user.dart` that now exist, still prints that the installation completed, and leaves the features off. Run `starter:install` yourself, as below. If you already ran the chain, `starter:configure` (or editing `lib/config/magic_starter.dart`) turns on a feature that needs no scaffolding, but not teams: that also needs the `Team` model, the `User` team accessors, the `bootstrap()` team callbacks and `registerMagicStarterTeamRoutes()`, and without them the app throws on startup. For those, commit your changes and re-run `dart run magic:dowel starter:install --features=teams --force`, adding every other feature you want on, since the config is rewritten from that list; `--force` replaces the generated files, including `AppServiceProvider`, and overwrites the translation file.

The package has no executable of its own: every command is `dart run magic:dowel starter:<command>`.

<a name="running-the-install-command"></a>
## Running the Install Command

```bash
dart run magic:dowel starter:install
```

Interactively, the command asks one yes/no question per feature key and defaults every answer to no. For a scripted install pass the keys you want:

```bash
dart run magic:dowel starter:install --features=registration,teams,notifications
```

`--features` implies `--non-interactive`; a key you leave out is written as `false`. The accepted keys are the ones in the [feature toggles table](configuration.md#feature-toggles).

The command then:

1. **Validates** that `lib/config/app.dart` exists and stops when it does not.
2. **Writes** `lib/config/magic_starter.dart` with your selections, the `EnsureAuthenticated` and `RedirectIfAuthenticated` middleware under `lib/app/middleware/`, `lib/app/models/user.dart` (and `team.dart` when `teams` is on), `lib/resources/views/dashboard_view.dart` and `lib/routes/app.dart`. A file that already exists is skipped, except `lib/routes/app.dart`, which gets the dashboard route group injected instead.
3. **Injects** `MagicStarterServiceProvider` into `lib/config/app.dart`, the config import and `magicStarterConfig` factory into `lib/main.dart` (with a default `primary` palette passed as `windTheme`), the `auth` and `guest` aliases into `lib/app/kernel.dart` and the route registrations into `lib/app/providers/route_service_provider.dart`.
4. **Edits** `lib/app/providers/app_service_provider.dart`: it injects the `MagicStarter.bootstrap(...)` call and a navigation block into an existing file, or writes a full one when the file is missing or `--force` is passed.
5. **Merges** the starter's translation keys into `assets/lang/en.json` and registers that asset in the host `pubspec.yaml`.
6. **Adds** `magic_notifications` to the host `pubspec.yaml` when `notifications` is on, and prints the `notifications:install` command that finishes OneSignal setup.
7. **Runs** `dart format .` on the host project.

Every injection is idempotent: a second run does not duplicate a registration. Pass `--force` to overwrite files the command already generated (it also replaces `app_service_provider.dart` instead of injecting into it). `--dry-run` is not a full preview: it stages the file writes without writing them, but the in-place edits of `main.dart`, `kernel.dart`, the route provider, `AppServiceProvider`, the translations and `pubspec.yaml` still run. The other commands (`starter:configure`, `starter:doctor`, `starter:publish`, `starter:uninstall`) are documented in [CLI Commands](../basics/cli.md).

<a name="registering-the-service-provider"></a>
## Registering the Service Provider

The injected section of `lib/config/app.dart` looks like this:

```dart
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart'; // injected by install

final appConfig = {
  'app': {
    'name': Env.get('APP_NAME', 'My App'),
    'providers': [
      (app) => RouteServiceProvider(app),
      (app) => AppServiceProvider(app),
      (app) => MagicStarterServiceProvider(app), // injected by install
    ],
  },
};
```

`MagicStarterServiceProvider` binds `MagicStarterManager` under the `'magic_starter'` key and defines the `starter.*` Gate abilities; see [Service Provider](../architecture/service-provider.md).

<a name="injecting-the-config-factory"></a>
## Injecting the Config Factory

The config factory is added to `Magic.init()` in `lib/main.dart`:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:magic/magic.dart';
import 'config/app.dart';
import 'config/magic_starter.dart'; // injected by install

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Magic.init(
    configFactories: [
      () => appConfig,
      () => magicStarterConfig, // injected by install
    ],
  );

  runApp(MagicApplication(title: 'My App'));
}
```

The generated `lib/config/magic_starter.dart` and every key in it are described in [Configuration](configuration.md).

<a name="bootstrapping-the-starter"></a>
## Bootstrapping the Starter

Registering the provider is not enough. The starter also needs four host-owned things: how to build your user model, how to log out, which locales to offer and, when `teams` is on, how to read and switch teams. `MagicStarter.bootstrap()` registers them in one call from `AppServiceProvider.boot()`; the installer writes it for you.

```dart
class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  @override
  void register() {}

  @override
  Future<void> boot() async {
    MagicStarter.bootstrap(
      userFactory: (data) => User.fromMap(data),
      onLogout: () async {
        await Auth.logout();
        MagicRoute.to('/auth/login');
      },
      locales: {
        'en': 'English',
        'tr': 'Türkçe',
      },
    );
  }
}
```

That is the complete setup for a teamless app. With `magic_starter.features.teams` on, pass the three team callbacks as well:

```dart
MagicStarter.bootstrap(
  userFactory: (data) => User.fromMap(data),
  onLogout: () async => Auth.logout(),
  locales: {
    'en': 'English',
    'tr': 'Türkçe',
  },
  currentTeam: () => User.current.currentTeam?.toMagicStarterTeam(),
  allTeams: () =>
      User.current.allTeams.map((t) => t.toMagicStarterTeam()).toList(),
  onSwitch: (id) => MagicStarter.switchTeam('$id'),
);
```

The team callbacks are a group: pass all three or none.

| Situation | Result |
|:----------|:-------|
| Teams off, team callbacks omitted | Valid. No team resolver is registered and no team UI renders. |
| Teams on, all three callbacks passed | Valid. The team selector, team switching and team settings work. |
| Teams on, team callbacks omitted | Throws a `StateError` naming the missing call and the config flag. |
| Only some of the three callbacks passed | Throws an `ArgumentError`; the manager is left untouched. |

`bootstrap()` also takes the optional `onLogin` and `onGuestClaimed` callbacks, described in [Manager](../architecture/manager.md#login-callback).

The individual setters (`useUserModel()`, `useLogout()`, `useLocaleOptions()`, `useTeamResolver()`) stay public. Call one after `bootstrap()` to replace what it registered, for example to register the team resolver once your own team store is warm:

```dart
MagicStarter.useTeamResolver(
  currentTeam: () => TeamStore.instance.current?.toMagicStarterTeam(),
  allTeams: () => TeamStore.instance.all,
  onSwitch: (id) => TeamStore.instance.switchTo(id),
);
```

> [!WARNING]
> Do not skip `userFactory`. Without it the starter falls back to its own `MagicStarterAuthUser`, so every screen keeps rendering while silently reading the wrong user model. `bootstrap()` makes that omission impossible: the parameter is required.

`bootstrap()` covers the identity contract only. The optional presentation setters (`useNavigation()`, `useTheme()`, `useWindTheme()`, `useHeader()`, `useSocialAuth()` and the per-surface theme setters) stay separate and are called alongside it.

<a name="related-documentation"></a>
## Related Documentation

- [Configuration](configuration.md): feature toggles, route prefixes and identity modes.
- [CLI Commands](../basics/cli.md): every `starter:*` command and flag.
- [Manager](../architecture/manager.md): the registrations `AppServiceProvider.boot()` makes.
- [View Registry](../architecture/view-registry.md): overriding a screen.
- [Magic installation guide](https://anilcancakir.com/magic/docs/getting-started/installation): scaffolding the host app.
