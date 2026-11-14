# Middleware

The two route guards the starter ships, `EnsureAuthenticated` and `RedirectIfAuthenticated`, and the `auth` and `guest` aliases its route groups expect.

- [Introduction](#introduction)
- [Registering the Aliases](#registering-the-aliases)
- [EnsureAuthenticated](#ensureauthenticated)
- [RedirectIfAuthenticated](#redirectifauthenticated)
- [Which Routes Expect Which Alias](#which-routes-expect-which-alias)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

`EnsureAuthenticated` blocks a signed-out visitor from a protected route, and `RedirectIfAuthenticated` blocks a signed-in visitor from a guest-only page such as the login form. Both extend `MagicMiddleware` and override `redirectTarget`, so the redirect resolves inside the router's `redirect` callback before any page builds; the destination view mounts exactly once instead of building the gated page and then remounting.

<a name="registering-the-aliases"></a>
## Registering the Aliases

Register them once in your app's `Kernel`, using the exact alias names `'auth'` and `'guest'` that the starter's own route groups reference:

```dart
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void registerMiddleware() {
  Kernel.registerAll({
    'auth': () => EnsureAuthenticated(),
    'guest': () => RedirectIfAuthenticated(),
  });
}
```

Call `registerMiddleware()` once from your bootstrap, before the router builds its routes. `starter:install` does this for you in `lib/app/kernel.dart`, with copies of the two classes it scaffolds into `lib/app/middleware/` (see [Gotchas](#gotchas)).

<a name="ensureauthenticated"></a>
## EnsureAuthenticated

Redirects an unauthenticated visitor to `MagicStarterConfig.loginRoute()`. It leaves the login route itself alone so the redirect can never loop: `go_router` raises past five successive redirects.

Before it redirects, it records the location it bounced as the router's intended url (`MagicRouter.setIntendedUrl`), so a successful sign-in lands there through `navigateHome()`. Nothing is recorded for the login route or for the guest-only auth pages (register, forgot and reset password, two-factor challenge, OTP). The location carries no query string, so a recorded intent loses a `?token=...` the original link had.

```dart
MagicRoute.group(
  middleware: ['auth'],
  routes: () {
    // protected routes
  },
);
```

<a name="redirectifauthenticated"></a>
## RedirectIfAuthenticated

Redirects an already authenticated visitor to `MagicStarterConfig.homeRoute()`. It leaves the home route itself alone for the same reason: a signed-in visitor landing back on home must not be redirected to home again.

A guest session (`is_guest: true`) is exempt and stays on the auth pages, because login and registration are where a guest becomes an account.

```dart
MagicRoute.group(
  middleware: ['guest'],
  routes: () {
    // auth pages: login, register, forgot/reset password
  },
);
```

<a name="which-routes-expect-which-alias"></a>
## Which Routes Expect Which Alias

The starter's own route groups assume these aliases are registered:

| Route group | Alias | File |
|:------------|:------|:-----|
| Auth (login, register, forgot/reset password, two-factor challenge, OTP) | `guest` | `lib/src/routes/auth_routes.dart` |
| Profile / settings | `auth` | `lib/src/routes/profile_routes.dart` |
| Teams | `auth` | `lib/src/routes/team_routes.dart` |
| Notifications | `auth` | `lib/src/routes/notification_routes.dart` |
| Support | `auth` | `lib/src/routes/support_routes.dart` |

The email verification and sign-in handoff routes sit outside both groups on purpose: a visitor may open those links signed in or signed out (see [Authentication](./authentication.md#verify-email)).

If a route names an alias that was never registered, the router throws a `StateError` naming the route and the alias when it builds, which surfaces from `Magic.init`.

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Forgetting to register `auth` or `guest` | The router refuses to build with a `StateError` that names each route and the missing alias. Register both before the router builds. |
| Assuming the installed Kernel uses the package classes | `starter:install` writes `lib/app/middleware/ensure_authenticated.dart` and `redirect_if_authenticated.dart` and registers those. They are plain `handle`-based copies: they redirect after the build, do not record an intended url and do not exempt a guest session. Delete them and register the package classes to get the behaviour on this page. |
| Using a different alias name | The starter's route groups look up `auth` and `guest` literally; any other name leaves them unregistered. |
| Expecting the intended url to keep a query string | `redirectTarget` receives the matched location without its query, so a `?token=...` is lost. |
| Putting the guest guard on the verify-email or handoff route | Those routes are deliberately outside `guest`: a signed-in reader would be sent home before the link was replayed. |

<a name="related-documentation"></a>
## Related Documentation

- [Authentication](./authentication.md): `Auth.check()`, login, logout and the routes these guards protect.
- [Session Scope](./session-scope.md): what resets when `Auth.stateNotifier` changes identity.
- [CLI Commands](./cli.md): what `starter:install` scaffolds and registers.
