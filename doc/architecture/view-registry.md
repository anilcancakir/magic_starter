# View Registry

`MagicStarterViewRegistry` is the string-keyed factory that every starter route resolves its screens, layouts and modals through, so a host app can swap any of them without touching routes or controllers.

- [Introduction](#introduction)
- [MagicStarterViewRegistry Class](#magicstarterviewregistry-class)
    - [Registering Views](#registering-views)
    - [Registering Layouts](#registering-layouts)
    - [Registering Modals](#registering-modals)
    - [Checking Existence](#checking-existence)
    - [Building Widgets](#building-widgets)
    - [Clearing the Registry](#clearing-the-registry)
- [Default View Keys](#default-view-keys)
- [Default Layout Keys](#default-layout-keys)
- [Default Modal Keys](#default-modal-keys)
- [Overriding Views](#overriding-views)
    - [Composing a Settings Page](#composing-a-settings-page)
- [Overriding Layouts](#overriding-layouts)
- [Overriding Modals](#overriding-modals)
- [Builder Slots](#builder-slots)
- [Route Integration](#route-integration)
- [Testing](#testing)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

Routes and controllers never construct a screen: they ask the registry for a key such as `auth.login` and the registry calls the builder registered under it. The package registers its own builders, a host replaces the ones it wants, and everything else keeps the default.

The registry lives at `lib/src/ui/magic_starter_view_registry.dart` and is held by `MagicStarterManager`, reachable as `MagicStarter.view`.

<a name="magicstarterviewregistry-class"></a>
## MagicStarterViewRegistry Class

The registry keeps four internal maps: view builders, layout builders, modal builders and slot builders. The builder typedefs:

```dart
typedef MagicStarterViewBuilder = Widget Function();
typedef MagicStarterLayoutBuilder = Widget Function(Widget child);
typedef MagicStarterModalBuilder = Widget Function();
typedef MagicStarterSlotBuilder = Widget Function(BuildContext context);
```

<a name="registering-views"></a>
### Registering Views

```dart
void register(String key, MagicStarterViewBuilder builder)
```

Stores a view builder under the key. A key that already exists is replaced.

<a name="registering-layouts"></a>
### Registering Layouts

```dart
void registerLayout(String key, MagicStarterLayoutBuilder builder)
```

Stores a layout builder. A layout builder receives the page as `child` and wraps it in a shell (sidebar, header, footer).

<a name="registering-modals"></a>
### Registering Modals

```dart
void registerModal(String key, MagicStarterModalBuilder builder)
```

Stores a modal builder under the key. A key that already exists is replaced.

<a name="checking-existence"></a>
### Checking Existence

```dart
bool has(String key)       // true when a view builder exists for key
bool hasLayout(String key) // true when a layout builder exists for key
bool hasModal(String key)  // true when a modal builder exists for key
```

`registerDefaultViews()` uses them to register a default only when the key is absent.

<a name="building-widgets"></a>
### Building Widgets

```dart
Widget make(String key)
Widget makeLayout(String key, {required Widget child})
Widget makeModal(String key)
```

All three throw a `StateError` when the key is not registered:

```dart
throw StateError('No view builder registered for key "$key".');
```

> [!NOTE]
> A `StateError` from `make()` usually means a feature flag is off. Feature-gated views are only registered when the matching `MagicStarterConfig.has*Features()` returns `true` at the moment the manager is built.

<a name="clearing-the-registry"></a>
### Clearing the Registry

```dart
void clear()
```

Removes every view, layout, modal and slot builder. `MagicStarterManager.reset()` calls it and then registers the defaults again.

<a name="default-view-keys"></a>
## Default View Keys

`MagicStarterManager.registerDefaultViews()` registers the default views when the manager is built. Each key, its view class and the feature that registers it are listed in [Default Views](manager.md#default-views).

The notification screens (`notifications.list`, `notifications.preferences`) are not on this registry. Both belong to `magic_notifications` and live on its own `Notify.view`, which has the same shape (`register`, `has`, `make`, `slot`, `buildSlot`, `clear`). `registerMagicStarterNotificationRoutes()` re-registers them there wrapped in this package's page geometry unless the host already overrode the key; see [Notifications](../basics/notifications.md).

<a name="default-layout-keys"></a>
## Default Layout Keys

| Key | Layout | Purpose |
|:----|:-------|:--------|
| `layout.app` | `MagicStarterAppLayout` | Authenticated pages: sidebar, header, bottom navigation |
| `layout.guest` | `MagicStarterGuestLayout` | Auth pages: centred card, minimal chrome |

<a name="default-modal-keys"></a>
## Default Modal Keys

| Key | Modal | Purpose |
|:----|:------|:--------|
| `modal.confirm` | `MagicStarterConfirmDialog` | Generic confirmation with a `ConfirmDialogVariant` (primary, danger, warning) |
| `modal.password_confirm` | `MagicStarterPasswordConfirmDialog` | Password prompt with inline error handling |
| `modal.two_factor` | `MagicStarterTwoFactorModal` | The two-factor setup wizard (QR code, code confirm, recovery codes) |

<a name="overriding-views"></a>
## Overriding Views

Register your builder through `MagicStarter.view`:

```dart
// In AppServiceProvider.boot()
MagicStarter.view.register(
  'auth.login',
  () => const MyCustomLoginView(),
);
```

`register()` replaces whatever is there, and `registerDefaultViews()` never overwrites an existing key, so an override wins whether it lands before or after the defaults. Register overrides in your `AppServiceProvider.boot()`: the facade resolves the manager bound by `MagicStarterServiceProvider`, and calling it earlier would use a throwaway fallback manager instead.

Override only the views you want to change. The rest keep the package defaults.

<a name="composing-a-settings-page"></a>
### Composing a Settings Page

The settings hub (`settings.hub`, routed at `/settings`) is three sections: Account, Security and Preferences. Each is a public widget that carries its own header, rows and gating, so a host that wants one settings page with sections of its own registers its view under `settings.hub` and places the starter's groups beside its sections, without copying a feature or ability check:

```dart
class AppSettingsView extends StatelessWidget {
  const AppSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MSPageScaffold(
      title: trans('magic_starter.nav.settings'),
      children: [
        MSSettingsSection(
          header: 'Playback',
          children: [
            MSSettingsNavRow(title: 'Player', to: '/settings/player'),
          ],
        ),
        MagicStarterSettingsAccountGroup(),
        if (MagicStarterSettingsSecurityGroup.hasRows)
          MagicStarterSettingsSecurityGroup(),
        MagicStarterSettingsPreferencesGroup(),
        if (MagicStarterConfig.hasReleasesFeatures())
          const MagicStarterAppVersion(),
      ],
    );
  }
}

// In AppServiceProvider.boot()
MagicStarter.view.register('settings.hub', () => const AppSettingsView());
```

| Widget | Rows and their gates |
|:-------|:---------------------|
| `MagicStarterSettingsAccountGroup` | Profile (always); for a guest (denied `starter.delete-account`) also the upgrade and sign-in rows |
| `MagicStarterSettingsSecurityGroup` | Two-factor (`two_factor` and `starter.manage-two-factor`), Password (`starter.update-password`), Browser sessions (`sessions`), Connected accounts (`social_login` and a `MagicStarter.useSocialAuth` bridge) |
| `MagicStarterSettingsPreferencesGroup` | Appearance (always), Notifications (`notifications`), Language (`extended_profile`), Timezone (`timezones`), Newsletter (`newsletter` and `starter.manage-newsletter`), What's new (`releases`) |

- The Security group renders a zero-size box when none of its rows is reachable. `MSPageScaffold` still puts a gap around a zero-size child, so guard the group with `hasRows`; the other two always have a row.
- The groups read the user, the abilities and the flags when they build and listen to none of them. Leave them non-const when the page is rebuilt on an auth change, or the Profile subtitle and the two-factor value keep what they read first.
- The version caption is not part of a group: place `MagicStarterAppVersion` yourself, as above, to close the page the way the hub does.

<a name="overriding-layouts"></a>
## Overriding Layouts

Replace the layout wrapper for guest or authenticated pages:

```dart
MagicStarter.view.registerLayout(
  'layout.guest',
  (child) => MyGuestLayout(child: child),
);

MagicStarter.view.registerLayout(
  'layout.app',
  (child) => MyAppLayout(child: child),
);
```

The layout builder receives the page as `child` and must render it somewhere in the layout tree.

> [!NOTE]
> When you override `layout.app`, your layout is responsible for navigation, header and responsive behaviour. The controllers still work; only the shell changes. Keep your authenticated route groups on the `MagicStarterLayoutIds.app` layout id so they share one shell with the starter's pages.

### The child arrives route-keyed

`makeLayout` wraps `child` in a `KeyedSubtree` keyed on the current route path before the builder sees it, so your layout renders it wherever you like and keeps the per-route remount the default layouts carry. You do not add the key yourself and should not strip it.

It matters because a layout is persistent: one element holds one child slot that every route in the group takes turns in. Without the key that slot is reused across routes, and swapping one scrollable view for another tears down render objects in a confused order under accumulated navigation. The wrap goes around the child rather than around your layout's result, so your navigation chrome is not torn down on a route change.

<a name="overriding-modals"></a>
## Overriding Modals

Replace the modal registered under a key:

```dart
MagicStarter.view.registerModal(
  'modal.confirm',
  () => const MyCustomConfirmDialog(),
);
```

> [!TIP]
> Override a modal when you need a completely different dialog. For style-only changes (colours, fonts, borders, presentation as a sheet), use `MagicStarter.useModalTheme()`; it needs no override. See [Modal Theme](manager.md#modal-theme).

<a name="builder-slots"></a>
## Builder Slots

A slot injects a widget into a named insertion point of a starter view without overriding the whole view. A slot builder is a `Widget Function(BuildContext)`.

```dart
MagicStarter.view.slot('auth.login', 'header', (context) {
  return WText('Welcome back!', className: 'text-2xl font-bold text-center');
});

MagicStarter.view.slot('settings.hub', 'footer', (context) {
  return MyHelpSection();
});
```

`slot()` takes the view key, the slot name and the builder. Slots are stored under the compound key `'<viewKey>.<slotName>'`, for example `'auth.login.header'`.

A view asks for its slots while it builds:

```dart
// Inside a view's build method
final headerSlot = MagicStarter.view.buildSlot('auth.login', 'header', context);
```

`buildSlot()` returns `null` when no slot is registered, and `hasSlot(viewKey, slot)` answers whether one is. Register slots before the view is built, in `AppServiceProvider.boot()`. `clear()` removes slots too, and registering a view again does not bring them back.

| View key | Slots |
|:---------|:------|
| `auth.login`, `auth.register` | `header`, `formFooter`, `footer` |
| `auth.forgot_password`, `auth.reset_password`, `auth.two_factor_challenge`, `auth.otp_verify` | `header`, `footer` |
| `settings.hub`, `profile.profile`, `teams.create`, `teams.invitation_accept` | `header`, `footer` |
| `teams.settings` | `header`, `footer`, `afterSection:members` |
| `teams.billing` | `plan_card_highlight`, a builder that renders inside one plan card |

> [!TIP]
> Use slots for small, targeted additions (a banner, a section, extra fields). For a structural change, override the whole view with `MagicStarter.view.register()`.

<a name="route-integration"></a>
## Route Integration

Starter routes resolve views and layouts through the registry. The auth routes go through the controller, whose page methods call `MagicStarter.view.make`:

```dart
// MagicStarterAuthController
Widget login() => MagicStarter.view.make('auth.login');
```

and every route group wraps its pages in a registry layout:

```dart
MagicRoute.group(
  middleware: ['auth'],
  layoutId: MagicStarterLayoutIds.app,
  layout: (child) => MagicStarter.view.makeLayout('layout.app', child: child),
  routes: () {
    MagicRoute.page(
      MagicStarterConfig.profileRoute(),
      () => MagicStarter.view.make('profile.profile'),
    );
  },
);
```

Route files import controllers and string keys, never view classes, so the registry resolves the plugin default or the host's override at runtime. Your own authenticated routes use the same `layout` and `layoutId` to land inside the starter's shell.

<a name="testing"></a>
## Testing

`MagicStarterManager.reset()` clears the registry and registers the defaults again. Bind a fresh manager in `setUp()` to isolate tests:

```dart
setUp(() {
  MagicApp.reset();
  Magic.flush();
  setUpMagicStarterForTests(); // binds a default MagicStarterManager()
});
```

To test with a custom view:

```dart
test('uses the custom login view when overridden', () {
  MagicStarter.view.register(
    'auth.login',
    () => const Text('Custom Login'),
  );

  final widget = MagicStarter.view.make('auth.login');
  expect(widget, isA<Text>());
});
```

To verify that a missing key throws:

```dart
test('throws StateError for an unregistered key', () {
  MagicStarter.view.clear();
  expect(
    () => MagicStarter.view.make('auth.login'),
    throwsStateError,
  );
});
```

<a name="related-documentation"></a>
## Related Documentation

- [Manager](manager.md): the singleton that holds the registry and registers the default views.
- [Service Provider](service-provider.md): the bootstrap that builds the manager.
- [Views and Layouts](../basics/views-and-layouts.md): how the starter's own views are built.
- [Notifications](../basics/notifications.md): the two screens that live on `Notify.view`.
- [Magic service container](https://anilcancakir.com/magic/docs/architecture/service-container): singleton bindings.
