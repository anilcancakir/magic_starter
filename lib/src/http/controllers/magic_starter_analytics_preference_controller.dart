import 'package:magic/magic.dart';
import 'package:magic_analytics/magic_analytics.dart';

import '../../facades/magic_starter.dart';

/// Controller for the account-level "Share usage data" choice on the Email &
/// privacy page.
///
/// The choice lives on the account (`GET` and `PUT /user/analytics`, answered
/// as `{"opted_out": bool}`), so turning it off on one device turns it off on
/// every device the account signs in on. A save is applied on this device only
/// after the backend accepted it: `magic_analytics`' opt-out, the vault copy a
/// cold start reads ([deviceCacheKey]), then the host's
/// `MagicStarterManager.onAnalyticsPreferenceChanged` hook.
class MagicStarterAnalyticsPreferenceController extends MagicController
    with MagicStateMixin, ValidatesRequests {
  /// Singleton accessor; use this instead of constructing directly.
  static MagicStarterAnalyticsPreferenceController get instance =>
      Magic.findOrPut(MagicStarterAnalyticsPreferenceController.new);

  /// The vault key holding this device's copy of the account's choice: `'1'`
  /// while the account has opted out, absent otherwise.
  ///
  /// `magic_analytics` keeps its opt-out in memory, so without this copy every
  /// cold start would collect until the account's answer arrived.
  static const String deviceCacheKey = 'magic_starter.analytics_opted_out';

  bool _isSubmitting = false;

  bool? _optedOut;

  /// The account's choice as the backend last answered it, `true` when the
  /// account has opted out; null until a read or a save has answered.
  bool? get optedOut => _optedOut;

  /// Reads the account's choice.
  Future<void> getAnalyticsPreference() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    setLoading();

    try {
      final MagicResponse response = await Http.get('/user/analytics');

      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('magic_starter.analytics.fetch_error'),
        );
        return;
      }

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      _optedOut = data['opted_out'] as bool;
      setSuccess(data);
    } catch (e, stackTrace) {
      Log.error(
        '[MagicStarterAnalyticsPreferenceController.getAnalyticsPreference] '
        '$e\n$stackTrace',
      );
      setError(trans('errors.unexpected'));
    } finally {
      _isSubmitting = false;
    }
  }

  /// Saves the account's choice; [optedOut] true stops sharing usage data.
  ///
  /// A refused or failed save applies nothing on this device and sets
  /// `magic_starter.analytics.update_error`.
  Future<void> updateAnalyticsPreference({required bool optedOut}) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    setLoading();

    try {
      final MagicResponse response = await Http.put(
        '/user/analytics',
        data: {'opted_out': optedOut},
      );

      if (!response.successful) {
        setError(trans('magic_starter.analytics.update_error'));
        return;
      }

      // 1. Apply on this device only now, so a refused save leaves the device
      //    collecting exactly as the account still says.
      await applyOnDevice(optedOut);
      _optedOut = optedOut;
      setSuccess(response.data as Map<String, dynamic>);

      // 2. Last, so the host re-applies identity on a device already opted in.
      await _notifyHost(optedOut);
    } catch (e, stackTrace) {
      Log.error(
        '[MagicStarterAnalyticsPreferenceController.updateAnalyticsPreference] '
        '$e\n$stackTrace',
      );
      setError(trans('errors.unexpected'));
    } finally {
      _isSubmitting = false;
    }
  }

  /// Hands the account's choice to the host's
  /// `MagicStarterManager.applyAnalyticsOptOut` hook when one is set, and to
  /// `magic_analytics` otherwise (only when its provider is registered).
  ///
  /// The one place the starter changes the opt-out, so a host that combines
  /// the account's choice with its own consent sees every change.
  static Future<void> applyOptOut(bool accountOptedOut) async {
    final Future<void> Function(bool)? hook =
        MagicStarter.manager.applyAnalyticsOptOut;

    if (hook != null) {
      await hook(accountOptedOut);
      return;
    }

    if (Magic.bound('analytics')) {
      await Analytics.setOptOut(accountOptedOut);
    }
  }

  /// Applies the account's choice on this device through [applyOptOut], and
  /// keeps the [deviceCacheKey] copy either way.
  ///
  /// Shared with `MagicStarterServiceProvider`, which applies the account's
  /// answer after a sign-in or a restore. It never calls the host hook:
  /// applying a choice nobody just changed is not a change.
  static Future<void> applyOnDevice(bool optedOut) async {
    await applyOptOut(optedOut);

    if (optedOut) {
      await Vault.put(deviceCacheKey, '1');
      return;
    }

    await Vault.delete(deviceCacheKey);
  }

  /// Calls the host's `onAnalyticsPreferenceChanged` hook.
  ///
  /// Logged rather than rethrown: the account already holds the new choice and
  /// this device already applies it, so a broken host hook is not a failed
  /// save.
  Future<void> _notifyHost(bool optedOut) async {
    final Future<void> Function(bool optedOut)? hook =
        MagicStarter.manager.onAnalyticsPreferenceChanged;
    if (hook == null) return;

    try {
      await hook(optedOut);
    } catch (error, stackTrace) {
      Log.error(
        '[MagicStarter] onAnalyticsPreferenceChanged hook failed: '
        '$error\n$stackTrace',
      );
    }
  }
}
