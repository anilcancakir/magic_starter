import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';
import 'package:magic_payments/magic_payments.dart';

import 'configuration/magic_starter_config.dart';
import 'configuration/magic_starter_theme.dart';
import 'contracts/magic_starter_social_auth.dart';
import 'facades/magic_starter.dart';
import 'http/controllers/magic_starter_auth_controller.dart';
import 'http/controllers/magic_starter_team_controller.dart';
import 'http/magic_starter_guest_claim.dart';
import 'models/magic_starter_auth_user.dart';
import 'models/magic_starter_nav_item.dart';
import 'models/magic_starter_team.dart';
import 'support/support_page_ref.dart';
import 'ui/layouts/magic_starter_app_layout.dart';
import 'ui/layouts/magic_starter_guest_layout.dart';
import 'ui/widgets/magic_starter_confirm_dialog.dart';
import 'ui/widgets/magic_starter_password_confirm_dialog.dart';
import 'ui/widgets/magic_starter_two_factor_modal.dart';
import 'ui/magic_starter_page_chrome.dart';
import 'ui/magic_starter_view_registry.dart';
import 'ui/views/auth/magic_starter_forgot_password_view.dart';
import 'ui/views/auth/magic_starter_handoff_view.dart';
import 'ui/views/auth/magic_starter_login_view.dart';
import 'ui/views/auth/magic_starter_register_view.dart';
import 'ui/views/auth/magic_starter_reset_password_view.dart';
import 'ui/views/auth/magic_starter_verify_email_view.dart';
import 'ui/views/auth/magic_starter_two_factor_challenge_view.dart';
import 'ui/views/auth/magic_starter_otp_verify_view.dart';
import 'ui/views/profile/magic_starter_profile_sub_page_view.dart';
import 'ui/views/settings/magic_starter_changelog_view.dart';
import 'ui/views/settings/magic_starter_settings_hub_view.dart';
import 'ui/views/settings/preferences/magic_starter_appearance_view.dart';
import 'ui/views/settings/preferences/magic_starter_language_view.dart';
import 'ui/views/settings/preferences/magic_starter_newsletter_view.dart';
import 'ui/views/settings/preferences/magic_starter_timezone_view.dart';
import 'ui/views/settings/security/magic_starter_connected_accounts_view.dart';
import 'ui/views/settings/security/magic_starter_password_view.dart';
import 'ui/views/settings/security/magic_starter_sessions_view.dart';
import 'ui/views/settings/security/magic_starter_two_factor_view.dart';
import 'ui/views/support/chat/magic_starter_support_chat_launcher.dart';
import 'ui/views/support/chat/magic_starter_support_chat_panel.dart';
import 'ui/views/support/magic_starter_feedback_view.dart';
import 'ui/views/support/magic_starter_support_create_view.dart';
import 'ui/views/support/magic_starter_support_index_view.dart';
import 'ui/views/support/magic_starter_support_thread_view.dart';
import 'ui/views/teams/magic_starter_billing_view.dart';
import 'ui/views/teams/magic_starter_team_create_view.dart';
import 'ui/views/teams/magic_starter_team_invitation_accept_view.dart';
import 'ui/views/teams/magic_starter_team_settings_view.dart';

typedef UserModelFactory = Authenticatable Function(Map<String, dynamic> data);

/// Holds team-related callbacks so plugin UI can render team data
/// without depending on app-specific models.
class MagicStarterTeamResolverConfig {
  final MagicStarterTeam? Function() currentTeam;
  final List<MagicStarterTeam> Function() allTeams;
  final Future<void> Function(dynamic teamId) onSwitch;

  const MagicStarterTeamResolverConfig({
    required this.currentTeam,
    required this.allTeams,
    required this.onSwitch,
  });
}

/// Configuration for app navigation sections.
///
/// Apps register these via [MagicStarter.useNavigation] to populate
/// the sidebar, drawer, and bottom navigation bar.
class MagicStarterNavigationConfig {
  /// Primary navigation items (Dashboard, Monitors, etc.).
  final List<MagicStarterNavItem> mainItems;

  /// Secondary/system navigation items (Team Members, Settings).
  final List<MagicStarterNavItem> systemItems;

  /// Bottom navigation items for mobile (subset of main).
  final List<MagicStarterNavItem> bottomItems;

  /// Profile dropdown menu items.
  ///
  /// Host apps can register additional links (e.g. Notifications, Billing)
  /// that appear in the user profile dropdown between the default
  /// "Profile Settings" link and the logout action.
  final List<MagicStarterNavItem> profileMenuItems;

  const MagicStarterNavigationConfig({
    required this.mainItems,
    this.systemItems = const [],
    this.bottomItems = const [],
    this.profileMenuItems = const [],
  });
}

/// Manager for Magic Starter.
class MagicStarterManager {
  /// Creates a new manager instance and registers default views.
  ///
  /// Intended to be instantiated by [MagicStarterServiceProvider] and
  /// resolved via IoC: `Magic.make<MagicStarterManager>('magic_starter')`.
  MagicStarterManager() {
    registerDefaultViews();
  }

  final MagicStarterViewRegistry _viewRegistry = MagicStarterViewRegistry();

  /// User model factory. Override to use your app's User model.
  UserModelFactory userFactory = (data) => MagicStarterAuthUser.fromMap(data);

  /// Team resolver callbacks. Null when not configured.
  MagicStarterTeamResolverConfig? teamResolver;

  /// Navigation config. Null when not configured (uses defaults).
  MagicStarterNavigationConfig? navigationConfig;

  /// Custom logout callback. When set, called instead of default logout.
  ///
  /// The [beforeLogout] hooks still run first, so a custom callback never has
  /// to repeat the package's own pre-sign-out work.
  Future<void> Function()? onLogout;

  /// How long one [beforeLogout] hook may run before the sign-out goes on
  /// without it.
  ///
  /// Five seconds because a hook is typically one request to the app's own
  /// backend: long enough for a slow mobile link, short enough that a dead one
  /// cannot trap somebody who asked to leave.
  static const Duration beforeLogoutTimeout = Duration(seconds: 5);

  /// The hooks [runBeforeLogoutHooks] awaits, in registration order.
  final List<Future<void> Function()> _beforeLogoutHooks = [];

  /// The registered [beforeLogout] hooks, in the order they run.
  List<Future<void> Function()> get beforeLogoutHooks =>
      List.unmodifiable(_beforeLogoutHooks);

