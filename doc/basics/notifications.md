# Notifications

How the starter mounts the `magic_notifications` screens and bell, runs the polling lifecycle, and declares the push identity of a signed-in device.

- [Introduction](#introduction)
- [Real-Time Polling](#real-time-polling)
- [Push Identity](#push-identity)
- [Notification List](#notification-list)
- [Notification Preferences](#notification-preferences)
- [Notification Dropdown](#notification-dropdown)
- [Notification Type Icons](#notification-type-icons)
- [Overriding a Screen](#overriding-a-screen)
- [Feature Gate](#feature-gate)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

The notification UI belongs to the `magic_notifications` package, which provides `NotificationsListView`, `NotificationPreferencesView`, `NotificationPreferencesController` and `NotificationDropdown`. This package ships none of them.

What stays here is what a notifications package cannot know on its own: `registerMagicStarterNotificationRoutes()` owns the paths (`MagicStarterConfig.notificationsRoute()` and `MagicStarterConfig.notificationPreferencesRoute()`, `/notifications` and `/settings/notifications` by default), mounts them inside the authenticated `layout.app` shell behind the `auth` middleware, and wraps the package's screens in this package's own page geometry (`MSPageContainer`) so they read like every other page in the app rather than spreading full-bleed. `MagicStarterAppLayout` owns the polling lifecycle and renders the bell, and `MagicStarterServiceProvider` declares the push identity.

The feature is opt-in behind `magic_starter.features.notifications`. When it is on, the layout starts polling and renders the bell; the routes resolve through `Notify.view`, not `MagicStarter.view`.

<a name="real-time-polling"></a>
## Real-Time Polling

Notification polling is managed by `MagicStarterAppLayout`. When the authenticated layout mounts and the notifications feature is on, it calls `Notify.startPolling()`, which fetches notifications at a regular interval. Polling stops when the layout is disposed:

```dart
@override
void initState() {
  super.initState();

  if (MagicStarterConfig.hasNotificationFeatures()) {
    Notify.startPolling();
  }
}

@override
void dispose() {
  if (MagicStarterConfig.hasNotificationFeatures()) {
    Notify.stopPolling();
  }
  super.dispose();
}
```

`Notify.startPolling()` is idempotent: calling it again has no effect. It also triggers an immediate fetch so the UI has data without waiting for the first interval tick. The layout wraps both calls in a `try`/`catch` so a test environment where Magic is not fully initialised does not fail; your own test teardown should still call `Notify.stopPolling()` with a silent catch to avoid a timer leak.

<a name="push-identity"></a>
## Push Identity

`magic_notifications` declares no push identity of its own; the starter does. `MagicStarterServiceProvider` listens to `Auth.stateNotifier` and, on every bump while the notifications feature is on, calls `Notify.initializePush('<prefix><Auth.id()>')`. That covers a password, social, two-factor, OTP or guest sign-in and the restore of a stored session at launch. The call is safe to repeat: the manager returns early when the intent is unchanged.

- **Prefix.** `magic_starter.notifications.external_id_prefix`, default `user_`; a blank value reads as the default. The backend must produce the same string: `onesignal.external_id_prefix` in `config/magic-starter.php` (`MAGIC_STARTER_EXTERNAL_ID_PREFIX`). A mismatch is accepted by OneSignal and delivered to nobody. `starter:doctor` prints the prefix it finds in the config.
- **Guests.** A guest session is declared as nobody: it releases any identity instead of subscribing a throwaway id.
- **Sign-out.** Any transition to signed-out releases the identity, including account deletion and the sign-out `AuthInterceptor` performs after a failed token refresh. `MagicStarterAuthController.logout()` also calls `Notify.logoutPush()` and `Notify.stopPolling()` first.
- **Push state.** When the notifications package is bound and `notifications.push_state.report_path` is configured, the provider registers `Notify.pushState.release` as a before-logout hook (see [Before-Logout Hooks](./authentication.md#before-logout-hooks)).

<a name="notification-list"></a>
## Notification List

`NotificationsListView` (from `magic_notifications`) is a full-page view that lists notifications with server-side pagination. It supports mark-as-read, mark-all-as-read, delete, and navigation to the notification's action URL.

`registerMagicStarterNotificationRoutes()` registers it on `Notify.view` under `'notifications.list'`, wrapped in this package's page container, and the route renders that key at `MagicStarterConfig.notificationsRoute()`:

```dart
MagicRoute.page(
  MagicStarterConfig.notificationsRoute(),
  () => Notify.view.make('notifications.list'),
).title('magic_starter.titles.notifications').stacked();
```

### Deleting a notification

The mount supplies the view's `onDelete`, which is what makes the per-row delete control render at all: `NotificationsListView` draws it only when that callback is non-null. It does not hand the callback straight to `Notify.deleteNotification`. A delete is destructive, irreversible and one tap away in a scrollable list, so the mount asks first, through this package's own `MSConfirmDialog`:

- The dialog is shown against `MagicRouter.instance.navigatorKey.currentContext`, because neither the view registry nor `onDelete` provides a `BuildContext`. A null context refuses rather than deleting: nobody could have been asked.
- `MSConfirmDialog` is used rather than `Magic.confirm` so the dialog follows `MagicStarter.manager.modalTheme` and the host's dark mode.
- Copy comes from `notifications.delete_confirm_title`, `notifications.delete_confirm_message`, `common.delete` and `common.cancel`. All four ship in `assets/stubs/install/en.stub`, so an app scaffolded by `starter:install` has them; an app with a hand-written catalogue needs them added, or the dialog renders the raw keys.

To take the confirmation out, or to change what it asks, register your own screen for `'notifications.list'` and pass whatever `onDelete` you want. That registration wins (see [Overriding a Screen](#overriding-a-screen)).

Each notification item resolves its icon through the notification type icon slot (see [Notification Type Icons](#notification-type-icons)). A tapped notification is marked as read and the user is sent to its `actionUrl`.

<a name="notification-preferences"></a>
## Notification Preferences

`NotificationPreferencesView` (from `magic_notifications`) shows a type-by-channel preference matrix fetched from the backend. Each notification type (for example "Monitor Down") lists its channels (email, in-app, push) as toggle switches.

`registerMagicStarterNotificationRoutes()` registers it under `'notifications.preferences'`, passing what the notifications package cannot know: where "back" goes in this app, and the host page geometry.

```dart
Notify.view.register(
  'notifications.preferences',
  () => NotificationPreferencesView(
    backRoute: MagicStarterConfig.settingsHubRoute(),
    contentClassName: geometry,
    headerBuilder: _pageHeader,
  ),
);
```

Both mounts pass `headerBuilder`, which draws each screen's header as an `MSPageHeader` inside the screen's own scroll view, so both pages follow [host-owned page chrome](../architecture/manager.md#host-page-chrome) like every other starter page: under `MagicStarter.useHostPageChrome` the inbox reports its title and keeps only its mark-all-as-read action, and the preferences report the settings hub as their back fallback. A screen you register yourself draws its own header unless you pass a `headerBuilder` too.

The matrix structure returned by the API:

```json
{
  "monitor_down": {
    "label": "Monitor Down",
    "channels": {
      "mail":     { "enabled": true,  "locked": false },
      "database": { "enabled": true,  "locked": true },
      "push":     { "enabled": false, "locked": false }
    }
  }
}
```

Locked channels display a lock icon and their toggle is disabled; the backend enforces that certain channels cannot be turned off.

> [!NOTE]
> Preference updates are optimistic. The toggle flips immediately and a `PUT /notification-preferences` request is sent; on failure the matrix reverts to its pre-update snapshot. That state lives in `magic_notifications`'s `NotificationPreferencesController`; this package carries no controller for it.

The screen also opens with a bulk card above the matrix, one switch per channel applying to every type at once, backed by the batch shape `PUT /notification-preferences` with `{preferences: [{type, channel, is_enabled}, ...]}`. `magic-starter-laravel` accepts that shape; a hand-rolled endpoint that only takes the single shape answers 422 and the card does nothing.

The notification screens read five `notifications.*` keys that no package supplies: `bulk_title` and `bulk_description` head the bulk card, `delete` names the list row's delete glyph for a screen reader, `delete_failed` is shown when the server refuses a delete, and `channel_sms` labels the SMS row. All five ship in `assets/stubs/install/en.stub`, so an app scaffolded by `starter:install` has them; an app with a hand-written catalogue adds them, or each renders as its own key.

<a name="notification-dropdown"></a>
## Notification Dropdown

`NotificationDropdown` (from `magic_notifications`) is a standalone widget, not a view: a bell icon with a live unread badge, built on a `StreamBuilder<List<DatabaseNotification>>`. `MagicStarterAppLayout` mounts it with these callbacks:

```dart
NotificationDropdown(
  notificationStream: Notify.notifications(),
  onMarkAsRead: (id) => Notify.markAsRead(id),
  onMarkAllAsRead: () => Notify.markAllAsRead(),
  onNotificationTap: (notification) =>
      MagicRoute.to(notification.actionUrl ?? '/'),
  onViewAll: () =>
      MagicRoute.to(MagicStarterConfig.notificationsRoute()),
)
```

The layout also passes the trigger, icon, panel and badge classNames from `MagicStarter.manager.layoutTheme`; a null one keeps the widget's own default. The dropdown is rendered in the layout's header and sidebar through the `_buildNotificationBell()` helper, and only when `MagicStarterConfig.hasNotificationFeatures()` is `true`.

| State | Display |
|:------|:--------|
| Loading | Bell icon with no badge, spinner in the dropdown body |
| Error | Bell icon with no badge, error icon in the dropdown body |
| Empty | Bell icon with no badge, "No notifications" empty state |
| Unread > 0 | Bell icon with red badge (`9+` overflow), notification list |

A tapped notification is marked as read and `onNotificationTap` fires; the dropdown closes after the tap.

> [!TIP]
> The dropdown uses `WPopover` for overlay positioning. It aligns to `PopoverAlignment.bottomRight` by default and constrains its height to 400 logical pixels.

<a name="notification-type-icons"></a>
## Notification Type Icons

What a notification type looks like is `magic_notifications`'s own slot, and it answers the same question for the list screen and the bell at once:

```dart
import 'package:magic_notifications/magic_notifications.dart';

Notify.view.slot(
  NotificationViewRegistry.typeIconSlotView,
  'monitor_down',
  (context) => WIcon(Icons.error_outline, className: 'text-lg text-red-500'),
);
```

Register the slot name `'default'` to answer for every type you did not name individually:

```dart
Notify.view.slot(
  NotificationViewRegistry.typeIconSlotView,
  'default',
  (context) => WIcon(Icons.info_outline, className: 'text-lg text-blue-500'),
);
```

Both the list view and the dropdown read `Notify.view.buildTypeIcon(type, context)`, which checks the type's own slot first and falls back to `'default'`, so one registration answers for both surfaces.

<a name="overriding-a-screen"></a>
## Overriding a Screen

To swap either screen, register on `Notify.view`, not `MagicStarter.view`:

```dart
Notify.view.register(
  'notifications.list',
  () => const MyCustomNotificationsListView(),
);
```

**The order does not matter.** `registerMagicStarterNotificationRoutes()` installs its own wrapped screens only when nobody has chosen one for that key (`Notify.view.hasOverride`), so a host registration wins whether it runs before or after the routes are mapped.

The check is `hasOverride`, not `has`: reading `Notify.view` seeds `magic_notifications`' own two defaults into the registry, so `has(key)` is already true before anybody has decided anything, and gating on it would make this package skip every time and never apply the page geometry. The two calls can land in different files (the installer injects the route registration into `route_service_provider.dart`, while your `Notify.view` work usually sits in `AppServiceProvider`), and which boots first depends on the host's provider list, which is why the order is made not to matter.

The registry has the same shape as `MagicStarter.view` (`register` / `has` / `make` / `slot` / `buildSlot` / `clear`).

<a name="feature-gate"></a>
## Feature Gate

All notification functionality is gated behind `MagicStarterConfig.hasNotificationFeatures()`. Enable it in your configuration:

```dart
Config.set('magic_starter.features.notifications', true);
```

When it is off:

- The notification routes are not registered (`registerMagicStarterNotificationRoutes()` returns at once).
- The bell does not render in the app layout.
- Polling never starts.
- No push identity is declared.

> [!TIP]
> The install command can enable it: `dart run magic:dowel starter:install --features=notifications`. That adds `magic_notifications` to your `pubspec.yaml` and prints the follow-up `dart run magic:dowel notifications:install --app-id=<your-onesignal-app-id>`; it does not run the OneSignal installer for you, because the app id is yours.

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Changing `magic_starter.notifications.external_id_prefix` on one side only | Change the backend's `onesignal.external_id_prefix` (`MAGIC_STARTER_EXTERNAL_ID_PREFIX`) with it. OneSignal accepts the mismatch and delivers to nobody; `starter:doctor` shows the prefix the app declares. |
| Using a custom prefix while reporting push state | `magic_notifications` reads its own `notifications.push_state.external_id_prefix` (default `user_`) and reports only when the intent is `<prefix><Auth.id()>`; set both keys to the same value. |
| Registering your own screen on `MagicStarter.view` | The notification routes resolve through `Notify.view`; register `'notifications.list'` or `'notifications.preferences'` there. |
| Gating an override on `Notify.view.has(key)` | Reading `Notify.view` seeds the package defaults, so `has` is always true. Use `hasOverride`. |
| A hand-written language catalogue missing the notification keys | The delete confirmation and the bulk card render raw keys. Add the `notifications.*` and `common.delete` entries from `assets/stubs/install/en.stub`. |
| Expecting authenticated work in a before-logout hook after a refresh failure | Hooks do not run for the sign-out `AuthInterceptor` performs; the starter still releases the push identity, but server-side rows need their own expiry. |

<a name="related-documentation"></a>
## Related Documentation

- [Authentication](./authentication.md#before-logout-hooks): sign-out and the before-logout hooks.
- [Components](./components.md): `MSConfirmDialog`, `MSPageHeader` and the page container the screens are wrapped in.
- [Views and Layouts](./views-and-layouts.md): the app layout that owns polling and the bell.
- [Configuration](../getting-started/configuration.md): the feature flag and the prefix key.
- [Channels](https://anilcancakir.com/magic/docs/notifications/basics/channels): the notification channels.
- [Preferences](https://anilcancakir.com/magic/docs/notifications/basics/preferences): the preference model behind the matrix.
