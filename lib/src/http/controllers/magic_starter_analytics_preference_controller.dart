import 'dart:async';

import 'package:magic/magic.dart';

import '../../facades/magic_starter.dart';
import '../../support/control_name.dart';

/// Controller for the account-level "Share usage data" choice on the Email &
/// privacy page.
///
/// The choice lives on the account (`GET` and `PUT /user/analytics`, answered
/// as `{"opted_out": bool}`), so turning it off on one device turns it off on
/// every device the account signs in on. A save is applied on this device only
/// after the backend accepted it: the vault copy a cold start reads
/// ([deviceCacheKey]), the host's `MagicStarterManager.applyAnalyticsOptOut`
/// hook, then the host's `MagicStarterManager.onAnalyticsPreferenceChanged`
/// hook. The starter never imports an analytics package: the host connects its
/// own through the second.
///
/// Every change to the device's opt-out (a save, the answer after a sign-in,
/// the cached choice on boot, the lift on sign-out) takes its turn in one
/// queue, and a turn includes the host hook. A hook may await, so without the
/// queue two hook calls made in order could finish in reverse order and leave
/// the device collecting for an account that opted out.
class MagicStarterAnalyticsPreferenceController extends MagicController
    with MagicStateMixin, ValidatesRequests
    implements SessionScoped {
  /// Singleton accessor; use this instead of constructing directly.
  static MagicStarterAnalyticsPreferenceController get instance =>
      Magic.findOrPut(MagicStarterAnalyticsPreferenceController.new);

  /// The vault key holding this device's copy of the account's choice: `'1'`
  /// while the account has opted out, absent otherwise.
  ///
  /// An analytics package usually keeps its opt-out in memory (`magic_analytics`
  /// does), so without this copy every cold start would collect until the
  /// account's answer arrived.
  static const String deviceCacheKey = 'magic_starter.analytics_opted_out';

  bool _isSubmitting = false;

  /// Bumped by every accepted save, so a sign-in read that started before it
  /// and answers after it is dropped instead of overwriting the newer choice.
  /// A refused save leaves it alone: the read is then still the newest.
  static int _saves = 0;

  /// The number of saves the backend has accepted so far; see
  /// `MagicStarterServiceProvider`.
  static int get saveGeneration => _saves;

  /// The end of the device apply queue: null while it is idle.
  ///
  /// Null rather than a completed future so that no future is created until a
  /// caller needs one, in that caller's zone. A future made at class load in
  /// one test zone would never drain inside a widget test's fake-async zone.
  static Future<void>? _tail;

  bool? _optedOut;

  /// The account [_optedOut] was answered for.
  Object? _answeredFor;

  /// The account's choice as the backend last answered it, `true` when the
  /// account has opted out; null until a read or a save has answered.
  bool? get optedOut => _optedOut;

  /// Drops the previous account's answer, so the switch never shows it for
  /// the next one. A team switch by the same user keeps it: the choice
  /// belongs to the user, and an open page keeps a usable switch. No read
  /// here: `SessionScope` runs this on every sign-in and team switch, and the
  /// Email & privacy page reads on mount.
  @override
  Future<void> resetForSession() async {
    if (_optedOut != null && Auth.id() == _answeredFor) {
      refreshUI();
      return;
    }

    _optedOut = null;
    _answeredFor = null;
    setEmpty();
  }

  /// Reads the account's choice.
  Future<void> getAnalyticsPreference() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    setLoading();

    // The account asking: an answer landing after another sign-in is not its.
    final Object? account = Auth.id();

    try {
      final MagicResponse response = await Http.get('/user/analytics');

      if (Auth.id() != account) {
        setEmpty();
        return;
      }

      if (!response.successful) {
        handleApiError(
          response,
          fallback: magicStarterControlName(
            'magic_starter.analytics.fetch_error',
            'Failed to load your usage data preference.',
          ),
        );
        return;
      }

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      _optedOut = data['opted_out'] as bool;
      _answeredFor = account;
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

    // The account the choice belongs to: an answer landing after a sign-out
    // or another sign-in must not be applied to whoever holds the device now.
    final Object? account = Auth.id();

    try {
      final MagicResponse response = await Http.put(
        '/user/analytics',
        data: {'opted_out': optedOut},
      );

      if (!response.successful) {
        setError(
          magicStarterControlName(
            'magic_starter.analytics.update_error',
            'Failed to update your usage data preference.',
          ),
        );
        return;
      }

      if (Auth.id() != account) return;

      // 1. The account holds the choice now, so the save counts whatever the
      //    device does next, and a sign-in read still in flight is older.
      _saves++;
      _optedOut = optedOut;
      _answeredFor = account;
      setSuccess(response.data as Map<String, dynamic>);

      // 2. Apply on this device only now, so a refused save leaves the device
      //    collecting exactly as the account still says. A failure here is
      //    logged; the next sign-in applies the account's choice again.
      //    The queue may hold it behind an earlier apply; an account that
      //    changed meanwhile does not inherit it.
      try {
        await applyOnDevice(optedOut, isCurrent: () => Auth.id() == account);
      } catch (e, stackTrace) {
        Log.error(
          '[MagicStarterAnalyticsPreferenceController] the saved choice could '
          'not be applied on this device: $e\n$stackTrace',
        );
      }

      // 3. Last, so the host re-applies identity on a device already opted
      //    in, and only for the account that saved.
      if (Auth.id() != account) return;
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

  /// The host's `MagicStarterManager.applyAnalyticsOptOut` hook.
  ///
  /// Throws a [StateError] naming the one line that wires it when the host set
  /// none. `MagicStarterServiceProvider.boot()` calls this while the feature is
  /// on, so a host finds out on its first run rather than by collecting data
  /// for an account that opted out.
  static Future<void> Function(bool accountOptedOut) requireApplyHook() {
    final Future<void> Function(bool)? hook =
        MagicStarter.manager.applyAnalyticsOptOut;

    if (hook == null) {
      throw StateError(
        '"magic_starter.features.analytics" is enabled but '
        'MagicStarterManager.applyAnalyticsOptOut is not set, so the account\'s '
        '"Share usage data" choice would apply to nothing. Install '
        'magic_analytics (`flutter pub add magic_analytics`, then `dart run '
        'magic:dowel plugin:install magic_analytics`) or any analytics '
        'package, and pass '
        '`applyAnalyticsOptOut: (optedOut) => Analytics.setOptOut(optedOut)` '
        'to MagicStarter.bootstrap(), from a provider that boots before '
        'MagicStarterServiceProvider (your AppServiceProvider), or disable '
        'the feature in lib/config/magic_starter.dart.',
      );
    }

    return hook;
  }

  /// Hands the account's choice to the host's
  /// `MagicStarterManager.applyAnalyticsOptOut` hook.
  ///
  /// The one place the starter changes the opt-out, so a host that combines
  /// the account's choice with its own consent sees every change. Throws a
  /// [StateError] through [requireApplyHook] when no hook is set.
  static Future<void> applyOptOut(bool accountOptedOut) async {
    await requireApplyHook()(accountOptedOut);
  }

  /// Applies the account's choice on this device through [applyOptOut], and
  /// keeps the [deviceCacheKey] copy either way.
  ///
  /// Shared with `MagicStarterServiceProvider`, which applies the account's
  /// answer after a sign-in or a restore. It never calls
  /// `onAnalyticsPreferenceChanged`: applying a choice nobody just changed is
  /// not a change.
  ///
  /// Waits for every earlier device apply, then asks [isCurrent] (when given)
  /// before touching anything: an apply that answered for a session or a save
  /// that has since moved on returns without changing the device. A host hook
  /// must not call this method or `updateAnalyticsPreference`: the hook runs
  /// inside a turn of the queue and would wait on itself.
  static Future<void> applyOnDevice(
    bool optedOut, {
    bool Function()? isCurrent,
  }) {
    return _serially(() async {
      // 1. The answer may have gone stale while this apply waited its turn.
      if (isCurrent != null && !isCurrent()) return;

      // 2. The copy first: it records the account's choice, so a host hook
      //    that throws below must not leave the next cold start on the old
      //    one. A vault that cannot be written is logged: the opt-out below
      //    still applies for this run, and the next sign-in writes the copy
      //    again.
      try {
        if (optedOut) {
          await Vault.put(deviceCacheKey, '1');
        } else {
          await Vault.delete(deviceCacheKey);
        }
      } catch (e, stackTrace) {
        Log.error(
          '[MagicStarterAnalyticsPreferenceController] the device copy could '
          'not be written: $e\n$stackTrace',
        );
      }

      // 3. The opt-out itself, through the host's hook.
      await applyOptOut(optedOut);
    });
  }

  /// Applies the opt-out cached on this device, when there is one, in its turn
  /// of the queue.
  static Future<void> applyCachedOnDevice() {
    return _serially(() async {
      final String? cached = await Vault.get(deviceCacheKey);
      if (cached != '1') return;

      await applyOptOut(true);
    });
  }

  /// Deletes this device's copy of the account's choice and, when it held an
  /// opt-out, lifts it, in its turn of the queue.
  static Future<void> forgetOnDevice() {
    return _serially(() async {
      final bool wasOptedOut = await Vault.get(deviceCacheKey) == '1';

      await Vault.delete(deviceCacheKey);
      if (wasOptedOut) {
        await applyOptOut(false);
      }
    });
  }

  /// Runs [body] once every earlier call has finished, whether it succeeded or
  /// threw: a failure reaches its own caller and the next turn still runs.
  ///
  /// A [body] that never finishes stalls every later turn, as a Vault call
  /// that never answers does. There is no timeout: a hook that is still
  /// working is not a hook that failed.
  static Future<T> _serially<T>(Future<T> Function() body) async {
    final Future<void>? previous = _tail;
    final Completer<void> turn = Completer<void>();
    final Future<void> end = turn.future;
    _tail = end;

    try {
      if (previous != null) await previous;

      return await body();
    } finally {
      turn.complete();
      if (identical(_tail, end)) _tail = null;
    }
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
