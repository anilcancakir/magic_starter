# Views, layouts and the shell

Every key below is registered by `MagicStarterManager.registerDefaultViews()`, which the manager's constructor calls. A default registers only while its key is free, so a host registration made in any provider wins. A key whose toggle is off is never registered, and `make(key)` throws `StateError` for it.

## View keys

| Key | Registered when | Default widget |
|:----|:----------------|:---------------|
| `auth.login` | always | `MagicStarterLoginView` |
| `auth.register` | always (the route needs `registration`) | `MagicStarterRegisterView` |
| `auth.forgot_password` | always | `MagicStarterForgotPasswordView` |
| `auth.reset_password` | always | `MagicStarterResetPasswordView` |
| `auth.verify_email` | `email_verification` | `MagicStarterVerifyEmailView` |
| `auth.two_factor_challenge` | `two_factor` | `MagicStarterTwoFactorChallengeView` |
| `auth.otp_verify` | `phone_otp` | `MagicStarterOtpVerifyView` |
| `auth.handoff` | `handoff` | `MagicStarterHandoffView` |
| `settings.hub` | always | `MagicStarterSettingsHubView` |
| `profile.profile` | always | `MagicStarterProfileSubPageView` |
| `settings.appearance` | always | `MagicStarterAppearanceView` |
| `settings.security.password` | always | `MagicStarterPasswordView` (a password-less account sees Set password) |
| `settings.language` | `extended_profile` | `MagicStarterLanguageView` |
| `settings.timezone` | `timezones` | `MagicStarterTimezoneView` |
| `settings.newsletter` | `newsletter` | `MagicStarterNewsletterView` |
| `settings.changelog` | `releases` | `MagicStarterChangelogView` |
| `settings.security.two_factor` | `two_factor` | `MagicStarterTwoFactorView` |
| `settings.security.sessions` | `sessions` | `MagicStarterSessionsView` |
| `settings.security.connected_accounts` | `social_login` | `MagicStarterConnectedAccountsView` |
| `teams.create`, `teams.settings`, `teams.invitation_accept` | `teams` | `MagicStarterTeamCreateView`, `MagicStarterTeamSettingsView`, `MagicStarterTeamInvitationAcceptView` |
| `teams.billing` | `billing` | `MagicStarterBillingView` (no route; the host mounts it) |
| `support.index`, `support.create`, `support.thread` | `support` | `MagicStarterSupportIndexView`, `MagicStarterSupportCreateView`, `MagicStarterSupportThreadView` |
| `support.feedback` | `support` and `support_feedback` | `MagicStarterFeedbackView` |
| `support.chat`, `support.chat_panel` | `support` and `support_chat` | `MagicStarterSupportChatLauncher` (the host mounts it once), `MagicStarterSupportChatPanel` |

`profile.settings` is not registered. `MagicStarterProfileSettingsView` is exported and publishable, but nothing mounts it, and `MagicStarterProfileController.profile()` still asks the registry for that key, so it throws until a host registers it.

`notifications.list` and `notifications.preferences` live on `magic_notifications`' `Notify.view`. `registerMagicStarterNotificationRoutes()` re-registers them there wrapped in this package's page geometry unless the host already chose one (`Notify.view.hasOverride`), so a host override lands whether it runs before or after the routes.

## Layout and modal keys

| Key | Default |
|:----|:--------|
| `layout.app` | `MagicStarterAppLayout`: sidebar with brand, navigation and user menu from `navigationBreakpoint` up (icon rail between it and `sidebarExpandedBreakpoint`), drawer and bottom bar below it; the notification bell and polling when `notifications` is on |
| `layout.guest` | `MagicStarterGuestLayout`: a centred, scrolling column for the auth pages |
| `modal.confirm` | `MagicStarterConfirmDialog` (`ConfirmDialogVariant.primary`, `danger`, `warning`) |
| `modal.password_confirm` | `MagicStarterPasswordConfirmDialog` |
| `modal.two_factor` | `MagicStarterTwoFactorModal` |

`makeLayout(key, child:)` hands your builder the child already wrapped in a subtree keyed on the route path, so a replacement layout keeps the remount between routes. Render that child inside the routed subtree.

## Slots

| View key | Slots read |
|:---------|:-----------|
| `auth.login`, `auth.register` | `header`, `formFooter`, `footer` |
| `auth.forgot_password`, `auth.reset_password`, `auth.two_factor_challenge`, `auth.otp_verify` | `header`, `footer` |
| `settings.hub`, `profile.profile`, `teams.create`, `teams.invitation_accept` | `header`, `footer` |
| `teams.settings` | `header`, `footer`, `afterSection:members` |
| `teams.billing` | `plan_card_highlight` |

Slots are stored under `'<viewKey>.<slotName>'`; `buildSlot` answers `null` when none is registered and `clear()` removes them.

## Shell hooks

| Facade call | Effect |
|:------------|:-------|
| `useNavigation(mainItems:, systemItems:, bottomItems:, profileMenuItems:)` | The sidebar, drawer, bottom bar and profile menu items, each a `MagicStarterNavItem(icon:, labelKey:, path:, activeIcon:, badgeCount:, badgeLabelKey:)`. `badgeCount` is a `ValueListenable<int?>`: hidden at `null` or zero, `99+` above 99. |
| `useHeader((context, isDesktop) => ...)` | Replaces the shell header. |
| `useSidebarFooter((context) => ...)` | A widget at the foot of the sidebar and drawer. |
| `useHostPageChrome((context) => bool)` | Where it answers true, every `MSPageHeader` and `MSPageScaffold` draws only its actions and reports a `MagicStarterPageChromeEntry` (`title`, `subtitle`, `backLabel`, `backFallback`) to `MagicStarter.pageChrome.current`, for a host bar to draw. |
| `MagicStarter.manager.pageContainerClassName` | The width cap and padding of every page container. |

`MagicStarterHideBottomNav(child: page)` collapses the phone's bottom bar with that page's transition; a replacement layout opts in with `MagicStarterBottomNavScope` at its root and its bar inside `MagicStarterBottomNavSlot`. `MagicStarterHideChrome` marks an immersive route group, which needs its own `layoutId`. Every other authenticated group uses `MagicStarterLayoutIds.app`, since two groups with different ids are two shells and the layout rebuilds between them.

The settings hub's sections are exported as `MagicStarterSettingsAccountGroup`, `MagicStarterSettingsSecurityGroup` and `MagicStarterSettingsPreferencesGroup`, with their feature and ability checks, for a host that composes its own settings page.

## Publishing

`dart run magic:dowel starter:publish --tag=<group>[:scope]`, groups `config`, `views`, `layouts`, `middleware`, `lang`, `all` (default): `views:auth`, `views:auth.login`, `layouts:app`. Views go to `lib/resources/views/starter/`, layouts to `lib/resources/layouts/starter/`, and each is registered in `AppServiceProvider`. `--force` overwrites. A published copy is a snapshot; `starter:doctor` lists published views and warns for one `AppServiceProvider` does not register.