  /// Registers [hook] to run before every sign-out the user asks for, while
  /// the session token is still valid.
  ///
  /// Both starter sign-out paths await it ([signOut], ahead of a custom
  /// [onLogout], and [MagicStarterAuthController.logout], ahead of
  /// `Auth.logout()`), so a hook can still make authenticated requests: a
  /// push-device release, a server-side session revoke.
  ///
  /// A hook that is already registered is not added twice, so a provider that
  /// boots twice (hot restart) does not release a device twice per sign-out.
  ///
  /// Not run for a sign-out the app performs on its own: magic's
  /// `AuthInterceptor` calls `Auth.logout()` after a failed token refresh, and
  /// by then the token is already dead, so an authenticated hook could only
  /// answer 401.
  void beforeLogout(Future<void> Function() hook) {
    if (_beforeLogoutHooks.contains(hook)) return;

    _beforeLogoutHooks.add(hook);
  }

  /// Awaits every [beforeLogout] hook in registration order, each isolated and
  /// bounded by [beforeLogoutTimeout].
  ///
  /// Never throws. A hook that fails or runs out of time is logged and the next
  /// one runs, because a sign-out the user asked for has to happen whatever a
  /// hook's network does. A host with its own sign-out button calls this
  /// before its own `Auth.logout()`.
  Future<void> runBeforeLogoutHooks() async {
    // Snapshot first: a hook that registers another would otherwise mutate the
    // list mid-iteration.
    for (final Future<void> Function() hook in List.of(_beforeLogoutHooks)) {
      try {
        await hook().timeout(beforeLogoutTimeout);
      } catch (error, stackTrace) {
        Log.error(
          '[MagicStarter] before-logout hook failed: $error\n$stackTrace',
        );
      }
    }
  }

  /// Ends the session the user asked to leave, running the [beforeLogout]
  /// hooks exactly once.
  ///
  /// With a custom [onLogout], the hooks run here and the callback replaces the
  /// default sign-out entirely. Without one, [MagicStarterAuthController.logout]
  /// runs the hooks itself, stops the notification services when that feature
  /// is on, calls `Auth.logout()` and navigates to the login route; running the
  /// hooks here too would release a push device twice.
  Future<void> signOut() async {
    final customLogout = onLogout;

    if (customLogout != null) {
      await runBeforeLogoutHooks();
      await customLogout();
      return;
    }

    await MagicStarterAuthController.instance.logout();
  }

  /// The team a switch was just accepted for, held only while that switch
  /// identifies the store rail.
  ///
  /// `Auth.restore()` returns with the CACHED user and syncs the fresh one in
  /// the background (magic's `BaseGuard.restore`), so right after a successful
  /// switch the team resolver still names the team being left. Identifying
  /// from the resolver there would bind the store account to that team.
  String? _landedTeamId;

  /// The active team's id as a string, or `null` without a team resolver or
  /// an active team.
  ///
  /// A string whatever the consumer's id type, so an int id from one source and
  /// a string id from another (a link, a push payload) compare equal.
  String? currentTeamId() => teamResolver?.currentTeam()?.id?.toString();

  /// The id the store rail is identified as for [billable], or `null` while
  /// nobody is signed in or no team is active.
  String? billableId(MagicStarterBillable billable) {
    if (!Auth.check()) return null;

    return switch (billable) {
      MagicStarterBillable.user => '${Auth.id()}',
      MagicStarterBillable.team => _landedTeamId ?? currentTeamId(),
    };
  }

  /// Switches the active team to [teamId] and answers whether the backend
  /// accepted it.
  ///
  /// On success the store rail is re-identified as the paying subject
  /// ([StoreIdentitySync.syncNow], a no-op in a build without a store rail),
  /// so a purchase made after the switch is not attributed to the team that
  /// was left. A refused switch identifies nothing: the session is still on
  /// the team it was on.
  ///
  /// A failed re-identify does not undo a successful switch. The team change
  /// already happened on the backend by the time [StoreIdentitySync.syncNow]
  /// runs, so a caller that read this future's failure as "the switch failed"
  /// (magic_deeplink's gate is one; it calls `onSwitchFailed` instead of
  /// `onSwitchSucceeded`) would report a landed switch as refused. Logged
  /// rather than swallowed: `syncNow` already logs its own
  /// [BillingException]s and returns normally, so anything that reaches this
  /// catch is something else, an error worth keeping visible.
  Future<bool> switchTeam(String teamId) async {
    final bool switched = await MagicStarterTeamController.instance.switchTeam(
      teamId,
    );
    if (!switched) return false;

    _landedTeamId = teamId;
    try {
      await StoreIdentitySync.syncNow();
    } catch (error, stackTrace) {
      Log.error(
        '[MagicStarter] store identity sync after team switch failed: '
        '$error\n$stackTrace',
      );
    } finally {
      _landedTeamId = null;
    }

    return true;
  }

  /// Custom login callback. When set, called after a fresh sign-in.
  ///
  /// Fires on `AuthLogin` (see [MagicStarterServiceProvider]'s registration
  /// in `register()`): password, two-factor challenge, social, guest, and
  /// phone OTP sign-ins. Deliberately NOT called on a cold-boot restore of a
  /// stored session or a team switch: both go through `Auth.restore()`,
  /// which dispatches `AuthRestored`, and only once an API sync confirms the
  /// user (never offline, never on a failed sync, never without a
  /// `userEndpoint` configured); neither path ever dispatches `AuthLogin`.
  Future<void> Function()? onLogin;

  /// Called when a guest claim settles, with any outcome but
  /// [GuestClaimOutcome.none].
  ///
  /// Fires from the `AuthLogin` and `AuthRestored` listeners the service
  /// provider registers while the guest-auth feature is on, after
  /// [MagicStarterGuestClaim.claimIfPending] answers. Every outcome it
  /// receives marks the first sign-in to a real account after a guest session
  /// on this device. Runs unawaited, so it never holds up the sign-in; a
  /// throw is logged.
  Future<void> Function(GuestClaimOutcome outcome)? onGuestClaimed;

  /// Called after the user changed the account's "Share usage data" choice and
  /// the backend accepted it, with the new value; [optedOut] true means the
  /// account stopped sharing.
  ///
  /// Runs once the choice is applied on this device. `magic_analytics` drops
  /// `identify`, `setUserProperties` and `setDefaultParams` while opted out, so
  /// a host that uses it and sets them re-applies them here when [optedOut]
  /// turns false.
  /// Deliberately NOT called when the starter applies the account's choice on
  /// boot or after a sign-in: nothing changed then. Awaited by the controller;
  /// a throw is logged and the save still counts.
  Future<void> Function(bool optedOut)? onAnalyticsPreferenceChanged;

