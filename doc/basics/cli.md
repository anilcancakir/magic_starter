# CLI Commands

The `starter:*` commands that scaffold, configure, diagnose, publish and remove the starter inside a Magic application, run through `dart run magic:dowel`.

- [Introduction](#introduction)
- [Quick Reference](#quick-reference)
- [Install Command](#install-command)
    - [What It Creates](#what-it-creates)
    - [What It Injects](#what-it-injects)
    - [Flags](#install-flags)
- [Configure Command](#configure-command)
    - [Show Current Config](#show-current-config)
    - [Toggle Features](#toggle-features)
    - [Non-Interactive Mode](#non-interactive-mode)
- [Doctor Command](#doctor-command)
    - [Health Checks](#health-checks)
    - [Verbose Mode](#verbose-mode)
- [Publish Command](#publish-command)
    - [Publish Tags](#publish-tags)
- [Uninstall Command](#uninstall-command)
- [Stub Templates](#stub-templates)
- [Testing CLI Commands](#testing-cli-commands)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

The package has no executable of its own. `MagicStarterDowelProvider` contributes its commands to the host app's `dowel` registry, so they run as `dart run magic:dowel starter:<command>`. `dart run magic:dowel plugin:install magic_starter` registers the provider and then chains `starter:install` as the plugin's bootstrap command; pass `--no-bootstrap` to `plugin:install` to skip that chain.

Each command extends `DowelCommand` (install extends `DowelInstallCommand`), declares a `signature` DSL string for its arguments and flags, and implements `handle(DowelContext ctx)`. Every command resolves the host project root through `FileHelper.findProjectRoot()`.

<a name="quick-reference"></a>
## Quick Reference

| Command | Purpose |
|:--------|:--------|
| `starter:install` | Scaffolds config, middleware, models, dashboard and routes, and injects the registrations into existing host files. |
| `starter:configure` | Turns feature flags on in `lib/config/magic_starter.dart`; `--show` prints the current state. |
| `starter:doctor` | Checks the installation; also exposed as the read-only MCP tool `starter_doctor`. |
| `starter:publish` | Copies views, layouts, middleware, config or translations into the host for customisation. |
| `starter:uninstall` | Removes the files and injections `starter:install` made. |

<a name="install-command"></a>
## Install Command

```bash
dart run magic:dowel starter:install
```

The installer validates the host project, asks which features to enable (one yes/no prompt per feature key), generates files from stubs and injects registrations into existing files. It throws when `lib/config/app.dart` is missing, which means the host has not been scaffolded: run `dart run magic:dowel magic:install` first.

<a name="what-it-creates"></a>
### What It Creates

Each file is written only when it does not exist yet, or when `--force` is passed:

| File | Purpose |
|:-----|:--------|
| `lib/config/magic_starter.dart` | Feature toggle configuration with the selected features enabled |
| `lib/app/middleware/ensure_authenticated.dart` | Auth guard middleware |
| `lib/app/middleware/redirect_if_authenticated.dart` | Guest redirect middleware |
| `lib/app/models/user.dart` | User model |
| `lib/app/models/team.dart` | Team model (only when `teams` is enabled) |
| `lib/resources/views/dashboard_view.dart` | Dashboard view scaffold |
| `lib/routes/app.dart` | App routes file with the dashboard inside the authenticated layout |
| `lib/app/providers/app_service_provider.dart` | Created from a stub; an existing file is injected into instead, unless `--force` replaces it |
| `assets/lang/en.json` | Translation strings, deep-merged into an existing file |

<a name="what-it-injects"></a>
### What It Injects

Beyond creating files, the installer modifies existing host files. Each injection checks for its own marker first, so a re-run adds nothing twice:

- **`lib/config/app.dart`**: adds `MagicStarterServiceProvider` to the providers list (the `install.yaml` manifest step).
- **`lib/main.dart`**: adds the `magicStarterConfig` factory to the config factories, a `WindThemeData` with a `primary` palette passed to `MagicApplication`, and the `config/magic_starter.dart` and `material_ui` imports.
- **`lib/app/kernel.dart`**: registers the `auth` (`EnsureAuthenticated`) and `guest` (`RedirectIfAuthenticated`) middleware aliases.
- **`lib/app/providers/route_service_provider.dart`**: adds `registerMagicStarterAuthRoutes()` and `registerMagicStarterProfileRoutes()`, plus the team, notification and support route registrations when those features are enabled.
- **`lib/app/providers/app_service_provider.dart`**: injects `MagicStarter.bootstrap(...)` (and `MagicStarter.useNavigation(...)`) into `boot()` unless the provider already configures the starter.
- **`pubspec.yaml`**: lists `assets/lang/en.json` under `flutter: assets:`, and adds `magic_notifications` when `notifications` is enabled.

```dart
// Injected into lib/config/app.dart
MagicStarterServiceProvider(),

// Injected into lib/main.dart
() => magicStarterConfig,
```

<a name="install-flags"></a>
### Flags

| Flag | Description |
|:-----|:------------|
| `--force` | Overwrite existing generated files and replace `app_service_provider.dart` instead of injecting into it |
| `--dry-run` | Stages the transactional writes (config, middleware, models, dashboard, routes, provider registration) without writing them. The in-place edits of `main.dart`, `kernel.dart`, the route provider, `AppServiceProvider`, the translations and `pubspec.yaml` still run. |
| `--non-interactive` | Skip the prompts; every feature stays off unless `--features` names it |
| `--no-bootstrap` | Inherited from `DowelInstallCommand`; read by `plugin:install`, which is what chains this command |
| `--features` | Comma-separated feature keys; passing it implies `--non-interactive` |

```bash
# Interactive installation (prompts for each feature)
dart run magic:dowel starter:install

# Non-interactive with specific features
dart run magic:dowel starter:install --features=teams,notifications,registration

# Force overwrite existing files
dart run magic:dowel starter:install --force
```

> [!TIP]
> With `notifications` enabled the installer does not run the `magic_notifications` installer. It adds the dependency to `pubspec.yaml` and prints `dart run magic:dowel notifications:install --app-id=<your-onesignal-app-id>`, because OneSignal needs an app id only you have.

<a name="configure-command"></a>
## Configure Command

```bash
dart run magic:dowel starter:configure
```

Updates individual feature flags in `lib/config/magic_starter.dart` without modifying any other file. It exits with an error when that file does not exist. With no flag it prints a warning and changes nothing.

<a name="show-current-config"></a>
### Show Current Config

```bash
dart run magic:dowel starter:configure --show
```

Prints every feature key found in the config file with its status:

```
Current Magic Starter Feature Configuration:

Feature        Status
-------------  --------
teams          enabled
social_login   disabled
...
```

<a name="toggle-features"></a>
### Toggle Features

```bash
# Enable teams and notifications
dart run magic:dowel starter:configure --teams --notifications
```

| CLI Flag | Config Key |
|:---------|:-----------|
| `--teams` | `teams` |
| `--social-login` | `social_login` |
| `--two-factor` | `two_factor` |
| `--sessions` | `sessions` |
| `--phone-otp` | `phone_otp` |
| `--newsletter` | `newsletter` |
| `--notifications` | `notifications` |
| `--email-verification` | `email_verification` |

> [!NOTE]
> Only flags you pass are touched; the rest stay as they are. The command rewrites the Dart source with a regular expression through `MagicStarterConfigHelper.updateFeature()`. Features without a flag here (registration, billing, support and the rest) are edited in the config file by hand.

The signature declares these as plain flags, so a flag can only turn a feature on from the command line. To turn one off, edit `'<key>': false` in `lib/config/magic_starter.dart`.

<a name="non-interactive-mode"></a>
### Non-Interactive Mode

The configure command never prompts: it works entirely through flags. That makes it safe for CI pipelines and scripts.

<a name="doctor-command"></a>
## Doctor Command

```bash
dart run magic:dowel starter:doctor
```

Runs independent checks that the starter was installed correctly. It exits with code 0 when every required check passes and code 1 otherwise. The same report is available to agents as the MCP tool `starter_doctor`, which takes an optional `verbose` boolean.

<a name="health-checks"></a>
### Health Checks

| Check | What It Verifies |
|:------|:-----------------|
| Magic Framework | `lib/config/app.dart` exists |
| Starter Config | `lib/config/magic_starter.dart` exists |
| Provider | `MagicStarterServiceProvider` appears in `lib/config/app.dart` |
| Config Factory | `magicStarterConfig` appears in `lib/main.dart` |
| Middleware | `EnsureAuthenticated` appears in `lib/app/kernel.dart` |
| Routes | `registerMagicStarterAuthRoutes` appears in `route_service_provider.dart` |
| Facade | `app_service_provider.dart` calls `MagicStarter.bootstrap(` or one of the legacy `useUserModel`, `useLocaleOptions`, `useLogout` setters |
| Translations | `assets/lang/en.json` exists |
| Billing web origin | Reported and required only when `billing` is enabled: `billing.web_origin` must be set to a non-empty value |

Three more lines appear only when relevant and never fail the command: a `Support routes: WARN` line when `support` is enabled but `registerMagicStarterSupportRoutes()` is not called, a `Push external id prefix` line when `notifications` is enabled (the prefix must equal the backend's `onesignal.external_id_prefix`), and a `Published Views` list that marks a published view `WARN` when `AppServiceProvider` does not register it.

```
Magic Framework: OK
Starter Config: OK
Provider: OK
Config Factory: OK
Middleware: OK
Routes: OK
Facade: FAIL
Translations: OK

Missing Requirements:
  FAIL MagicStarter facade not configured in app_service_provider.dart

1 check(s) failed. Run `dart run magic:dowel starter:install` to fix.
```

<a name="verbose-mode"></a>
### Verbose Mode

```bash
dart run magic:dowel starter:doctor --verbose
```

Shows the file inspected for each check and the string searched for:

```
Provider: OK
    File: lib/config/app.dart
    Contains: MagicStarterServiceProvider
```

<a name="publish-command"></a>
## Publish Command

```bash
dart run magic:dowel starter:publish
```

Copies plugin source files into the host application for customisation, the starter's equivalent of Laravel's `vendor:publish`. Without `--tag` it publishes every group. When views or layouts are published, the command registers them in `AppServiceProvider` (`MagicStarter.view.register(...)` and `registerLayout(...)`) so the registry serves your copy.

<a name="publish-tags"></a>
### Publish Tags

```bash
# Publish everything
dart run magic:dowel starter:publish

# Publish only views
dart run magic:dowel starter:publish --tag=views

# One module, one view, one layout
dart run magic:dowel starter:publish --tag=views:auth
dart run magic:dowel starter:publish --tag=views:auth.login
dart run magic:dowel starter:publish --tag=layouts:app

# Overwrite existing files
dart run magic:dowel starter:publish --force
```

| Tag | What It Publishes |
|:----|:------------------|
| `config` | `lib/config/magic_starter.dart` |
| `views` | View files to `lib/resources/views/starter/` |
| `layouts` | `app` and `guest` layouts to `lib/resources/layouts/starter/` |
| `middleware` | Auth middleware files to `lib/app/middleware/` |
| `lang` | Translation file to `assets/lang/en.json` |
| `all` (default) | All of the above |

A `views:<scope>` scope is either one registry key (`auth.login`) or a module prefix (`auth`) taken from the command's view map; an unknown scope prints an error. Views with no entry in that map, such as the handoff page, are published only by the unscoped `views` tag.

> [!NOTE]
> Without `--force`, existing files are skipped with a warning. The command reports the number of published files at the end.

> [!NOTE]
> A published file is a snapshot of the release that published it. A later release that changes a view or a layout does not reach your copy: read the CHANGELOG entry for the edits it names, or re-publish with `--force` and re-apply your own changes.

<a name="uninstall-command"></a>
## Uninstall Command

```bash
dart run magic:dowel starter:uninstall
```

Performs a reverse of the install command. It removes generated files and cleans up injected lines from host config files while keeping user code intact. It lists what it will remove and asks for confirmation first.

What it removes:

- `lib/config/magic_starter.dart`
- The `magic_starter` dependency from `pubspec.yaml`
- The `MagicStarterServiceProvider` import and registration from `lib/config/app.dart`
- The `magicStarterConfig` import and factory from `lib/main.dart`
- The middleware aliases and imports from `lib/app/kernel.dart`
- The route imports and registrations from `route_service_provider.dart`

```bash
# Skip the confirmation prompt
dart run magic:dowel starter:uninstall --force
```

Each removal step is wrapped in error handling, so already-clean projects and partial installations do not crash the command. Afterwards `dart format .` runs automatically.

> [!TIP]
> The uninstall command does not remove your `AppServiceProvider` integrations, the middleware files or the translation entries. It lists them as manual cleanup once it finishes.

<a name="stub-templates"></a>
## Stub Templates

Generated files are built from stub templates in the `assets/stubs/install/` directory:

| Stub | Output |
|:-----|:-------|
| `magic_starter_config.stub` | `lib/config/magic_starter.dart` |
| `ensure_authenticated.stub` | `lib/app/middleware/ensure_authenticated.dart` |
| `redirect_if_authenticated.stub` | `lib/app/middleware/redirect_if_authenticated.dart` |
| `user.stub` | `lib/app/models/user.dart` |
| `team.stub` | `lib/app/models/team.dart` |
| `app_service_provider.stub` | `lib/app/providers/app_service_provider.dart` |
| `dashboard_view.stub` | `lib/resources/views/dashboard_view.dart` |
| `app_routes.stub` | `lib/routes/app.dart` |
| `en.stub` | `assets/lang/en.json` |

Stub paths are resolved relative to the plugin package at runtime. The installer searches two locations through `getStubSearchPaths()`: the plugin's `assets/stubs` found through `.dart_tool/package_config.json`, then `assets/stubs` under the current directory.

> [!NOTE]
> Stubs are plain Dart and JSON files with placeholder tokens that the installer replaces based on the selected features. Never hardcode absolute stub paths; resolve them through the package config.

<a name="testing-cli-commands"></a>
## Testing CLI Commands

Commands expose overridable methods so a test can isolate them from the real filesystem:

```dart
class TestableInstallCommand extends MagicStarterInstallCommand {
  final String _testRoot;

  TestableInstallCommand(this._testRoot);

  @override
  String getProjectRoot() => _testRoot;

  @override
  List<String> getStubSearchPaths() => [
    '$_testRoot/stubs',
  ];

  @override
  Future<ProcessResult> runDartFormat(String rootPath) async {
    return ProcessResult(0, 0, '', ''); // No-op in tests
  }
}
```

| Method | Commands | Purpose |
|:-------|:---------|:--------|
| `getProjectRoot()` | All | Redirect to a temp directory |
| `getStubSearchPaths()` | Install | Point to test stub fixtures |
| `resolveManifestPath()` | Install | Point to a test `install.yaml` |
| `runDartFormat()` | Install, Uninstall | Skip formatting in tests |
| `getPluginSourceDir()` | Publish | Point to a test plugin source |

> [!TIP]
> The doctor command's check methods (`checkConfigExists()`, `checkProviderRegistered()` and the rest) take a root path, so they are testable without subclassing.

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Running `dart run magic_starter install` | The package has no executable. Every command is `dart run magic:dowel starter:<command>`. |
| Passing `--no-teams` (or any `--no-` form) to `starter:configure` | The flags are not negatable, so the parser rejects them. Set `'<key>': false` in `lib/config/magic_starter.dart` to turn a feature off. |
| Expecting `starter:configure` to toggle every feature | Only the flags in the table have one. `registration`, `billing`, `support` and the others are edited in the config file. |
| Running `starter:install` before the host is scaffolded | It throws when `lib/config/app.dart` is missing. Run `dart run magic:dowel magic:install` first. |
| Expecting `--features` to leave the prompts on | Passing `--features` skips them, and every key it does not name is written as `false`. |
| Expecting `starter:uninstall` to remove everything | `AppServiceProvider` integrations, middleware files and translation entries stay; it prints them as manual cleanup. |

<a name="related-documentation"></a>
## Related Documentation

- [Installation](../getting-started/installation.md): adding the package and registering the plugin.
- [Configuration](../getting-started/configuration.md): the feature keys the config file carries.
- [Views and Layouts](./views-and-layouts.md): overriding a screen without publishing it.
- [Service Provider](../architecture/service-provider.md): what `MagicStarterServiceProvider` registers.
