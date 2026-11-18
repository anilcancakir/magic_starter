# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.4.0] - 2026-11-18

### Added

- **`MagicStarter.signOut()` signs a user out the way the starter's own button does.** It runs the before-logout hooks once, then the `useLogout()` callback when one is set, or `MagicStarterAuthController.instance.logout()` otherwise (which runs the hooks itself). The profile dropdown now calls it instead of its own copy of that branch. `lib/src/magic_starter_manager.dart`, `lib/src/facades/magic_starter.dart`.
- **`MagicStarter.isGuest()` answers whether the signed-in user is a guest session.** It reads `is_guest` from `Auth.user()`, whichever model `useUserModel()` registered, and is `false` with nobody signed in. The starter's own reads of the flag on the signed-in user go through it. `lib/src/facades/magic_starter.dart`.

### Changed

- **The handoff's Continue over an open session signs out through `MagicStarter.signOut()`.** Every host that passes `onLogout` to `bootstrap()` (it is required there) or calls `useLogout()` now has that callback run on the handoff, after the before-logout hooks, where before the handoff always took `MagicStarterAuthController.instance.logout()` and skipped it. The callback therefore has to end the session itself with `Auth.logout()`, as it already did for the profile dropdown. `lib/src/http/controllers/magic_starter_handoff_controller.dart`.

## [1.3.3] - 2026-11-17

### Fixed

- **Leaving a page that reads `GoRouterState.of` in `build` no longer freezes the app under go_router 18.** `MagicStarter.view.makeLayout` wrapped the child in a `KeyedSubtree` keyed on the route path, and that child is go_router's shell navigator. go_router 18.1.4 keys the navigator's state on its navigator key, so the path key recreated that state on every route change while the `Navigator` survived, and the outgoing page rebuilt against a state registry that did not know it: `GoRouterState.of` looped forever. `makeLayout` now hands the layout the child unchanged, which go_router already mounts as one page per route. A host that registered its own layout through `registerLayout` no longer gets a path key it did not add, and must not add one. `lib/src/ui/magic_starter_view_registry.dart`.

## [1.3.2] - 2026-11-16

### Fixed

- **The account menu uses the height of the window instead of stopping at 400 px.** `WPopover` caps its overlay at 400 px unless `maxHeight` says otherwise, and `MSUserProfileDropdown` never did, so a menu with notifications, support and feedback on kept its rows in a 233 px strip on a 1440 by 900 window, with the last ones behind a scroll. The popover now takes the window height as its ceiling and still shrinks to the room on its side of the trigger, so a short window scrolls the rows and sign out stays pinned. The language is not the cause: a row is 52 px in English and in the longer labels it was tried with. WPopover picks the side it opens on from the same ceiling, so a trigger in the middle of a tall window now opens towards the roomier side. `lib/src/ui/components/user_profile_dropdown/user_profile_dropdown.dart`.
- **The password field in the confirm dialog has a name for screen readers.** `MagicStarterPasswordConfirmDialog` gave its `WFormInput` neither a label nor a placeholder, so every action that confirms an account's password announced an unnamed text field next to a named eye. The field now carries the `attributes.password` placeholder, which Wind also uses as its accessible name; the empty field shows that word. `lib/src/ui/widgets/magic_starter_password_confirm_dialog.dart`.
- **The remember me label on the login screen wraps instead of overflowing.** The checkbox shares its row with the forgot-password link and gets about half of the form, and the label was not flexible, so a translation wider than that ran past the edge of a phone. The label now carries a `flex-initial` class token ahead of the theme's `checkboxLabelClassName`, so it wraps, and a host class with a `flex-*` token of its own still wins instead of landing in a second wrapper. `lib/src/ui/views/auth/magic_starter_login_view.dart`.

## [1.3.1] - 2026-11-16

### Fixed

