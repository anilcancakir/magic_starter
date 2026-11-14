# Views and Layouts

How a page-level view binds to its controller, how the app and guest shells wrap it, and how a host replaces any screen or shell through the view registry.

- [Introduction](#introduction)
- [Quick Reference](#quick-reference)
- [MagicStatefulView](#magicstatefulview)
- [View Lifecycle](#view-lifecycle)
- [State Rendering](#state-rendering)
- [Form Handling](#form-handling)
- [AppLayout](#applayout)
    - [Where the sidebar starts, and where it grows labels](#where-the-sidebar-starts-and-where-it-grows-labels)
    - [Letting the viewer collapse the sidebar](#letting-the-viewer-collapse-the-sidebar)
    - [A focus ring for a keyboard or a remote](#a-focus-ring-for-a-keyboard-or-a-remote)
    - [A live count on a destination](#a-live-count-on-a-destination)
    - [The box the route child is handed](#the-box-the-route-child-is-handed)
    - [Hiding the bottom nav on a page](#hiding-the-bottom-nav-on-a-page)
    - [An immersive route](#an-immersive-route)
- [GuestLayout](#guestlayout)
- [Page Chrome](#page-chrome)
- [Wind UI System](#wind-ui-system)
- [Dark Mode](#dark-mode)
- [View Registry](#view-registry)
- [Layout Registry](#layout-registry)
- [Overriding the App Shell](#overriding-the-app-shell)
- [Feature-Gated Rendering](#feature-gated-rendering)
- [Zero Business Logic](#zero-business-logic)
- [Reusable Widgets](#reusable-widgets)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

The view layer separates rendering from state: views render, controllers hold state and business logic. Every page-level view extends `MagicStatefulView<ControllerType>`, which binds the view to its controller singleton and provides lifecycle hooks. Two layout shells wrap the views: `MagicStarterAppLayout` for authenticated pages and `MagicStarterGuestLayout` for auth pages. The views are built with Wind widgets (`WDiv`, `WText`, `WButton` and the rest); `Icons` is the only Material import.

All views and layouts are registered by string key in a registry, so every screen is overridable by the host app.

<a name="quick-reference"></a>
## Quick Reference

Replace a view or a layout by registering a builder under its key, in your own provider's `boot()`:

```dart
MagicStarter.view.register('auth.login', () => const MyLoginView());
MagicStarter.view.registerLayout('layout.app', (child) => MyAppShell(child: child));
```

| View keys | Registered when |
|:----------|:----------------|
| `auth.login`, `auth.register`, `auth.forgot_password`, `auth.reset_password` | Always |
| `auth.verify_email` | `email_verification` |
| `auth.two_factor_challenge` | `two_factor` |
| `auth.otp_verify` | `phone_otp` |
| `auth.handoff` | `handoff` |
| `settings.hub`, `profile.profile`, `settings.appearance`, `settings.security.password` | Always |
| `settings.language` | `extended_profile` |
| `settings.timezone` | `timezones` |
| `settings.newsletter` | `newsletter` |
| `settings.changelog` | `releases` |
| `settings.security.two_factor` | `two_factor` |
| `settings.security.sessions` | `sessions` |
| `settings.security.connected_accounts` | `social_login` |
| `teams.create`, `teams.settings`, `teams.invitation_accept` | `teams` |
| `teams.billing` | `billing` |
| `support.index`, `support.create`, `support.thread` | `support` |
| `support.feedback` | `support` and `support_feedback` |
| `support.chat`, `support.chat_panel` | `support` and `support_chat` |

| Layout keys | Layout |
|:------------|:-------|
| `layout.app` | The authenticated shell with sidebar and navigation |
| `layout.guest` | The centred shell for auth pages |

`profile.settings` is a long single-page profile view the package can publish (`starter:publish`) but no default registers. `notifications.list` and `notifications.preferences` are not on `MagicStarter.view` either: those screens belong to `magic_notifications` and live on its own `Notify.view`; see [Notifications](./notifications.md).

<a name="magicstatefulview"></a>
## MagicStatefulView

Page-level views extend `MagicStatefulView<ControllerType>` with a state class that extends `MagicStatefulViewState`:

```dart
class ProjectsView extends MagicStatefulView<ProjectController> {
  const ProjectsView({super.key});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState
    extends MagicStatefulViewState<ProjectController, ProjectsView> {
  @override
  void onInit() {
    controller.clearErrors();
    controller.setEmpty();
  }

  @override
  Widget build(BuildContext context) {
    return controller.renderState(
      (_) => _buildList(),
      onEmpty: _buildList(),
      onError: (message) => _buildList(errorMessage: message),
    );
  }
}
```

The base class gives you the controller singleton as `controller`, plus the `onInit()` and `onClose()` hooks. Only full-page views that need a controller binding use it; components such as `MSUserProfileDropdown` extend `StatelessWidget` or `StatefulWidget` directly.

<a name="view-lifecycle"></a>
## View Lifecycle

`onInit()` runs once when the state is initialised: clear errors, set the initial state or trigger a fetch. `onClose()` runs when the state is disposed: dispose form data and local notifiers.

```dart
@override
void onClose() => form.dispose();
```

A view with several forms disposes every `MagicFormData` in `onClose()`, and field names must not collide across forms in the same view. A view that runs while its route is being built should not notify: the profile and team controllers expose `resetQuietly()` for that.

<a name="state-rendering"></a>
## State Rendering

`controller.renderState()` picks a builder from the controller's `MagicStateMixin` state. The first positional argument builds the success state (it receives the state value):

| Parameter | When | Typical use |
|:----------|:-----|:------------|
| `onLoading` | A request is in flight | A skeleton |
| `onEmpty` | No data loaded yet | The empty form or a placeholder |
| `onError` | The controller called `setError()` | The form with an error banner |

Read `controller.isLoading` at the top of a build method to disable a submit button:

```dart
WButton(
  onTap: controller.isLoading ? null : _submit,
  className: 'w-full py-3 rounded-lg bg-primary text-white',
  child: WText(controller.isLoading ? trans('common.loading') : trans('auth.login')),
)
```

<a name="form-handling"></a>
## Form Handling

Forms are `MagicFormData` instances with empty-string defaults for text fields and typed defaults for the rest:

```dart
late final form = MagicFormData(
  {
    'email': '',
    'password': '',
    'remember_me': false,
  },
  controller: controller,
);
```

Read a text field with `form.get('email')` and a typed one with `form.value<bool>('remember_me')`. Render fields with `WFormInput`, bound to the form's field controller:

```dart
WFormInput(
  label: trans('attributes.email'),
  controller: form['email'],
  type: InputType.email,
  validator: rules([Required(), Email()], field: 'email'),
)
```

Validate, then hand the values to the controller:

```dart
Future<void> _submit() async {
  if (!form.validate()) return;

  await controller.doLogin(
    email: form.get('email'),
    password: form.get('password'),
    rememberMe: form.value<bool>('remember_me'),
  );
}
```

Read route values a controller call needs (a reset token, say) in the view's `didChangeDependencies` through `MagicRouter.instance.queryParameterOf(context, 'token')` or `pathParameterOf(context, ...)`, which answer for the page the view sits in.

<a name="applayout"></a>
## AppLayout

`MagicStarterAppLayout` is the authenticated shell: a sidebar with brand, team selector, navigation and user menu on a wide screen, and a header, drawer and bottom navigation on a narrow one. `MagicStarterServiceProvider` registers it under `layout.app`.

It starts notification polling when it mounts (with notifications on, through `Notify.startPolling()`), mounts the update and campaign banners when their features are on, and rebuilds on `Auth.stateNotifier` and on the static `MagicStarterAppLayout.refreshNotifier`. Nothing in the package bumps that notifier, since the layout already rebuilds on `Auth.stateNotifier`; only a host that needs an extra rebuild increments its `value`.

Customise it before the layout first paints, ideally in `AppServiceProvider.boot()`:

```dart
// Replace the mobile header.
MagicStarter.useHeader((context, isDesktop) {
  return MyCustomHeader(showMenuButton: !isDesktop);
});

// Navigation destinations.
MagicStarter.useNavigation(
  mainItems: [
    MagicStarterNavItem(
      icon: Icons.dashboard_outlined,
      labelKey: 'nav.dashboard',
      path: '/',
    ),
  ],
);

// A widget between the navigation items and the user menu.
MagicStarter.useSidebarFooter((context) => MyVersionBadge());

// Colours and brand.
MagicStarter.useNavigationTheme(
  MagicStarterNavigationTheme(
    activeItemClassName:
        'active:text-amber-500 active:bg-amber-500/10 dark:active:text-amber-400 dark:active:bg-amber-400/10',
    brandBuilder: (context) => Image.asset('assets/logo.png', height: 28),
    bottomNavActiveClassName: 'active:text-amber-500 dark:active:text-amber-400',
    avatarClassName: 'bg-amber-500/10 dark:bg-amber-400/10',
  ),
);
```

`useNavigation` also takes `systemItems`, `bottomItems` and `profileMenuItems`. See [Manager](../architecture/manager.md) for the themes.

### Theme setters and `useWindTheme`

`MagicStarter.useWindTheme(windTheme)` derives the colours of every sub-theme from your Wind palette, and it lands them only on the fields you have not set yourself. So it can run before or after `useLayoutTheme`, `useNavigationTheme` and the other `use*Theme()` setters: a field you set keeps your value either way.

The rule is per field. A field counts as yours when its current value differs both from its sub-theme's default constructor value and from what the previous `useWindTheme` call derived for it. Your fields are kept; every other field takes the derived value. Two things follow from that:

- A second `useWindTheme` with another palette re-skins what the first one derived, and still leaves your fields alone.
- A field you set to exactly its stock default reads as not set, so the palette derives over it. To keep a stock value on top of a palette, set it after `useWindTheme`.

`useTheme(MagicStarterTheme(...))` is not a merge: it replaces every sub-theme whole.

Each setter assigns its whole struct, so `MagicStarterLayoutTheme(navigationBreakpoint: 'sm')` puts every other layout field back on its default, including the sidebar, header and background colours `useWindTheme` derived. A one-field override is `current.copyWith(...)`, which every sub-theme has:

```dart
MagicStarter.useLayoutTheme(
  MagicStarter.layoutTheme.copyWith(navigationBreakpoint: 'sm'),
);

MagicStarter.useNavigationTheme(
  MagicStarter.navigationTheme.copyWith(
    focusItemClassName: 'focus:ring-2 focus:ring-primary',
  ),
);
```

`useWindTheme` also derives the drawer and content area backgrounds (`drawerBackground*` and `contentBackground*`) from the `bg-surface` role the sidebar and header use. Those fields are `wColor` keys rather than classNames, so each half of the role (`bg-ink-50`, `dark:bg-[#0E0F11]`) becomes a colour name, or a hex, and a shade. A half that does not resolve, an opacity step or a colour the Wind theme does not carry, keeps the stock key.

### Where the sidebar starts, and where it grows labels

Three fields on `MagicStarterLayoutTheme` decide the shell's shape. The first two are breakpoints, named as keys of the Wind theme's `screens` map (`sm`, `md`, `lg`, `xl`, `2xl` by default) rather than as pixel counts; the third is a width in logical pixels:

| Field | Default | What it decides |
|:------|:--------|:----------------|
| `navigationBreakpoint` | `'lg'` | The breakpoint from which the sidebar replaces the drawer and the bottom bar |
| `sidebarExpandedBreakpoint` | `'lg'` | The breakpoint from which the sidebar carries labels beside its icons |
| `sidebarCompactWidth` | `80` | The width of the sidebar while it is compact |

Between the two breakpoints the sidebar renders compact: icons only, with every text label dropped (the app name, the item labels, the system section's name, and the user's name and email, which falls back to the avatar trigger the mobile header mounts). What a host supplies itself, `brandBuilder` and `sidebarFooterBuilder`, is not reshaped, since only the host knows whether its own widget fits an icon column. A host whose wordmark does not fit sets `MagicStarterNavigationTheme.compactBrandBuilder` to a glyph, and the compact rail shows that instead.

A name the Wind theme does not carry throws a `StateError` naming the field and listing the valid keys, because `wScreenIs` answers false for an unknown key and a typo would otherwise pin the shell to its narrow form with nothing to read. The defaults leave the two breakpoints equal, so the compact form never fires until a host lowers one of them:

```dart
// An icon rail from 640 px, labels from 1024 px.
MagicStarter.useLayoutTheme(
  const MagicStarterLayoutTheme(
    navigationBreakpoint: 'sm',
    sidebarExpandedBreakpoint: 'lg',
  ),
);
```

Keep `sidebarCompactWidth` at 80 or more: the compact team selector (`mx-3 p-2` around a `w-8` avatar) plus the sidebar's `border-r` overflows a narrower rail.

### Letting the viewer collapse the sidebar

| Field | Default | What it decides |
|:------|:--------|:----------------|
| `sidebarCollapsible` | `false` | Whether a toggle above the user menu collapses the labelled sidebar to its compact form and back |
| `sidebarCollapsedByDefault` | `false` | Whether a collapsible sidebar starts compact before the viewer has chosen |

The toggle appears only at or above `sidebarExpandedBreakpoint`; below it the sidebar is compact because the window cannot spare `sidebarWidth`. `sidebarCollapsedByDefault` is ignored unless the sidebar is collapsible. The viewer's choice is remembered through Magic's `Cache` under `magic_starter.sidebar_collapsed`, written with a ten year TTL because the cache has no `forever` and its own default would hand the viewer the default back the next morning. A host that binds no cache keeps the choice in memory for the life of the shell, and a remembered choice wins over `sidebarCollapsedByDefault`.

The toggle reads `nav.collapse_sidebar` and `nav.expand_sidebar`, both in the install stub; a host with its own language files adds them.

```dart
// Icons only until the viewer asks for labels, with a glyph for the rail.
MagicStarter.useLayoutTheme(
  const MagicStarterLayoutTheme(
    sidebarCollapsible: true,
    sidebarCollapsedByDefault: true,
  ),
);

MagicStarter.useNavigationTheme(
  MagicStarterNavigationTheme(
    brandBuilder: (context) => const MyLogoLockup(),
    compactBrandBuilder: (context) => const MyLogoGlyph(),
  ),
);
```

### A focus ring for a keyboard or a remote

`MagicStarterNavigationTheme.focusItemClassName` is applied to every navigation item the shell draws (sidebar, drawer and bottom bar). Each token carries the `focus:` prefix; Wind lights them when the item's `WAnchor` holds primary focus. It defaults to `''`, which is no ring, and an app driven by arrow keys or a television remote wants it set:

```dart
MagicStarter.useNavigationTheme(
  const MagicStarterNavigationTheme(
    focusItemClassName: 'focus:ring-2 focus:ring-primary focus:ring-offset-2',
  ),
);
```

### Names for a screen reader

Every control the shell draws has a name in the semantics tree, which is what a screen reader announces and what a semantics-driven test tool finds a control by. A labelled sidebar row, a drawer row and a bottom bar item are named by their label. The compact rail drops the label it draws, so its items carry that label as their name all the same, with a badge's count sentence after it.

The phone header's three icon controls read their names from the catalogue: `nav.open_menu` for the menu button, `nav.notifications` for the bell (the bell in the sidebar takes the same name) and `nav.account_menu` for the avatar that opens the account menu, which also names the avatar on the compact rail. The install stub ships the three keys; an app installed before them gets the English names (`Open menu`, `Notifications`, `Account menu`) rather than the raw keys until it adds them to its own language files. A `triggerBuilder` handed to `MSUserProfileDropdown` names its own trigger.

### A live count on a destination

A `MagicStarterNavItem` takes a `badgeCount`, a `ValueListenable<int?>`. The shell listens to it, so the host moves the number by updating the notifier and never rebuilds the navigation config:

```dart
// Owned by whatever loads the number: a controller, a repository, a stream.
final ValueNotifier<int?> unticked = ValueNotifier<int?>(null);

MagicStarter.useNavigation(
  mainItems: [
    MagicStarterNavItem(
      icon: Icons.shopping_cart_outlined,
      labelKey: 'nav.shopping',
      path: '/shopping',
      badgeCount: unticked,
      badgeLabelKey: 'nav.shopping_open',
    ),
  ],
);

unticked.value = 4; // the badge reads 4
unticked.value = 0; // and is gone
```

The badge is hidden while the value is `null` or not above zero, and reads `99+` above 99. The sidebar and the drawer draw it at the trailing edge of the row, the compact rail and the bottom bar on the corner of the icon; the profile menu ignores it. On the compact rail the pill overhangs the icon by 16 px, so a `sidebarCompactWidth` under 52 would cut it.

A badge is not colour alone. A screen reader gets a sentence in place of the number, added to the item's own label: `badgeLabelKey` names a catalogue line with both plural forms and a `:count` placeholder, read with the real count even above 99. It defaults to `nav.badge_count`, which the install stub ships (`"One item|:count items"`); name your own key when the number counts something specific:

```json
{
  "nav": {
    "shopping_open": "One line to buy|:count lines to buy"
  }
}
```

An item holding a notifier is not `const`, so the list that carries it is `final`. Recolour the badge through the navigation theme, with a `dark:` peer on every colour (a semantic alias such as `bg-primary` already carries one):

```dart
MagicStarter.useNavigationTheme(
  const MagicStarterNavigationTheme(
    badgeClassName: 'bg-primary text-on-primary',
  ),
);
```

### The box the route child is handed

The shell wraps the route child in one `WDiv`, and two fields on `MagicStarterLayoutTheme` own it:

| Field | Default | What it decides |
|:------|:--------|:----------------|
| `contentClassName` | `'flex-1 min-h-0'` | The content area's own className |
| `contentScrollPrimary` | `false` | Whether that area attaches to the ambient `PrimaryScrollController` |

The default is a box of bounded height that does not scroll, so each routed page scrolls itself. Every view this package ships already does, through `MSPageScaffold` (which brings its own `SingleChildScrollView(primary: false)`) or, for the invitation card, its own scroll view. A page of your own that is taller than the window needs its own vertical scroll: put it through `MSPageScaffold`, or wrap it:

```dart
MagicRoute.page(
  '/reports',
  // `primary: false`, as MSPageScaffold does: the page owns its controller.
  () => const SingleChildScrollView(primary: false, child: ReportsView()),
);
```

> [!WARNING]
> Setting `contentClassName` to `'flex-1 overflow-y-auto'` with `contentScrollPrimary: true` makes the shell scroll, and it has a cost. In a go_router shell the route child is the nested Navigator, so a scrolling content box scrolls the Navigator and lays its Overlay out under an unbounded height. A page left under a `.stacked()` route is then never laid out again, and its second rebuild while hidden fails `_debugRelayoutBoundaryAlreadyMarkedNeedsLayout` in debug. The same setting also gives a fill-shaped screen (an `h-full` column that scrolls inside itself) an unbounded height, which it cannot lay out. See [flutter/flutter#193247](https://github.com/flutter/flutter/issues/193247).

Set the two fields together: Wind reads `scrollPrimary` only where it builds a scroll view, so beside a non-scrolling className it is inert. Two `primary: true` scrollables in one tree contend for the single controller.

### Hiding the bottom nav on a page

Wrap the page, not the route group, in `MagicStarterHideBottomNav`:

```dart
MagicRoute.page(
  '/chat/:id',
  () => MagicStarterHideBottomNav(child: ChatView()),
).stacked();
```

The phone's bottom bar collapses in step with that page's transition and returns as it leaves, an iOS back swipe included. The page stays in the same shell as the rest of the app, so nothing is rebuilt on the way in. A page registers once magic's route middleware has mounted it, so the bar starts collapsing a frame or two into the transition.

A host layout that draws its own bottom nav joins in with `MagicStarterBottomNavScope` at the layout's root and its nav inside `MagicStarterBottomNavSlot`:

```dart
class MyAppShell extends StatelessWidget {
  const MyAppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MagicStarterBottomNavScope(
      child: Column(
        children: [
          Expanded(child: child),
          MagicStarterBottomNavSlot(child: MyBottomNav()),
        ],
      ),
    );
  }
}
```

The slot's height is the nav's times how much of it is showing, so the content above grows into the room the bar gives up. Read that fraction with `MagicStarterBottomNavScope.visibilityOf(context)` (`0` to `1`). Place the scope inside the layout, never around it: magic tells shells apart by the layout widget's runtime type.

### An immersive route

`MagicStarterHideChrome` drops all of the chrome (sidebar, drawer, header and bottom bar, plus the safe-area inset), so a player, a viewfinder or a map paints the whole window:

```dart
MagicRoute.group(
  layout: (child) => MagicStarterHideChrome(
    child: MagicStarter.view.makeLayout('layout.app', child: child),
  ),
  layoutId: 'app.immersive',
  routes: () {
    MagicRoute.page('/player', () => const PlayerView());
  },
);
```

The group needs an id of its own, and a separate id is a separate shell: entering the route builds this layout and leaving it builds the app shell again, so the layout's state (the sidebar's collapsed choice, notification polling, the auth listeners) is rebuilt on each crossing. That suits an immersive route. A page that only wants the bottom bar gone belongs in the app shell under `MagicStarterHideBottomNav`.

<a name="guestlayout"></a>
## GuestLayout

`MagicStarterGuestLayout` is a minimal centred wrapper for authentication pages (login, register, forgot password, reset password). It constrains content to 480 px and provides scrolling. It is registered under `layout.guest`, uses `wColor()` for theme-aware backgrounds, and pads the content with `p-4 lg:p-8`.

Guest routes use `RouteTransition.none`, so there is no animation between auth screens.

<a name="page-chrome"></a>
## Page Chrome

The layout shell owns the sidebar, the header and the content box. What is left is page chrome: how wide the content column is, how far it sits from the edges, and where the title goes. `MSPageScaffold` and `MSPageContainer` own that, and every authenticated page goes through one of them.

`MSPageScaffold` is the full treatment. Give it a title and a list of sections, and it renders the page surface, its own vertical scroll, the shared content geometry, an `MSPageHeader` and a `gap-6` column for the sections:

```dart
MSPageScaffold(
  title: trans('teams.settings'),
  subtitle: trans('teams.settings_subtitle'),
  children: [
    MSCard(title: 'General', child: generalForm),
    MSCard(title: 'Members', child: memberList),
  ],
)
```

A sub-page adds a back affordance, and a top-level page can put an action next to the title:

```dart
MSPageScaffold(
  title: trans('profile.settings'),
  backLabel: trans('magic_starter.nav.settings'),
  backFallback: MagicStarterConfig.settingsHubRoute(),
  actions: [saveButton],
  children: [profileForm],
)
```

`MSPageContainer` is the geometry alone: width cap, edge margins, vertical rhythm and a horizontal safe-area guard. Reach for it when the page brings its own header or scrolls its own way, which is the usual shape in a host app:

```dart
MSPageContainer(
  children: [
    MSPageHeader(title: 'Monitors', actions: [newMonitorButton]),
    monitorTable,
  ],
)
```

Neither component decides the numbers. They read `MagicStarter.manager.pageContainerClassName`, which the host sets once (see [Page Geometry](../architecture/manager.md#page-geometry)), so a starter account page and a host domain page line up inside the same shell. See [Components](./components.md) for `MSCard`, `MSPageHeader` and the rest.

> [!WARNING]
> Do not open a page with its own `WDiv(className: 'p-4 lg:p-6 flex flex-col gap-6')`. It is how pages end up at different widths in the same app. A page that needs to tune one axis passes `className` to `MSPageContainer` instead.

<a name="wind-ui-system"></a>
## Wind UI System

The views use Wind widgets and Tailwind-style `className` strings: `WDiv` for containers, `WText` for text, `WButton`, `WAnchor`, `WIcon`, `WFormInput`, `WPopover` and so on. For long class lists, use a triple-quoted string:

```dart
WDiv(
  className: '''
    rounded-2xl bg-surface
    border border-color-border
    shadow-sm p-6
  ''',
  child: content,
)
```

Use Wind widgets in views, not `Container`, `Text` or `ElevatedButton`. `Icons.*` is the one Material reference, for icon data.

<a name="dark-mode"></a>
## Dark Mode

Wind supports the `dark:` prefix. A raw colour token needs its `dark:` peer in the same `className`; a semantic alias such as `bg-primary`, `bg-surface` or `text-fg-muted` already carries one:

```dart
WText('Hello', className: 'text-gray-900 dark:text-white')
WText('Hello', className: 'text-fg-muted')
```

The profile dropdown toggles the theme with `context.windTheme.toggleTheme()`, and `context.windIsDark` reads the current mode.

<a name="view-registry"></a>
## View Registry

All views are registered by string key in `MagicStarterViewRegistry`. The host overrides a screen by registering under the same key; the key table is in the [Quick Reference](#quick-reference):

```dart
// Override with a custom view.
MagicStarter.view.register(
  'auth.login',
  () => const MyCustomLoginView(),
);

// Build a view by key.
final widget = MagicStarter.view.make('auth.login');

// Inject content into a view that exposes a slot.
MagicStarter.view.slot('settings.hub', 'footer', (context) => const MyAboutSection());
```

`make(key)` throws a `StateError` when the key is not registered, so register views before routes reference them. The registry also answers `has(key)` and `clear()`, and `buildSlot()` is what a view calls to render a slot. Register slots before the view is built.

<a name="layout-registry"></a>
## Layout Registry

Layouts follow the same pattern with a `child` parameter for wrapping content:

```dart
// Override with a custom layout.
MagicStarter.view.registerLayout(
  'layout.app',
  (child) => MyCustomAppLayout(child: child),
);

// Build a layout around content.
final widget = MagicStarter.view.makeLayout(
  'layout.guest',
  child: loginView,
);
```

`makeLayout` hands the builder a `child` already wrapped in a route-keyed `KeyedSubtree`, so a replaced layout keeps the remount behaviour the default layouts carry. To test a view in isolation, register a minimal layout: `MagicStarter.view.registerLayout('layout.guest', (child) => child);`.

<a name="overriding-the-app-shell"></a>
## Overriding the App Shell

Every account, profile, team and settings route renders through the `layout.app` key. `MagicStarterServiceProvider` registers `MagicStarterAppLayout` under it, so a fresh install already renders in a working shell.

An app that already has its own navigation chrome does not want starter routes rendering inside a second, different shell on top of its own. Re-register `layout.app` with your own shell and every starter route renders inside it:

```dart
MagicStarter.view.registerLayout(
  'layout.app',
  (child) => MyAppShell(child: child),
);
```

Call this from your own `AppServiceProvider`'s `boot()`, alongside `MagicStarter.useNavigation()` or `MagicStarter.useHeader()`. `registerLayout()` always overwrites what is registered under the key, and the default is registered synchronously the first time the `magic_starter` singleton resolves, before your code runs, so your override wins whether you call it first or last in boot.

Your own authenticated routes join the same shell. Magic merges route groups into one go_router `ShellRoute` only when they carry the same `layoutId`, so give your group `MagicStarterLayoutIds.app`:

```dart
MagicRoute.group(
  layout: (child) => MagicStarter.view.makeLayout('layout.app', child: child),
  middleware: ['auth'],
  layoutId: MagicStarterLayoutIds.app,
  routes: () {
    MagicRoute.page('/', () => const DashboardView());
  },
);
```

A group with another id, or none, becomes a second shell, and every crossing between it and the starter's profile, team, notification or support pages rebuilds and re-animates the whole layout. `layout.app` is the only authenticated-shell key the starter resolves: override it in place, do not add a second key.

<a name="feature-gated-rendering"></a>
## Feature-Gated Rendering

Use conditional spreads to show or hide UI based on feature flags at build time:

```dart
WDiv(
  className: 'flex flex-col gap-4',
  children: [
    _buildEmailField(),
    _buildPasswordField(),
    if (MagicStarterConfig.hasRegistrationFeatures())
      WAnchor(
        onTap: () => MagicRoute.to('${MagicStarterConfig.authPrefix()}/register'),
        child: WText(trans('auth.register_link'), className: 'text-sm text-primary'),
      ),
    if (MagicStarterConfig.hasSocialLoginFeatures() &&
        MagicStarter.socialAuth != null) ...[
      const MSSocialDivider(),
      MagicStarterSocialButtons(
        socialAuth: MagicStarter.socialAuth!,
        onSelected: controller.doSocialSignIn,
        isLoading: controller.isLoading,
        busyProvider: controller.pendingSocialProvider,
      ),
    ],
  ],
)
```

Feature checks in views are read-only queries against the config. A view never toggles a feature; that is `starter:configure` or a config edit.

<a name="zero-business-logic"></a>
## Zero Business Logic

A view contains no business logic:

- No async work: `_submit()` calls a controller method and returns.
- No state decisions: the controller decides what happens after a submit (navigation, error handling).
- No HTTP calls: all API communication lives in controllers through `Http.post()`, `Http.get()` and the rest.
- No direct navigation: controllers use the `NavigatesRoutes` mixin, and views never call `context.go()`.
- Local UI state only: a password visibility toggle, a phone/email switch, a section spinner in a local `ValueNotifier<bool>`.

```dart
// Correct: the view delegates to the controller.
Future<void> _submit() async {
  if (!form.validate()) return;

  await controller.doLogin(
    email: form.get('email'),
    password: form.get('password'),
  );
}

// Wrong: the view makes the API call.
Future<void> _submit() async {
  final response = await Http.post('/auth/login', data: payload);
}
```

<a name="reusable-widgets"></a>
## Reusable Widgets

These widgets take plain callbacks and no internal controller, so a host app uses them directly. All are exported from `package:magic_starter/magic_starter.dart`. The `MS` components (`MSCard`, `MSPageHeader`, `MSAvatar` and the rest) are covered in [Components](./components.md).

`MagicStarterConfirmDialog` is a confirmation dialog with variant-driven styling, an alias of `MSConfirmDialog`. It returns `true` when confirmed and `false` when cancelled or dismissed, and shows a loading state while `onConfirm` runs:

```dart
final confirmed = await MagicStarterConfirmDialog.show(
  context,
  title: trans('teams.remove_member_label'),
  description: trans('teams.confirm_remove_member'),
  confirmLabel: trans('teams.remove'),
  variant: ConfirmDialogVariant.danger,
  onConfirm: () async {
    await TeamService.removeMember(memberId);
  },
);

if (confirmed) _refreshMembers();
```

`ConfirmDialogVariant` is `primary`, `danger` or `warning`; the button classNames come from `MagicStarter.manager.modalTheme`.

`MagicStarterPasswordConfirmDialog` is a password gate. Its `onConfirm` returns `null` on success or an error string to show inline; the dialog stays open on an error and closes with `true` on success. Without an `onConfirm` it closes with `true` as soon as the user confirms. For a gate that picks the right proof for the account, use `confirmIdentity` (see [Confirming Identity](./identity-confirmation.md)).

```dart
final confirmed = await MagicStarterPasswordConfirmDialog.show(
  context,
  title: trans('projects.delete_title'),
  onConfirm: (password) async {
    // Return null to confirm, or an error string on failure.
    return await ProjectService.delete(id, password: password);
  },
);
```

`MagicStarterTwoFactorModal` is the two-factor setup wizard: the QR code and a code input, then the recovery codes. It resolves `true` once `onConfirm` accepts a code:

```dart
final enabled = await MagicStarterTwoFactorModal.show(
  context,
  setupData: {
    'secret': 'JBSWY3DPEHPK3PXP',     // shown for manual entry
    'qr_svg': qrSvg,                  // raw SVG string
    'recovery_codes': recoveryCodes,  // list of strings
  },
  onConfirm: (code) async {
    return await TwoFactorService.confirmSetup(code);
  },
);
```

The other widgets a host can place:

| Widget | What it is |
|:-------|:-----------|
| `MagicStarterAuthFormCard` | A centred card (480 px) for auth-adjacent screens such as an invitation or onboarding, with a title, a subtitle, an optional error banner and a theme toggle |
| `MagicStarterTimezoneSelect` | A searchable timezone dropdown over `GET /timezones`; see [Profile](./profile.md#timezone-and-language) |
| `MSTeamSelector` | The current-team switcher; needs a registered team resolver (see [Teams](./teams.md#msteamselector)) |
| `MSUserProfileDropdown` | The avatar menu with user info, profile links, the theme toggle and logout; accepts a custom `triggerBuilder` |
| `MSSocialDivider` | The "Or continue with" divider for auth forms |
| `MagicStarterHideBottomNav`, `MagicStarterBottomNavScope`, `MagicStarterBottomNavSlot` | Collapse the phone's bottom navigation per page; see [Hiding the bottom nav on a page](#hiding-the-bottom-nav-on-a-page) |
| `MagicStarterHideChrome` | Hides the whole shell chrome for an immersive route; see [An immersive route](#an-immersive-route) |
| `MagicStarterLayoutIds` | The `layoutId` values of the starter's route groups; `MagicStarterLayoutIds.app` is the one a host's own group must share |

The notification bell is not here: it moved to `magic_notifications` as `NotificationDropdown`; see [Notifications](./notifications.md).

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Registering a layout under a new key for your shell | `layout.app` is the only authenticated-shell key the starter resolves. Re-register it. |
| Giving your own authenticated group another `layoutId` | Use `MagicStarterLayoutIds.app`, or crossing into a starter page rebuilds the whole layout. |
| A page taller than the window that does not scroll | The content box does not scroll by default. Use `MSPageScaffold` or wrap the page in a `SingleChildScrollView(primary: false)`. |
| Calling `MagicStarter.view.make(key)` for a key nothing registered | It throws a `StateError`. `profile.settings` is not registered by default, and a key behind a feature flag exists only with the flag on. |
| A breakpoint name the Wind theme does not carry in `MagicStarterLayoutTheme` | It throws a `StateError` listing the valid keys. Use `sm`, `md`, `lg`, `xl`, `2xl` or your own `screens` keys. |
| Calling `useNavigationTheme()` or `useModalTheme()` after the first paint | Call them in `AppServiceProvider.boot()`, before the layout or a dialog first renders. |

<a name="related-documentation"></a>
## Related Documentation

- [Components](./components.md): the `MS` design-system components.
- [Notifications](./notifications.md): the notification screens on `Notify.view`.
- [Profile](./profile.md): the settings hub and its sub-pages.
- [Teams](./teams.md): the team selector and team views.
- [Manager](../architecture/manager.md): the themes, locale options and page geometry.
- [View Registry](../architecture/view-registry.md): how the registry is built.
- [Configuration](../getting-started/configuration.md): the feature flags that decide which views register.
