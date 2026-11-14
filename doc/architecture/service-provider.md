# MagicStarterServiceProvider

`MagicStarterServiceProvider` binds the manager, listens to the auth events, defines the profile Gate abilities and wires the sign-in and sign-out side effects the starter owns.

- [Two-Phase Bootstrap](#two-phase-bootstrap)
- [Register Phase](#register-phase)
- [Boot Phase](#boot-phase)
    - [Teams Feature Warning](#teams-feature-warning)
    - [Gate Abilities](#gate-abilities)
    - [Primary Colour Fallback](#primary-color-fallback)
    - [Auth State Listeners](#auth-state-listeners)
    - [Before-Logout Hooks](#before-logout-hooks)
- [IoC Bindings](#ioc-bindings)
- [Related Documentation](#related-documentation)

The provider lives at `lib/src/providers/magic_starter_service_provider.dart` and extends `ServiceProvider` from `package:magic/magic.dart`. `starter:install` adds it to the `providers` list in `lib/config/app.dart`.

<a name="two-phase-bootstrap"></a>
## Two-Phase Bootstrap

Magic calls every provider's `register()` first, then every provider's `boot()` in list order:

| Phase | Method | Constraint |
|:------|:-------|:-----------|
| 1 | `register()` | Sync. Only bind into the container; no other service may be resolved yet. |
| 2 | `boot()` | Async. Every provider has registered, so bindings are resolvable. Providers boot one after another in the order of the `providers` list. |

<a name="register-phase"></a>
## Register Phase

```dart
@override
void register() {
  app.singleton('magic_starter', () => MagicStarterManager());

  EventDispatcher.instance.register(AuthRestored, [
    () => _ReloadOnAuthRestored(),
  ]);

  EventDispatcher.instance.register(AuthLogin, [() => _CallOnLoginHook()]);

  // ... guest listeners, session identity and store billable, below
}
```

1. **Manager singleton**: binds `MagicStarterManager` under `'magic_starter'`. The container builds it the first time it is resolved, and its constructor calls `registerDefaultViews()`, so the default views, layouts and modals are available from then on.
2. **Auth restored listener**: `_ReloadOnAuthRestored` calls `Magic.reload()` when `AuthRestored` fires with `changed` true, so screens refresh after a write that calls `Auth.restore()` (team rename, invitation accept, profile update). A sync that only confirms the cached user (`changed` false, the usual cold boot) reloads nothing. It also stays out of the way while `MagicStarterHandoffController` holds a sign-in handoff. A team switch does not come through here; it resets team-scoped screens through `SessionScope`.
3. **Auth login listener**: `_CallOnLoginHook` calls the host's `MagicStarter.useLogin()` callback (unawaited, logged on failure) whenever `AuthLogin` fires: every fresh sign-in, never a cold-boot restore. See [Login Callback](manager.md#login-callback).
4. **Guest listeners**, only when `features.guest_auth` is on: on `AuthLogin` a guest sign-in is recorded and any other sign-in claims the recorded guest's data in the background; on `AuthRestored` a pending claim runs; on `AuthLogout` the record is forgotten. See [Guest Claim Callback](manager.md#guest-claim-callback).
5. **Session identity**: sets `SessionScope.identity` to `<userId>:<teamId>` while signed in and `null` otherwise, so a team switch by the same user counts as a change. See [Session Scope](../basics/session-scope.md).
6. **Store billable**: points `StoreIdentitySync.billableId` at the manager, so the store rail is identified as the user or the team according to `magic_starter.billing.billable`.

> [!NOTE]
> The manager is built the first time it is resolved. If you want to override views, register them in your `AppServiceProvider.boot()`: `registerDefaultViews()` registers a key only when it is absent, and `register()` on the registry replaces whatever is there.

<a name="boot-phase"></a>
## Boot Phase

`boot()` is `async`. In order, it:

1. warns about a missing team resolver,
2. defines the Gate abilities,
3. schedules the primary colour fallback,
4. installs the modal presentation resolver on magic's router (`MagicRoute.useOverlayPresentation`), so an overlay route follows the modal theme's `presentation`,
5. on the web, primes the app build when `app_update` or `releases` is on,
6. attaches the auth state listeners and the before-logout hooks described below.

<a name="teams-feature-warning"></a>
### Teams Feature Warning

If `magic_starter.features.teams` is on and no team resolver has been registered, the provider logs a warning:

```dart
final teamsEnabled =
    Config.get<bool>('magic_starter.features.teams', false) ?? false;
if (teamsEnabled && MagicStarter.manager.teamResolver == null) {
  Log.warning(
    '[MagicStarter] Teams feature is enabled but no team resolver '
    'is configured. Call MagicStarter.useTeamResolver() in your AppServiceProvider.',
  );
}
```

`MagicStarter.bootstrap()` throws on the same condition instead of logging, so prefer it; see [Installation](../getting-started/installation.md#bootstrapping-the-starter). The resolver has to be registered before this provider boots, so list the provider that registers it before `MagicStarterServiceProvider`.

<a name="gate-abilities"></a>
### Gate Abilities

The provider defines the abilities that control profile section visibility. Every ability is granted when the user is not a guest (`is_guest != true`).

```dart
bool isNotGuest(Model user, [dynamic _]) {
  return user.get<bool>('is_guest') != true;
}

Gate.define('starter.update-profile-photo', isNotGuest);
Gate.define('starter.update-email', isNotGuest);
// ...
```

| Ability | Controls |
|:--------|:---------|
| `starter.update-profile-photo` | Profile photo upload and remove section |
| `starter.update-email` | Email field in profile information |
| `starter.update-phone` | Phone and country code in the extended profile |
| `starter.update-password` | Password change section |
| `starter.verify-email` | Email verification banner |
| `starter.manage-two-factor` | Two-factor authentication section |
| `starter.manage-newsletter` | Newsletter preferences section |
| `starter.logout-sessions` | Revoke buttons in browser sessions |
| `starter.delete-account` | Account deletion section |

`Gate.define()` replaces an ability of the same name, so the last definition wins. To override one, define it after this provider boots, which means listing your own provider after `MagicStarterServiceProvider`:

```dart
// In a provider listed after MagicStarterServiceProvider
Gate.define('starter.delete-account', (user, [_]) => false); // disable for all
```

> [!WARNING]
> A `Gate.define()` for a `starter.*` ability in a provider listed before `MagicStarterServiceProvider` boots first and is then overwritten by the starter's own definition.

<a name="primary-color-fallback"></a>
### Primary Colour Fallback

If the host has not defined a `primary` colour in its Wind theme, the provider registers `indigo` as the fallback. `boot()` runs during `Magic.init()`, before `runApp()` builds the widget tree, so the check is deferred to a post-frame callback:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final context = MagicRouter.instance.navigatorKey.currentContext;
  if (context == null) return;

  final windTheme = WindTheme.of(context);
  if (!windTheme.data.isValidColor('primary')) {
    windTheme.updateTheme(
      colors: {'primary': windTheme.data.colors['indigo']!},
    );
  }
});
```

The fallback applies only when no `primary` colour exists; if your `WindThemeData.colors` defines one, the callback does nothing.

<a name="auth-state-listeners"></a>
### Auth State Listeners

Three listeners attach to `Auth.stateNotifier`, each once per notifier, so a hot restart does not stack them:

| Listener | Does |
|:---------|:-----|
| Intended URL | On sign-out, clears the intended URL magic's router remembered, so the next sign-in does not land on the previous person's page. |
| Push identity | With `features.notifications` on: signed in as a non-guest, declares `<prefix><userId>` to the push driver (`Notify.initializePush`); signed out, or a guest, releases it. See [The push external id](../getting-started/configuration.md#push-external-id). |
| Saved locale | With `localization.apply_user_locale` on, applies the signed-in user's `locale` attribute through `MagicStarterManager.applyLocale()`. See [Locale Application](manager.md#locale-application). |

<a name="before-logout-hooks"></a>
### Before-Logout Hooks

The provider registers two hooks that run before every sign-out the user asks for, while the token still works (see [Logout Callback](manager.md#logout-callback)):

1. **Push device release**, when `magic_notifications` is bound and its push state is configured: `Notify.pushState.release`, which frees the backend's push-state row.
2. **Token revoke**, when an `auth` guard is bound and a token exists: `POST /auth/logout`. A non-success answer is logged as a warning and the token may stay valid until it expires.

A hook that throws or runs past five seconds is logged and skipped. A sign-out the app performs on its own, such as magic's `AuthInterceptor` after a failed token refresh, does not run them: the token is already dead.

<a name="ioc-bindings"></a>
## IoC Bindings

The manager is reachable two ways:

```dart
// Via the facade (preferred)
final manager = MagicStarter.manager;

// Via the container
final manager = Magic.make<MagicStarterManager>('magic_starter');
```

Register the provider in the `providers` list of `lib/config/app.dart`, and the config factory in `Magic.init()`:

```dart
import 'package:magic_starter/magic_starter.dart';

Map<String, dynamic> get appConfig => {
  'app': {
    'providers': [
      // ... other providers
      (app) => MagicStarterServiceProvider(app),
    ],
  },
};
```

The `magic_starter` keys live in their own config file, see [Configuration](../getting-started/configuration.md).

<a name="related-documentation"></a>
## Related Documentation

- [Manager](manager.md): the singleton holding every customisation registration.
- [View Registry](view-registry.md): the string-keyed view factory behind overridable screens.
- [Controllers](controllers.md): the lazy singleton pattern and the starter's own controllers.
- [Session Scope](../basics/session-scope.md): what resets when the identity key changes.
- [Magic service providers](https://anilcancakir.com/magic/docs/getting-started/service-providers): the two-phase lifecycle.
- [Magic authorization](https://anilcancakir.com/magic/docs/security/authorization): the Gate.