- **The newsletter label on the register screen wraps instead of overflowing.** The checkbox sat in a row that gave it an unbounded width and the label was not flexible, so a label wider than a phone (the Turkish "Ürün güncellemelerine ve haberlere abone ol" at 390 px, or a longer `MagicStarter.useNewsletterLabel` text) ran 5 px past the card edge, was clipped and raised a `RenderFlex overflowed` error. The label is `Flexible` inside a bounded box now, so it breaks onto a second line. (`lib/src/ui/views/auth/magic_starter_register_view.dart`)

## [1.3.0] - 2026-11-16

### Added

- **`MagicStarterPasswordToggle`, the show-or-hide eye for a password field.** Pass it as a `WFormInput` `suffix` with `obscured` and `onToggle`. It carries the name from `magicStarterPasswordToggleName` and a 44 px box below `lg` (40 px from `lg` up) around the 20 px glyph. A published view uses it through the barrel. (`lib/src/ui/widgets/magic_starter_password_toggle.dart`)

### Fixed

- **The password eyes are no longer 20 px tap targets.** Every eye (the login, register, reset, change-password and profile views and the password confirm dialog) was a bare `WAnchor` around the icon, so the tappable area and the node a tap-target audit measures were 20 by 20. They all use `MagicStarterPasswordToggle` now, so each is at least 44 px square below `lg` and 40 px from `lg` up. A field with an eye is as tall as that box: 44 px below `lg`, 40 px from `lg` up, which is a few pixels taller than a plain field of the default form theme. Fixes #276. (`lib/src/ui/views/`, `lib/src/ui/widgets/magic_starter_password_confirm_dialog.dart`)
- **The password eyes on the profile screens are named for screen readers.** The seven show-or-hide toggles on the settings view (current, new and confirmation password, and the two guest upgrade fields) and the guest upgrade fields on the profile sub-page were bare icons, read as an unlabelled button; each now carries `magicStarterPasswordToggleName`, which flips between "Show password" and "Hide password" with the field. No new keys: the helper falls back to English. (`lib/src/ui/views/profile/`)
- **Every icon-only control name goes through `magicStarterControlName`.** The app layout, the team selector and the account dropdown each carried their own copy of the "catalogue line or English default" check, and three labels called `trans()` with no fallback: the dropdown's "Toggle theme" row and the collapsible sidebar's expand and collapse control, so a host installed before those keys existed showed the raw key. They read "Toggle theme", "Expand sidebar" and "Collapse sidebar" now when the catalogue lacks the key. (`lib/src/ui/layouts/magic_starter_app_layout.dart`, `lib/src/ui/components/`)

## [1.2.0] - 2026-11-16

### Added

- **`magicStarterControlName` and `magicStarterPasswordToggleName` name an icon-only control for a screen reader.** `magicStarterControlName(key, fallback)` answers the translation of `key` when the app's language files hold it and `fallback` otherwise, so a host that has not added the key reads an English name, never the raw key. `magicStarterPasswordToggleName(obscured:)` answers `auth.show_password` while the field is hidden and `auth.hide_password` while it is shown, each with an English default. Both are exported from the barrel so a published view and a host screen can use them. (`lib/src/support/control_name.dart`)

### Fixed

- **The icon-only controls on the auth screens are named for screen readers.** The theme toggle on the auth form card and the show-or-hide eye on every password field (login, register, reset password, the password settings page and the password confirmation dialog) had no accessible name and read as an unlabelled button. The toggle takes `common.toggle_theme`; the eye takes `auth.show_password` or `auth.hide_password`, naming the action its next tap performs, so the label flips with the field. Both new keys ship in the install stub; an app installed before them gets the English names, never the raw keys, until it adds them to its own language files. (`lib/src/ui/widgets/magic_starter_auth_form_card.dart`, `lib/src/ui/views/auth/`, `lib/src/ui/views/settings/security/magic_starter_password_view.dart`, `lib/src/ui/widgets/magic_starter_password_confirm_dialog.dart`)

## [1.1.2] - 2026-11-16

### Changed

