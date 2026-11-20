import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../../configuration/magic_starter_config.dart';
import '../../../../http/controllers/magic_starter_analytics_preference_controller.dart';
import '../../../../http/controllers/magic_starter_newsletter_controller.dart';
import '../../../components/settings_row/index.dart';
import '../../../components/page_scaffold/index.dart';
import '../../../components/settings_section/index.dart';
import '../../../components/switch/index.dart';

/// The "Email & privacy" settings sub-page: the newsletter subscription and
/// the account-level "Share usage data" switch.
///
/// The newsletter section renders when `newsletter` is on: a [MSSettingsRow]
/// with a trailing [MSSwitch] wired to
/// [MagicStarterNewsletterController.updateNewsletterSubscription], its status
/// fetched on init via `getNewsletterStatus`. The analytics section renders
/// when `analytics` is on and `magic_analytics`' provider is registered: one
/// switch wired to
/// [MagicStarterAnalyticsPreferenceController.updateAnalyticsPreference], on
/// while the account shares usage data, disabled until the account's choice is
/// read and while a save is in flight.
///
/// The class, the registry key `settings.newsletter` and the route
/// `MagicStarterConfig.settingsNewsletterRoute()` keep the newsletter name for
/// compatibility with hosts that override or link to them.
class MagicStarterNewsletterView
    extends MagicStatefulView<MagicStarterNewsletterController> {
  const MagicStarterNewsletterView({super.key});

  /// Whether the newsletter section renders: the feature is on and the user
  /// may manage the subscription (`starter.manage-newsletter`, which denies a
  /// guest).
  static bool showsNewsletter() =>
      MagicStarterConfig.hasNewsletterFeatures() &&
      Gate.allows('starter.manage-newsletter');

  /// Whether the "Share usage data" section renders: the feature is on and
  /// `magic_analytics`' provider is registered. Without the provider there is
  /// nothing on this device to apply the choice to, so the switch would only
  /// mislead.
  static bool showsAnalytics() =>
      MagicStarterConfig.hasAnalyticsFeatures() && Magic.bound('analytics');

  /// Whether the page has a section to show; the hub row hides otherwise, so
  /// it never leads to a page with only a title.
  static bool hasSections() => showsNewsletter() || showsAnalytics();

  @override
  State<MagicStarterNewsletterView> createState() =>
      _MagicStarterNewsletterViewState();
}

class _MagicStarterNewsletterViewState
    extends
        MagicStatefulViewState<
          MagicStarterNewsletterController,
          MagicStarterNewsletterView
        > {
  static const _iconNewsletter = Icons.mail_outline;
  static const _iconAnalytics = Icons.insights_outlined;
  static const _iconLoading = Icons.refresh;

  /// Isolated switch spinner, decoupled from the controller's global loading
  /// flag (mirrors the source view's per-section notifier pattern).
  final ValueNotifier<bool> _toggleLoading = ValueNotifier<bool>(false);

  /// Read once: a feature toggled after the page opened changes nothing here,
  /// as with every other settings page.
  final bool _showsNewsletter = MagicStarterNewsletterView.showsNewsletter();

  final bool _showsAnalytics = MagicStarterNewsletterView.showsAnalytics();

  MagicStarterAnalyticsPreferenceController get _analytics =>
      MagicStarterAnalyticsPreferenceController.instance;

  @override
  void onInit() {
    if (_showsNewsletter) {
      controller.getNewsletterStatus();
    }

    if (_showsAnalytics) {
      _analytics.getAnalyticsPreference();
    }
  }

  @override
  void onClose() {
    _toggleLoading.dispose();
  }

  /// Toggles the subscription optimistically through the controller.
  Future<void> _toggle(bool subscribe) async {
    _toggleLoading.value = true;
    try {
      await controller.updateNewsletterSubscription(subscribe: subscribe);
    } finally {
      _toggleLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MSPageScaffold(
      title: trans('magic_starter.privacy.title'),
      subtitle: trans('magic_starter.privacy.description'),
      backLabel: trans('profile.settings'),
      backFallback: MagicStarterConfig.settingsHubRoute(),
      children: [
        if (_showsNewsletter) _buildNewsletterSection(),
        if (_showsAnalytics) _buildAnalyticsSection(),
      ],
    );
  }

  Widget _buildNewsletterSection() {
    return MSSettingsSection(
      footer: trans('magic_starter.newsletter.section_description'),
      children: [
        controller.renderState(
          (data) {
            final isSubscribed = data?['subscribed'] as bool? ?? false;
            return ValueListenableBuilder<bool>(
              valueListenable: _toggleLoading,
              builder: (context, isLoading, _) => MSSettingsRow(
                icon: _iconNewsletter,
                title: trans('magic_starter.newsletter.toggle_label'),
                subtitle: isSubscribed
                    ? trans('magic_starter.newsletter.subscribed_status')
                    : trans('magic_starter.newsletter.unsubscribed_status'),
                trailing: MSSwitch(
                  value: isSubscribed,
                  disabled: isLoading,
                  onChanged: (newValue) => _toggle(newValue),
                ),
              ),
            );
          },
          onEmpty: MSSettingsRow(
            icon: _iconNewsletter,
            title: trans('magic_starter.newsletter.toggle_label'),
            trailing: WIcon(
              _iconLoading,
              className: 'text-fg-muted animate-spin text-xl',
            ),
          ),
        ),
      ],
    );
  }

  /// One row in every controller state, so the switch never leaves the page:
  /// the read and a save disable it, and an error replaces its description.
  Widget _buildAnalyticsSection() {
    return MSSettingsSection(
      children: [
        _analytics.renderState(
          (_) => _buildAnalyticsRow(),
          onLoading: _buildAnalyticsRow(),
          onEmpty: _buildAnalyticsRow(),
          onError: (message) => _buildAnalyticsRow(error: message),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow({String? error}) {
    final bool? optedOut = _analytics.optedOut;
    final String title = trans('magic_starter.analytics.toggle_label');

    return MSSettingsRow(
      icon: _iconAnalytics,
      title: title,
      subtitle: error ?? trans('magic_starter.analytics.toggle_description'),
      trailing: MSSwitch(
        value: optedOut == false,
        disabled: optedOut == null || _analytics.isLoading,
        semanticLabel: title,
        onChanged: (bool shares) =>
            _analytics.updateAnalyticsPreference(optedOut: !shares),
      ),
    );
  }
}