  /// How the account's "Share usage data" choice reaches this device's
  /// analytics, called wherever the starter applies it: the cached choice on
  /// boot, the account's answer after a sign-in or restore, a saved switch, and
  /// the lift on sign-out (`false`).
  ///
  /// Required while `magic_starter.features.analytics` is on: the starter
  /// imports no analytics package, so this hook is the only connection, and
  /// `MagicStarterServiceProvider.boot()` throws a [StateError] without it. Set
  /// it from the host's own provider boot (the usual place is the
  /// `applyAnalyticsOptOut:` argument of `MagicStarter.bootstrap()`), for
  /// example `(optedOut) => Analytics.setOptOut(optedOut)` with `magic_analytics`
  /// installed in the host (`flutter pub add`, then `plugin:install`).
  ///
  /// A host with its own reason to stay opted out, such as a device-level
  /// consent refusal, combines the two here; otherwise the account's choice
  /// would overwrite the host's. Awaited; a throw propagates to the caller,
  /// which logs it.
  ///
  /// The starter calls it one change at a time, in the order the changes were
  /// made, so a hook that awaits never finishes an older change after a newer
  /// one. It runs inside its turn of that queue: it must not sign out or call
  /// the analytics controller's device applies or `updateAnalyticsPreference`,
  /// which would wait on the turn the hook is part of.
  Future<void> Function(bool accountOptedOut)? applyAnalyticsOptOut;

  /// Custom header builder. When set, replaces the default header.
  Widget Function(BuildContext context, bool isDesktop)? headerBuilder;

  /// Custom sidebar footer builder. When set, rendered between the
  /// navigation and user menu in both the desktop sidebar and mobile drawer.
  Widget Function(BuildContext context)? sidebarFooterBuilder;

  /// The app's social login bridge. While set and the `social_login` feature
  /// is on, login and register offer its providers.
  MagicStarterSocialAuth? socialAuth;

  /// What the host says the customer is looking at, asked each time a support
  /// message is sent. Null while the host registers none, which sends no page
  /// context.
  List<MagicStarterSupportPageRef> Function()? pageContextProvider;

  /// Navigation theme configuration. Holds color/className overrides for the
  /// app layout navigation elements (active item, brand, bottom nav, avatar).
  MagicStarterNavigationTheme navigationTheme =
      const MagicStarterNavigationTheme();

  /// Modal theme configuration. Holds className overrides for modal containers,
  /// headers, bodies, footers, buttons, inputs, and typography.
  MagicStarterModalTheme modalTheme = const MagicStarterModalTheme();

  /// Form theme configuration. Holds className overrides for inputs, labels,
  /// placeholders, and primary/secondary/link button styles in all forms.
  MagicStarterFormTheme formTheme = const MagicStarterFormTheme();

  /// Auth theme configuration. Holds className overrides for the auth form
  /// card, title, subtitle, error banner, social divider, and link styles.
  MagicStarterAuthTheme authTheme = const MagicStarterAuthTheme();

  /// Card widget theme configuration. Holds className overrides for card
  /// variant backgrounds, border radius, padding, and title styles.
  MagicStarterCardTheme cardTheme = const MagicStarterCardTheme();

  /// Dropdown theme configuration. Holds the colour className overrides for the
  /// team switcher and user menu popover panels.
  MagicStarterDropdownTheme dropdownTheme = const MagicStarterDropdownTheme();

  /// Button theme configuration. Holds the className overrides for the shape,
  /// the three sizes and the secondary border of [MSButton].
  MagicStarterButtonTheme buttonTheme = const MagicStarterButtonTheme();

  /// Field theme configuration. Holds the className overrides for the height
  /// and type of [MSInput], the [MSSelect] and [MSCombobox] triggers, and the
  /// [MSSegmentedControl] segments and root padding.
  MagicStarterFieldTheme fieldTheme = const MagicStarterFieldTheme();

  /// Page header theme configuration. Holds className overrides for the
  /// page header container, title, subtitle, and action container.
  MagicStarterPageHeaderTheme pageHeaderTheme =
      const MagicStarterPageHeaderTheme();

  /// The page chrome a host can claim, and the entries the mounted page
  /// headers report to it. One instance for the manager's lifetime, so a
  /// host's bar keeps listening to the same notifier across [reset].
  final MagicStarterPageChrome pageChrome = MagicStarterPageChrome();

  /// Layout shell theme configuration. Holds className/dimension overrides for
  /// the sidebar, header, content background, drawer, and brand bar.
  MagicStarterLayoutTheme layoutTheme = const MagicStarterLayoutTheme();

  /// The page geometry [MSPageContainer] applies when the host configures
  /// nothing: width cap, horizontal edge margins, and vertical rhythm.
  ///
  /// The cap is generous on purpose: a narrow centred strip leaves large empty
  /// gutters on a desktop window, which is what this value was widened to avoid.
  static const String defaultPageContainerClassName =
      'max-w-7xl px-4 lg:px-8 pt-6 sm:pt-8 pb-16';

  /// The Wind geometry every page container in the app shares.
  ///
  /// A host app caps its own pages at its own width and pads them on its own
  /// grid, and this package's pages render inside that same shell. So the
  /// geometry is the HOST's to choose, and it has to be ONE choice: when the
  /// starter kept its own answer here, its settings pages centred 64px further
  /// out per side than the host's pages (`max-w-7xl` against a `max-w-6xl`
  /// host), and its team pages, which capped at nothing at all, spread the full
  /// width of the window. Set it once in a service provider and every page in
  /// the app, starter-owned or host-owned, lines up by construction.
  ///
  /// Carry the whole geometry in this one string rather than splitting it across
  /// several knobs: a cap that agrees while the padding does not still reads as
  /// two different pages.
  String pageContainerClassName = defaultPageContainerClassName;

  /// Get the unified theme built from all individual sub-theme fields.
  ///
  /// Reading this constructs a [MagicStarterTheme] from the current values of
  /// [navigationTheme], [modalTheme], [formTheme], [cardTheme],
  /// [pageHeaderTheme], [layoutTheme], [authTheme], [dropdownTheme],
  /// [buttonTheme], and [fieldTheme].
  MagicStarterTheme get theme => MagicStarterTheme(
    navigation: navigationTheme,
    modal: modalTheme,
    form: formTheme,
    card: cardTheme,
    pageHeader: pageHeaderTheme,
    layout: layoutTheme,
    auth: authTheme,
    dropdown: dropdownTheme,
    button: buttonTheme,
    field: fieldTheme,
  );