- **`starter:install --features=...` no longer skips an existing config in silence.** `plugin:install` chains `starter:install --non-interactive`, which writes `lib/config/magic_starter.dart` with every feature off, and a later `starter:install --features=teams` then skipped the config that existed by then and still reported success, so the features stayed off. When the explicit `--features` selection differs from the flags in the existing config, the command now leaves the file alone, prints the features whose setting differs and the way out (commit, then pass `--force` to rewrite the config from the list, which also replaces the generated files, `AppServiceProvider` included; `starter:configure` only for a feature that needs no scaffolding, which teams does not), and exits `1`. A selection the config already holds still succeeds (a re-run is idempotent), `--force` still rewrites the config, and a run without `--features` keeps leaving an existing config alone. A script that ran `starter:install --features=...` on top of an existing config and read exit `0` as applied now gets exit `1`. (`lib/src/cli/commands/magic_starter_install_command.dart`, `install.yaml`, `README.md`, `llms.txt`, `skills/magic-starter/SKILL.md`, `doc/getting-started/installation.md`)

## [1.1.1] - 2026-11-16

### Fixed

- **`MSSegmentedControl` tells a screen reader which segment is selected.** The `selected:` look was painted only, so "Monthly" and "Annual" read alike whichever one was chosen. Each segment now carries `Semantics(selected:)` on its own button node (merged, so the node's name is still the label), true for the one at `selectedIndex` and false for the rest, including a `selectedIndex` that names no segment. Nothing changes visually or in the layout. (`lib/src/ui/components/segmented_control/segmented_control.dart`)

## [1.1.0] - 2026-11-15

### Added

- **Every theme sub-theme has a `copyWith`, and the layout theme resolves its backgrounds.** `MagicStarterNavigationTheme`, `MagicStarterCardTheme`, `MagicStarterPageHeaderTheme`, `MagicStarterLayoutTheme`, `MagicStarterAuthTheme`, `MagicStarterDropdownTheme`, `MagicStarterButtonTheme` and `MagicStarterFieldTheme` join the form and modal themes, so a one-field override keeps the rest: `MagicStarter.useLayoutTheme(MagicStarter.layoutTheme.copyWith(navigationBreakpoint: 'sm'))`. `MagicStarterLayoutTheme.contentBackgroundColor(context)` and `drawerBackgroundColor(context)` resolve the two background pairs for the current brightness and accept a `#hex` in either half; both layouts paint through them. (`lib/src/configuration/magic_starter_theme.dart`, `lib/src/ui/layouts/`)

### Changed

- **The barrel exports what a publishable view or layout reads:** `NavigatesRoutes` and `MagicStarterNextPath` (the login and register views), `MagicStarterBreakpoints` (the app layout), `confirmAndDeleteAccount` (the profile view) and `MSConfirmDialog` (the billing view). A published copy reaches them without importing from `src/`. (`lib/magic_starter.dart`)

### Fixed

- **The platform statement says what pub.dev lists.** The README and `llms.txt` claimed every platform Flutter and `magic` run on; pana's static import-graph check lists Android and iOS only (it drops Windows and Linux at `purchases_flutter` through `magic_payments`, macOS at `url_launcher_windows` and the web at `path_provider`), and the text now says so. The skill's backend-contract reference gains the map from each Flutter feature key to the backend feature name, and marks `registration`, `store_review` and `support_chat` as having no backend toggle (`app_update` has none either, but its store banner needs the backend `releases` feature). The dependency comments in `pubspec.yaml` describe the 1.x floors instead of the 0.x history. (`README.md`, `llms.txt`, `skills/magic-starter/references/backend-contract.md`, `pubspec.yaml`)
- **The config that `starter:publish --tag=config` copies turns every feature off.** The published `lib/config/magic_starter.dart` switched `registration`, `extended_profile`, `social_login` and `notifications` on, while the documentation says every feature defaults to `false` and a screen appears only when its toggle is on. All four are `false` now, so a fresh publish shows no screen the app did not enable. An app that already published the file keeps its own values. (`lib/config/magic_starter.dart`)
- **`useWindTheme()` no longer discards sub-theme fields a host set before it, and it now themes the drawer and content backgrounds.** The derived values land only on fields the host has not set: a field is the host's when it differs from its sub-theme's default and from what the previous `useWindTheme()` derived, so `useLayoutTheme()`, `useNavigationTheme()` and the other setters called before it keep their fields. A setter called after it still assigns its whole struct, so build that struct with `copyWith` on the active theme. A field set to exactly its stock default, or to exactly what the previous `useWindTheme()` derived for it, reads as unset, and the next `useWindTheme()` replaces it; to keep such a value, set a different one, or set it again after `useWindTheme()` with `copyWith`. A layout background's colour and shade count as one field, a host value stays the host's when a later palette derives the same value, and the drawer and content backgrounds follow the last `bg-` utility of each brightness in `bg-surface`, as Wind paints it. This changes one documented behaviour: a button or field theme set before `useWindTheme()` is now kept rather than reset. `useTheme()` still replaces every sub-theme. The drawer and content area backgrounds now follow the theme's `bg-surface` role instead of staying stock grey. (#149; `lib/src/magic_starter_manager.dart`, `lib/src/facades/magic_starter.dart`, `lib/src/configuration/magic_starter_theme.dart`)
- **The documentation now matches what the package does.** An unset or empty `billing.web_origin` hides the web checkout button; a relative value reaches Stripe, which refuses it, and the error is only logged; the origin must be absolute. With both identity modes on, login and registration send every non-empty identity field rather than preferring the phone. `plugin:install` injects `(app) => MagicStarterServiceProvider(app),`. A disabled feature's path hits the router's not-found handling instead of throwing; only `MagicStarter.view.make` throws. The middleware `starter:install` writes records no intended URL and does not let a guest through; the package classes do. The login sample says `magic-starter-laravel` up to 0.0.64 ignores `remember_me`, and the controller's doc comments say every non-empty identity field is sent. The README names the `MagicStarterBillingController` registration, links the agent skill on GitHub, and `doc/basics/components.md` documents `package:magic_starter/previews.dart`. (`README.md`, `llms.txt`, `doc/`, `skills/magic-starter/`)
- **The compact sidebar rail and the icon-only shell controls are named for screen readers.** A compact rail item announces its destination (with its badge count). The phone header's menu button, the drawer's close button, the notification bell, the account avatar and the compact rail's team switcher (which also carries the team's name) take names from the new `nav.open_menu`, `nav.close_menu`, `nav.notifications`, `nav.account_menu` and `nav.team_menu` keys in the install stub, falling back to English rather than the raw key when an app's language files lack them. (#150; `lib/src/ui/layouts/magic_starter_app_layout.dart`, `lib/src/ui/components/user_profile_dropdown/user_profile_dropdown.dart`, `lib/src/ui/components/team_selector/team_selector.dart`, `assets/stubs/install/en.stub`)
- **A view or layout published with `starter:publish` compiles in your app.** The command copied the file byte for byte, so its relative imports (`'../../../configuration/magic_starter_config.dart'`) pointed at paths that do not exist under `lib/resources/`, and every published view and layout failed to compile. The registration it added to `AppServiceProvider` broke the app as well: the provider imports the package barrel, which exports the original class under the same name, so the call was an ambiguous import. A published file's relative imports now become `import 'package:magic_starter/magic_starter.dart';` where the barrel covers the target and a `package:magic_starter/src/...` URI where it does not (only the support screens' helper widgets, which the unscoped `views` tag publishes), and the registration imports your copy `as published`. If an earlier publish left an unprefixed registration in `AppServiceProvider`, delete that import and its `register` or `registerLayout` line and publish again with `--force`. (`lib/src/cli/commands/magic_starter_publish_command.dart`)

## [1.0.0] - 2026-11-14

### BREAKING

- **The CLI moved from `fluttersdk_artisan` to `dowel`.** The provider is renamed to `MagicStarterDowelProvider` (`lib/src/cli/starter_dowel_provider.dart`, exported from `package:magic_starter/cli.dart`); re-run `dart run magic:dowel plugin:install magic_starter` to register it under `.dowel/`. The commands are run as `dart run magic:dowel starter:<command>`, and the read-only `starter_doctor` MCP tool routes through `dowel:starter:doctor`. (`lib/src/cli/`, `lib/cli.dart`, `install.yaml`)
- **Wind moved to `wind_kit` and Material to `material_ui`.** `fluttersdk_wind` is replaced by `wind_kit ^1.12.0`, and every Material import now comes from `package:material_ui/material_ui.dart`, which `material_ui ^1.11.0` provides. `starter:install` writes the `material_ui` import into a host's `main.dart` and `AppServiceProvider`, swaps a host's `package:flutter/material.dart` import in those files for it (both define `MaterialColor` and `Colors`, so keeping the two would make the generated theme ambiguous), and adds `material_ui ^1.11.0` to the host's `pubspec.yaml`. The SDK floor is Dart 3.13 and Flutter 3.47. (`pubspec.yaml`, `lib/`, `assets/stubs/install/`)