  /// Set the unified theme, distributing each sub-theme to its individual field.
  ///
  /// This is equivalent to setting [navigationTheme], [modalTheme],
  /// [formTheme], [cardTheme], [pageHeaderTheme], [layoutTheme], [authTheme],
  /// [dropdownTheme], [buttonTheme], and [fieldTheme] separately.
  set theme(MagicStarterTheme value) {
    navigationTheme = value.navigation;
    modalTheme = value.modal;
    formTheme = value.form;
    cardTheme = value.card;
    pageHeaderTheme = value.pageHeader;
    layoutTheme = value.layout;
    authTheme = value.auth;
    dropdownTheme = value.dropdown;
    buttonTheme = value.button;
    fieldTheme = value.field;
  }

  /// What the last [applyWindTheme] left to the palette: the derived value of
  /// every field the palette owns, and the stock value of every field the host
  /// owns, or the stock theme before the first call. A field still holding its
  /// value here is the palette's, so the next palette may replace it; a host
  /// field is recorded as stock so that a later palette deriving the same
  /// value does not take it over.
  MagicStarterTheme _windDerived = const MagicStarterTheme();

  /// Derives the sub-themes from [wind] through [MagicStarterTheme.fromWind]
  /// and applies them to every field the host has not set, keeping the ones
  /// it has, so the call order against the `use*Theme` setters does not
  /// matter for a host-set field.
  ///
  /// The rule, per field of every sub-theme: the field is host-set when its
  /// current value differs both from that sub-theme's default constructor value
  /// and from what the previous call left to the palette for it; a host-set
  /// field is kept, any other field takes the derived value. A layout
  /// background's colour and shade are one field for this rule, since `wColor`
  /// reads them together. A host field stays the host's when a later palette
  /// happens to derive the same value. Two consequences follow. A host
  /// value equal to the stock default reads as unset and is derived over, so
  /// a host that wants the stock value back on top of a palette sets it after
  /// this call. And a second call re-derives what the first one derived,
  /// which is what switching palettes at runtime needs.
  ///
  /// [theme] (and [MagicStarter.useTheme]) still replace every sub-theme.
  void applyWindTheme(WindThemeData wind) {
    final MagicStarterTheme derived = MagicStarterTheme.fromWind(wind);
    final MagicStarterTheme current = theme;
    final MagicStarterTheme previous = _windDerived;

    // One merge gives both results: with `record` off the theme to apply, with
    // it on what the palette owns afterwards.
    MagicStarterTheme merge(bool record) => MagicStarterTheme(
      navigation: _mergeNavigation(
        _WindMerge(
          current.navigation,
          previous.navigation,
          derived.navigation,
          const MagicStarterNavigationTheme(),
          record,
        ),
      ),
      modal: _mergeModal(
        _WindMerge(
          current.modal,
          previous.modal,
          derived.modal,
          const MagicStarterModalTheme(),
          record,
        ),
      ),
      form: _mergeForm(
        _WindMerge(
          current.form,
          previous.form,
          derived.form,
          const MagicStarterFormTheme(),
          record,
        ),
      ),
      card: _mergeCard(
        _WindMerge(
          current.card,
          previous.card,
          derived.card,
          const MagicStarterCardTheme(),
          record,
        ),
      ),
      pageHeader: _mergePageHeader(
        _WindMerge(
          current.pageHeader,
          previous.pageHeader,
          derived.pageHeader,
          const MagicStarterPageHeaderTheme(),
          record,
        ),
      ),
      layout: _mergeLayout(
        _WindMerge(
          current.layout,
          previous.layout,
          derived.layout,
          const MagicStarterLayoutTheme(),
          record,
        ),
      ),
      auth: _mergeAuth(
        _WindMerge(
          current.auth,
          previous.auth,
          derived.auth,
          const MagicStarterAuthTheme(),
          record,
        ),
      ),
      dropdown: _mergeDropdown(
        _WindMerge(
          current.dropdown,
          previous.dropdown,
          derived.dropdown,
          const MagicStarterDropdownTheme(),
          record,
        ),
      ),
      button: _mergeButton(
        _WindMerge(
          current.button,
          previous.button,
          derived.button,
          const MagicStarterButtonTheme(),
          record,
        ),
      ),
      field: _mergeField(
        _WindMerge(
          current.field,
          previous.field,
          derived.field,
          const MagicStarterFieldTheme(),
          record,
        ),
      ),
    );

    theme = merge(false);
    _windDerived = merge(true);
  }

  /// Native language names for common locale codes.
  /// Used to generate human-readable labels from [Lang.supportedLocales].
  static const Map<String, String> _nativeLanguageNames = {
    'en': 'English',
    'tr': 'Türkçe',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'nl': 'Nederlands',
    'ru': 'Русский',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
    'ar': 'العربية',
  };

  /// Locale options for language selection.
  ///
  /// Reads from [Lang.supportedLocales] (configured via
  /// `localization.supported_locales`)
  /// and converts them to [SelectOption] with native language labels.
  /// Override via [localeOptions] setter for custom labels.
  List<SelectOption<String>> get localeOptions {
    if (_localeOptions != null) return _localeOptions!;
    return Lang.supportedLocales
        .map(
          (locale) => SelectOption<String>(
            value: locale.languageCode,
            label:
                _nativeLanguageNames[locale.languageCode] ??
                locale.languageCode.toUpperCase(),
          ),
        )
        .toList(growable: false);
  }

  set localeOptions(List<SelectOption<String>> options) {
    _localeOptions = options;
  }

  List<SelectOption<String>>? _localeOptions;

  /// Target of an in-flight [applyLocale] call, or `null` when none is
  /// pending.
  String? _pendingLocale;

  /// Locale an in-flight [Lang.setLocale] call is currently switching to, or
  /// `null` when no switch is awaiting its catalogue load.
  ///
  /// `Translator.load` only updates [Lang.current] once its OWN catalogue
  /// load resolves, so for the whole duration of that await [Lang.current]
  /// still reports the locale being REPLACED, not the one in flight. A call
  /// that arrives during that window and trusts [Lang.current] alone reads a
  /// stale answer twice: once to decide whether it is redundant, and once
  /// more, in its own callback, to decide whether to actually switch (which
  /// is how a second target used to get silently dropped on the floor while
  /// the first one was still loading). Both guards in [applyLocale] read
  /// through this field first so they see the target actually in flight.
  String? _applyingLocale;

  /// Switches the running app's locale to [code], deduplicating against
  /// whichever caller reaches this first in the same frame.
  ///
  /// `MagicStarterServiceProvider`'s `Auth.stateNotifier` listener and
  /// `MagicStarterProfileController.doUpdateProfile` both call this: a
  /// profile save persists a new `locale` and then calls `Auth.restore()`,
  /// which bumps the very notifier the provider listens on, so both can
  /// reach this method in the same frame. A shared pending target is what
  /// keeps that pairing to exactly one [Lang.setLocale] call regardless of
  /// how long the catalogue load takes: a real app loads it from assets
  /// asynchronously (`compute()`, past 50 KB), so a fixed number of deferred
  /// frames cannot be relied on to outlast it.
  ///
  /// A no-op when [code] is empty, or when [code] is already the pending
  /// target (or, with nothing pending, whatever switch is currently in
  /// flight, or, with neither, the current locale). Otherwise records [code]
  /// as the new pending target, superseding whatever was pending before it,
  /// and defers the switch to a post-frame callback.
  ///
  /// Deferred rather than switched synchronously: [Lang.setLocale] calls
  /// `Magic.reload()`, which unmounts whatever is mid-build or mid-await
  /// right now, and both callers reach this off a `ValueNotifier` callback or
  /// mid `await` in an async method. `addPostFrameCallback` does not ASK for
  /// a frame, and an idle app stops producing them, so
  /// [WidgetsBinding.scheduleFrame] runs alongside it.
  void applyLocale(String code) {
    if (code.isEmpty) return;
    final String current = _applyingLocale ?? Lang.current.languageCode;
    if (code == (_pendingLocale ?? current)) return;

    _pendingLocale = code;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // A later call superseded this one before its frame arrived; the
      // superseding call owns the switch now.
      if (_pendingLocale != code) return;

      // A different switch is already in flight. `Lang.current` cannot tell
      // this call whether it is redundant (see [_applyingLocale]'s doc), so
      // rather than guess it leaves its target in `_pendingLocale`: the
      // in-flight switch chases it, below, once it settles.
      if (_applyingLocale != null) return;

      await _performLocaleSwitch(code);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Runs one [Lang.setLocale] call for [code] and, once it settles, chases
  /// whatever target arrived in `_pendingLocale` while it was in flight.
  ///
  /// Split out of [applyLocale] so the chase can run its own await and its
  /// own follow-up chase without another post-frame round trip: by the time
  /// this runs, [applyLocale]'s deferral has already happened once, so a
  /// chased switch is not started mid-build.
  Future<void> _performLocaleSwitch(String code) async {
    _pendingLocale = null;
    _applyingLocale = code;
    try {
      if (Lang.current.languageCode != code) {
        await Lang.setLocale(Locale(code));
      }
    } catch (error, stackTrace) {
      // Logged rather than rethrown: this runs off a post-frame callback (or
      // a chase from one), where a throw becomes an unhandled async error.
      Log.error(
        '[MagicStarter] applying locale "$code" failed: $error\n$stackTrace',
      );
    } finally {
      if (_applyingLocale == code) _applyingLocale = null;
    }

    // A newer target arrived while this switch was in flight: `Lang.current`
    // stayed on the OLD locale for the whole await, so that caller's own
    // callback read this switch as not-yet-applied and backed off instead of
    // running it. Chase it now that this switch has actually settled.
    //
    // A pending target equal to the one just applied (reverted and restored
    // while in flight) is already satisfied and must be cleared, or it would
    // read as "already pending" to the next request for the same code.
    final String? next = _pendingLocale;
    if (next == code) {
      _pendingLocale = null;
    } else if (next != null) {
      await _performLocaleSwitch(next);
    }
  }

  /// Guest authentication entry point builder.
  /// When set, renders custom widget for guest/anonymous login flows.
  Widget Function()? guestAuthEntryBuilder;

  /// Custom label for the newsletter signup feature.
  String? newsletterLabel;

  /// Global view registry used for plugin view overrides.
  MagicStarterViewRegistry get view => _viewRegistry;

  /// Registers plugin-provided default views if they are not overridden yet.
  void registerDefaultViews() {
    // Views
    _registerDefault('auth.login', () => const MagicStarterLoginView());
    _registerDefault('auth.register', () => const MagicStarterRegisterView());
    _registerDefault(
      'auth.forgot_password',
      () => const MagicStarterForgotPasswordView(),
    );
    _registerDefault(
      'auth.reset_password',
      () => const MagicStarterResetPasswordView(),
    );
    if (MagicStarterConfig.hasEmailVerificationFeatures()) {
      _registerDefault(
        'auth.verify_email',
        () => const MagicStarterVerifyEmailView(),
      );
    }
    // Two-factor challenge — conditional on feature flag.
    if (MagicStarterConfig.hasTwoFactorFeatures()) {
      _registerDefault(
        'auth.two_factor_challenge',
        () => const MagicStarterTwoFactorChallengeView(),
      );
    }

    if (MagicStarterConfig.hasHandoffFeatures()) {
      _registerDefault('auth.handoff', () => const MagicStarterHandoffView());
    }

    // Phone OTP — conditional on feature flag.
    if (MagicStarterConfig.hasPhoneOtpFeatures()) {
      _registerDefault(
        'auth.otp_verify',
        () => const MagicStarterOtpVerifyView(),
      );
    }

    // Settings — iOS-style hub + drill-down sub-pages. The hub, Profile,
    // Appearance, and Password sub-pages are always registered; the rest
    // mirror their feature toggles (and the routes that gate them).
    _registerDefault('settings.hub', () => const MagicStarterSettingsHubView());
    _registerDefault(
      'profile.profile',
      () => const MagicStarterProfileSubPageView(),
    );
    _registerDefault(
      'settings.appearance',
      () => const MagicStarterAppearanceView(),
    );
    _registerDefault(
      'settings.security.password',
      () => const MagicStarterPasswordView(),
    );

    // Language — extended profile / locale selection.
    if (MagicStarterConfig.hasExtendedProfileFeatures()) {
      _registerDefault(
        'settings.language',
        () => const MagicStarterLanguageView(),
      );
    }

    // Timezone.
    if (MagicStarterConfig.hasTimezoneFeatures()) {
      _registerDefault(
        'settings.timezone',
        () => const MagicStarterTimezoneView(),
      );
    }

    // Email & privacy: the newsletter page, which also holds the analytics
    // switch.
    if (MagicStarterConfig.hasNewsletterFeatures() ||
        MagicStarterConfig.hasAnalyticsFeatures()) {
      _registerDefault(
        'settings.newsletter',
        () => const MagicStarterNewsletterView(),
      );
    }

    // Changelog.
    if (MagicStarterConfig.hasReleasesFeatures()) {
      _registerDefault(
        'settings.changelog',
        () => const MagicStarterChangelogView(),
      );
    }

    // Security — Two-Factor.
    if (MagicStarterConfig.hasTwoFactorFeatures()) {
      _registerDefault(
        'settings.security.two_factor',
        () => const MagicStarterTwoFactorView(),
      );
    }

    // Security — Active Sessions.
    if (MagicStarterConfig.hasSessionsFeatures()) {
      _registerDefault(
        'settings.security.sessions',
        () => const MagicStarterSessionsView(),
      );
    }

    // Security: Connected accounts.
    if (MagicStarterConfig.hasSocialLoginFeatures()) {
      _registerDefault(
        'settings.security.connected_accounts',
        () => const MagicStarterConnectedAccountsView(),
      );
    }

    // Teams — conditional on feature flag.
    if (MagicStarterConfig.hasTeamFeatures()) {
      _registerDefault(
        'teams.create',
        () => const MagicStarterTeamCreateView(),
      );
      _registerDefault(
        'teams.settings',
        () => const MagicStarterTeamSettingsView(),
      );
      _registerDefault(
        'teams.invitation_accept',
        () => const MagicStarterTeamInvitationAcceptView(),
      );
    }

    // Billing, conditional on its OWN feature flag rather than on teams'.
    //
    // The key sits in the `teams.` area because that is where the route lives
    // (`MagicStarterConfig.billingRoute()` defaults to `/teams/billing`), but a
    // subscription is bought by whoever holds the account, so an app with no
    // team features can still sell one. Nesting this inside the teams block
    // above would make the billing toggle silently depend on a second one.
    if (MagicStarterConfig.hasBillingFeatures()) {
      _registerDefault('teams.billing', () => const MagicStarterBillingView());
    }

    // Support desk, conditional on its own feature flag. The routes resolve
    // these keys (see `registerMagicStarterSupportRoutes`).
    if (MagicStarterConfig.hasSupportFeatures()) {
      _registerDefault(
        'support.index',
        () => const MagicStarterSupportIndexView(),
      );
      _registerDefault(
        'support.create',
        () => const MagicStarterSupportCreateView(),
      );
      _registerDefault(
        'support.thread',
        () => const MagicStarterSupportThreadView(),
      );

      if (MagicStarterConfig.hasSupportFeedbackFeatures()) {
        _registerDefault(
          'support.feedback',
          () => const MagicStarterFeedbackView(),
        );
      }

      // The chat: a host mounts `support.chat` where it wants the launcher,
      // and the launcher resolves its panel through `support.chat_panel`.
      if (MagicStarterConfig.hasSupportChatFeatures()) {
        _registerDefault(
          'support.chat',
          () => const MagicStarterSupportChatLauncher(),
        );
        _registerDefault(
          'support.chat_panel',
          () => const MagicStarterSupportChatPanel(),
        );
      }
    }

    // Notification screens are NOT registered here. They belong to
    // `magic_notifications`, which registers them on its own `Notify.view`
    // under the same two keys; `registerMagicStarterNotificationRoutes()`
    // re-registers them there wrapped in this package's page geometry. A
    // second copy of the keys on this registry would be a second answer
    // nothing reads.

    // Layouts
    _registerDefaultLayout(
      'layout.guest',
      (child) => MagicStarterGuestLayout(child: child),
    );
    _registerDefaultLayout(
      'layout.app',
      (child) => MagicStarterAppLayout(child: child),
    );
    // Modals
    _registerDefaultModal(
      'modal.confirm',
      () => MagicStarterConfirmDialog(title: trans('common.confirm')),
    );
    _registerDefaultModal(
      'modal.password_confirm',
      () => const MagicStarterPasswordConfirmDialog(),
    );
    _registerDefaultModal(
      'modal.two_factor',
      () => MagicStarterTwoFactorModal(
        setupData: const {},
        onConfirm: (_) async => false,
      ),
    );
  }

  void _registerDefault(String key, Widget Function() builder) {
    if (!_viewRegistry.has(key)) {
      _viewRegistry.register(key, builder);
    }
  }

  void _registerDefaultLayout(String key, Widget Function(Widget) builder) {
    if (!_viewRegistry.hasLayout(key)) {
      _viewRegistry.registerLayout(key, builder);
    }
  }

  void _registerDefaultModal(String key, Widget Function() builder) {
    if (!_viewRegistry.hasModal(key)) {
      _viewRegistry.registerModal(key, builder);
    }
  }

  /// Check if the starter is ready.
  /// Returns false when team features are enabled but no team resolver
  /// is configured.
  ///
  /// [MagicStarter.bootstrap] reads this and throws when it is false, so the
  /// missing team resolver surfaces at configuration time instead of as an
  /// empty team selector; `MagicStarterServiceProvider.boot()` additionally
  /// logs a warning for apps that wire the setters up individually.
  bool get isReady {
    // Read the flag through MagicStarterConfig so the config key lives in one
    // place; a second inline Config.get here could drift from the toggle every
    // other feature check uses.
    if (MagicStarterConfig.hasTeamFeatures() && teamResolver == null) {
      return false;
    }
    return true;
  }

  /// Reset manager state. Useful for test isolation.
  void reset() {
    userFactory = (data) => MagicStarterAuthUser.fromMap(data);
    teamResolver = null;
    navigationConfig = null;
    onLogout = null;
    _beforeLogoutHooks.clear();
    _landedTeamId = null;
    onLogin = null;
    onGuestClaimed = null;
    onAnalyticsPreferenceChanged = null;
    applyAnalyticsOptOut = null;
    headerBuilder = null;
    sidebarFooterBuilder = null;
    socialAuth = null;
    pageContextProvider = null;
    navigationTheme = const MagicStarterNavigationTheme();
    modalTheme = const MagicStarterModalTheme();
    formTheme = const MagicStarterFormTheme();
    authTheme = const MagicStarterAuthTheme();
    cardTheme = const MagicStarterCardTheme();
    pageHeaderTheme = const MagicStarterPageHeaderTheme();
    pageChrome.reset();
    layoutTheme = const MagicStarterLayoutTheme();
    dropdownTheme = const MagicStarterDropdownTheme();
    buttonTheme = const MagicStarterButtonTheme();
    fieldTheme = const MagicStarterFieldTheme();
    _windDerived = const MagicStarterTheme();
    _localeOptions = null;
    _pendingLocale = null;
    _applyingLocale = null;
    guestAuthEntryBuilder = null;
    newsletterLabel = null;
    _viewRegistry.clear();
    registerDefaultViews();
  }
}

// ---------------------------------------------------------------------------
// Wind theme merge
// ---------------------------------------------------------------------------

/// One sub-theme seen by [MagicStarterManager.applyWindTheme]: what is active,
/// what the previous call left to the palette, what this call derived, and the
/// stock default.
///
/// With [record] off a pick answers the merged value; with it on, what the
/// palette owns after the merge (the stock value for a field the host owns).
class _WindMerge<S> {
  final S current;
  final S previous;
  final S derived;
  final S stock;
  final bool record;