### Changed

- **First stable release: version 1.0.0 replaces the planned 0.1.0 and requires `magic ^1.0.0` and `dowel ^1.0.0`; no API change beyond what is listed below.**
- **Now depends on `magic ^1.0.0`, `magic_picker` and `magic_socket`.** `Pick` (attachments, profile photo) comes from `package:magic_picker/magic_picker.dart` and `BroadcastListeners` (support sync) from `package:magic_socket/magic_socket.dart`, since core 1.0.0 no longer ships either. (`pubspec.yaml`, `lib/src/support/support_sync.dart`, `lib/src/ui/views/support/magic_starter_support_attachments.dart`, `lib/src/ui/views/profile/`)
- **The package page and every documentation link name the new location under `https://anilcancakir.com/magic/starter`.** (`pubspec.yaml`, `README.md`, `llms.txt`, `doc/`, `skills/`, `tool/check-docs.py`)
- **Package metadata names the new owner.** The pub.dev description is rewritten, and the homepage, repository and issue tracker point at `anilcancakir`. (`pubspec.yaml`)
- **`starter:configure` accepts `--no-<feature>` on a real command line.** dowel registers a signature flag as non-negatable, so `--no-teams` (the form the usage and the docs show) was rejected with "Could not find an option named"; the command now registers the eight feature flags as negatable. (`lib/src/cli/commands/magic_starter_configure_command.dart`)
- **Direct dependencies raised to the latest release.** `path ^1.9.1`, `web ^1.1.2` and dev `test ^1.32.0`. (`pubspec.yaml`)
- **The dashboard `starter:install` scaffolds links to the current Magic pages.** Its Documentation, GitHub and CLI Commands cards open `https://anilcancakir.com/magic/docs/getting-started/installation`, `https://github.com/anilcancakir/magic` and `https://anilcancakir.com/magic/docs/packages/magic-cli`, and the CLI card names `dart run magic:dowel list`. (`assets/stubs/install/dashboard_view.stub`)
- **The `plugin:install` message says what the chained `starter:install` really does.** The chain runs non-interactively and writes every feature `false`, and a later `starter:install --features=...` skips the config file that exists by then unless `--force` is passed; the message now points at `starter:configure` or `--no-bootstrap`. (`install.yaml`)
- **`starter:install` names the right command when the host is not a Magic app.** The error says to run `dart run magic:dowel magic:install`, not `magic install`. (`lib/src/cli/commands/magic_starter_install_command.dart`)

## Older releases

Releases 0.0.73 and older are in [CHANGELOG-ARCHIVE.md](CHANGELOG-ARCHIVE.md).