  const _WindMerge(
    this.current,
    this.previous,
    this.derived,
    this.stock,
    this.record,
  );

  /// Whether the host set [field]: it differs from the stock default and from
  /// what the previous call left to the palette.
  bool _hostSet<T>(T Function(S theme) field) {
    final T value = field(current);

    return value != field(stock) && value != field(previous);
  }

  /// The value of [field] after the merge: the active one when the host set
  /// it, the derived one otherwise.
  T pick<T>(T Function(S theme) field) {
    final S source = _hostSet(field) ? (record ? stock : current) : derived;

    return field(source);
  }

  /// [first] and [second] decided as one value: both from the host when the
  /// pair differs from the stock pair and from the pair the previous call left
  /// to the palette, both derived otherwise. The halves are not tested apart:
  /// a host pair can match the derived colour and the stock shade one half at
  /// a time and still be neither.
  (A, B) pickPair<A, B>(A Function(S theme) first, B Function(S theme) second) {
    (A, B) pair(S theme) => (first(theme), second(theme));
    final (A, B) value = pair(current);
    final bool hostSet = value != pair(stock) && value != pair(previous);
    final S source = hostSet ? (record ? stock : current) : derived;

    return (first(source), second(source));
  }
}

MagicStarterNavigationTheme _mergeNavigation(
  _WindMerge<MagicStarterNavigationTheme> m,
) {
  return MagicStarterNavigationTheme(
    activeItemClassName: m.pick((t) => t.activeItemClassName),
    hoverItemClassName: m.pick((t) => t.hoverItemClassName),
    brandClassName: m.pick((t) => t.brandClassName),
    brandBuilder: m.pick((t) => t.brandBuilder),
    compactBrandBuilder: m.pick((t) => t.compactBrandBuilder),
    bottomNavActiveClassName: m.pick((t) => t.bottomNavActiveClassName),
    avatarClassName: m.pick((t) => t.avatarClassName),
    avatarTextClassName: m.pick((t) => t.avatarTextClassName),
    dropdownAvatarClassName: m.pick((t) => t.dropdownAvatarClassName),
    dropdownAvatarTextClassName: m.pick((t) => t.dropdownAvatarTextClassName),
    focusItemClassName: m.pick((t) => t.focusItemClassName),
    badgeClassName: m.pick((t) => t.badgeClassName),
  );
}

MagicStarterModalTheme _mergeModal(_WindMerge<MagicStarterModalTheme> m) {
  return MagicStarterModalTheme(
    containerClassName: m.pick((t) => t.containerClassName),
    headerClassName: m.pick((t) => t.headerClassName),
    bodyClassName: m.pick((t) => t.bodyClassName),
    headlessBodyClassName: m.pick((t) => t.headlessBodyClassName),
    footerClassName: m.pick((t) => t.footerClassName),
    titleClassName: m.pick((t) => t.titleClassName),
    descriptionClassName: m.pick((t) => t.descriptionClassName),
    primaryButtonClassName: m.pick((t) => t.primaryButtonClassName),
    secondaryButtonClassName: m.pick((t) => t.secondaryButtonClassName),
    dangerButtonClassName: m.pick((t) => t.dangerButtonClassName),
    warningButtonClassName: m.pick((t) => t.warningButtonClassName),
    errorClassName: m.pick((t) => t.errorClassName),
    inputClassName: m.pick((t) => t.inputClassName),
    maxWidth: m.pick((t) => t.maxWidth),
    presentation: m.pick((t) => t.presentation),
    dialogBreakpoint: m.pick((t) => t.dialogBreakpoint),
  );
}

MagicStarterFormTheme _mergeForm(_WindMerge<MagicStarterFormTheme> m) {
  return MagicStarterFormTheme(
    inputClassName: m.pick((t) => t.inputClassName),
    labelClassName: m.pick((t) => t.labelClassName),
    errorClassName: m.pick((t) => t.errorClassName),
    placeholderClassName: m.pick((t) => t.placeholderClassName),
    primaryButtonClassName: m.pick((t) => t.primaryButtonClassName),
    secondaryButtonClassName: m.pick((t) => t.secondaryButtonClassName),
    linkClassName: m.pick((t) => t.linkClassName),
    checkboxLabelClassName: m.pick((t) => t.checkboxLabelClassName),
  );
}

MagicStarterCardTheme _mergeCard(_WindMerge<MagicStarterCardTheme> m) {
  return MagicStarterCardTheme(
    surfaceClassName: m.pick((t) => t.surfaceClassName),
    insetClassName: m.pick((t) => t.insetClassName),
    elevatedClassName: m.pick((t) => t.elevatedClassName),
    titleClassName: m.pick((t) => t.titleClassName),
    titleNoPaddingContainerClassName: m.pick(
      (t) => t.titleNoPaddingContainerClassName,
    ),
    borderRadius: m.pick((t) => t.borderRadius),
    paddingClassName: m.pick((t) => t.paddingClassName),
  );
}

MagicStarterPageHeaderTheme _mergePageHeader(
  _WindMerge<MagicStarterPageHeaderTheme> m,
) {
  return MagicStarterPageHeaderTheme(
    containerClassName: m.pick((t) => t.containerClassName),
    containerInlineClassName: m.pick((t) => t.containerInlineClassName),
    titleClassName: m.pick((t) => t.titleClassName),
    subtitleClassName: m.pick((t) => t.subtitleClassName),
    actionContainerClassName: m.pick((t) => t.actionContainerClassName),
    backControlClassName: m.pick((t) => t.backControlClassName),
    inlineActions: m.pick((t) => t.inlineActions),
    largeTitle: m.pick((t) => t.largeTitle),
    largeTitleClassName: m.pick((t) => t.largeTitleClassName),
    compactBarClassName: m.pick((t) => t.compactBarClassName),
    compactBarOpaqueClassName: m.pick((t) => t.compactBarOpaqueClassName),
    compactTitleClassName: m.pick((t) => t.compactTitleClassName),
    compactBarBlurSigma: m.pick((t) => t.compactBarBlurSigma),
  );
}

MagicStarterLayoutTheme _mergeLayout(_WindMerge<MagicStarterLayoutTheme> m) {
  // `wColor` reads a colour with its shade, so a host that set one half of a
  // background keeps the other half it had rather than the palette's.
  final (contentLightColor, contentLightShade) = m.pickPair(
    (t) => t.contentBackgroundLightColor,
    (t) => t.contentBackgroundLightShade,
  );
  final (contentDarkColor, contentDarkShade) = m.pickPair(
    (t) => t.contentBackgroundDarkColor,
    (t) => t.contentBackgroundDarkShade,
  );
  final (drawerLightColor, drawerLightShade) = m.pickPair(
    (t) => t.drawerBackgroundLightColor,
    (t) => t.drawerBackgroundLightShade,
  );
  final (drawerDarkColor, drawerDarkShade) = m.pickPair(
    (t) => t.drawerBackgroundDarkColor,
    (t) => t.drawerBackgroundDarkShade,
  );

  return MagicStarterLayoutTheme(
    sidebarClassName: m.pick((t) => t.sidebarClassName),
    sidebarWidth: m.pick((t) => t.sidebarWidth),
    navigationBreakpoint: m.pick((t) => t.navigationBreakpoint),
    sidebarExpandedBreakpoint: m.pick((t) => t.sidebarExpandedBreakpoint),
    sidebarCompactWidth: m.pick((t) => t.sidebarCompactWidth),
    sidebarCollapsible: m.pick((t) => t.sidebarCollapsible),
    sidebarCollapsedByDefault: m.pick((t) => t.sidebarCollapsedByDefault),
    headerClassName: m.pick((t) => t.headerClassName),
    headerHeight: m.pick((t) => t.headerHeight),
    contentBackgroundLightColor: contentLightColor,
    contentBackgroundLightShade: contentLightShade,
    contentBackgroundDarkColor: contentDarkColor,
    contentBackgroundDarkShade: contentDarkShade,
    drawerBackgroundLightColor: drawerLightColor,
    drawerBackgroundLightShade: drawerLightShade,
    drawerBackgroundDarkColor: drawerDarkColor,
    drawerBackgroundDarkShade: drawerDarkShade,
    brandBarClassName: m.pick((t) => t.brandBarClassName),
    bottomNavClassName: m.pick((t) => t.bottomNavClassName),
    contentClassName: m.pick((t) => t.contentClassName),
    contentScrollPrimary: m.pick((t) => t.contentScrollPrimary),
    notificationTriggerClassName: m.pick((t) => t.notificationTriggerClassName),
    notificationTriggerIconClassName: m.pick(
      (t) => t.notificationTriggerIconClassName,
    ),
    notificationPanelClassName: m.pick((t) => t.notificationPanelClassName),
    notificationBadgeClassName: m.pick((t) => t.notificationBadgeClassName),
    notificationBadgeTextClassName: m.pick(
      (t) => t.notificationBadgeTextClassName,
    ),
  );
}

MagicStarterAuthTheme _mergeAuth(_WindMerge<MagicStarterAuthTheme> m) {
  return MagicStarterAuthTheme(
    cardClassName: m.pick((t) => t.cardClassName),
    titleClassName: m.pick((t) => t.titleClassName),
    subtitleClassName: m.pick((t) => t.subtitleClassName),
    errorBannerClassName: m.pick((t) => t.errorBannerClassName),
    themeToggleClassName: m.pick((t) => t.themeToggleClassName),
    themeToggleIconClassName: m.pick((t) => t.themeToggleIconClassName),
    socialDividerClassName: m.pick((t) => t.socialDividerClassName),
    socialDividerLineClassName: m.pick((t) => t.socialDividerLineClassName),
    socialDividerTextClassName: m.pick((t) => t.socialDividerTextClassName),
    guestButtonClassName: m.pick((t) => t.guestButtonClassName),
    registrationLinkClassName: m.pick((t) => t.registrationLinkClassName),
    registrationLinkTextClassName: m.pick(
      (t) => t.registrationLinkTextClassName,
    ),
  );
}

MagicStarterDropdownTheme _mergeDropdown(
  _WindMerge<MagicStarterDropdownTheme> m,
) {
  return MagicStarterDropdownTheme(
    panelClassName: m.pick((t) => t.panelClassName),
    dividerClassName: m.pick((t) => t.dividerClassName),
    itemClassName: m.pick((t) => t.itemClassName),
    tileClassName: m.pick((t) => t.tileClassName),
    textClassName: m.pick((t) => t.textClassName),
    mutedTextClassName: m.pick((t) => t.mutedTextClassName),
    dangerTextClassName: m.pick((t) => t.dangerTextClassName),
    dangerTileClassName: m.pick((t) => t.dangerTileClassName),
  );
}

MagicStarterButtonTheme _mergeButton(_WindMerge<MagicStarterButtonTheme> m) {
  return MagicStarterButtonTheme(
    shapeClassName: m.pick((t) => t.shapeClassName),
    smClassName: m.pick((t) => t.smClassName),
    mdClassName: m.pick((t) => t.mdClassName),
    lgClassName: m.pick((t) => t.lgClassName),
    secondaryBorderClassName: m.pick((t) => t.secondaryBorderClassName),
  );
}

MagicStarterFieldTheme _mergeField(_WindMerge<MagicStarterFieldTheme> m) {
  return MagicStarterFieldTheme(
    inputSizeClassName: m.pick((t) => t.inputSizeClassName),
    selectSizeClassName: m.pick((t) => t.selectSizeClassName),
    segmentedSmClassName: m.pick((t) => t.segmentedSmClassName),
    segmentedMdClassName: m.pick((t) => t.segmentedMdClassName),
    segmentedPaddingClassName: m.pick((t) => t.segmentedPaddingClassName),
  );
}
