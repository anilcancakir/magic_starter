import 'dart:async';

import 'package:flutter_test/flutter_test.dart' hide EventDispatcher;
import 'package:magic/magic.dart';
import 'package:magic_analytics/magic_analytics.dart';
import 'package:magic_starter/magic_starter.dart';

const String _cacheKey = 'magic_starter.analytics_opted_out';

MagicStarterAuthUser _user() {
  return MagicStarterAuthUser.fromMap({'id': 42, 'name': 'Alice'});
}

void main() {
  // The provider's boot reads `WidgetsBinding.instance` for its primary colour
  // fallback, and every test here boots it for real.
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<bool> hookCalls;

  /// Boots the starter provider, which is what applies the account choice.
  Future<void> bootProvider() async {
    final provider = MagicStarterServiceProvider(MagicApp.instance);
    provider.register();
    await provider.boot();
  }

  /// Answers `GET /user/analytics` with [optedOut], or with [statusCode].
  FakeNetworkDriver fakeBackend({bool optedOut = false, int statusCode = 200}) {
    return Http.fake({
      'user/analytics': statusCode == 200
          ? Http.response({'opted_out': optedOut})
          : Http.response({'message': 'Server Error'}, statusCode),
    });
  }

  setUp(() {
    MagicApp.reset();
    Magic.flush();
    MagicRouter.reset();
    EventDispatcher.instance.clear();
    Log.fake();
    Auth.fake();
    Vault.fake();
    Analytics.fake();
    Config.set('magic_starter.features.notifications', false);
    Config.set('magic_starter.features.analytics', true);

    hookCalls = <bool>[];
  });

  tearDown(() {
    EventDispatcher.instance.clear();
    Auth.unfake();
    Http.unfake();
    Vault.unfake();
    Analytics.unfake();
    Log.unfake();
  });

  /// Registers the hook after boot, as a host's own provider would.
  void listenToHook() {
    MagicStarter.manager.onAnalyticsPreferenceChanged = (bool optedOut) async {
      hookCalls.add(optedOut);
    };
  }

  group('on boot', () {
    test('applies a cached opt-out before the first screen', () async {
      Vault.fake({_cacheKey: '1'});

      await bootProvider();

      expect(Analytics.isOptedOut, isTrue);
    });

    test('leaves analytics on without a cached opt-out', () async {
      await bootProvider();

      expect(Analytics.isOptedOut, isFalse);
    });

    test('a vault that fails to read does not fail the boot', () async {
      Vault.fake().throwOnGet(StateError('keychain locked'));

      await expectLater(bootProvider(), completes);
      expect(Analytics.isOptedOut, isFalse);
    });
  });

  group('when a session starts or is restored', () {
    for (final MapEntry<String, MagicEvent Function()> event
        in <String, MagicEvent Function()>{
          'AuthLogin': () => AuthLogin(_user()),
          'AuthRestored': () => AuthRestored(_user()),
        }.entries) {
      test('${event.key} applies the account opt-out and caches it', () async {
        await bootProvider();
        listenToHook();
        await Auth.login({'token': 'account-token'}, _user());
        final fake = fakeBackend(optedOut: true);

        await Event.dispatch(event.value());
        await pumpEventQueue();

        fake.assertSent(
          (MagicRequest request) =>
              request.method == 'GET' && request.url == '/user/analytics',
        );
        expect(Analytics.isOptedOut, isTrue);
        expect(await Vault.get(_cacheKey), '1');
        expect(hookCalls, isEmpty);
      });
    }

    test('an account that shares lifts a cached opt-out', () async {
      Vault.fake({_cacheKey: '1'});
      await bootProvider();
      await Auth.login({'token': 'account-token'}, _user());
      fakeBackend();

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();

      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
    });

    test('a failed read changes nothing', () async {
      Vault.fake({_cacheKey: '1'});
      await bootProvider();
      await Auth.login({'token': 'account-token'}, _user());
      fakeBackend(statusCode: 500);

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();

      expect(Analytics.isOptedOut, isTrue);
      expect(await Vault.get(_cacheKey), '1');
    });

    test('an answer for a session that is gone applies nothing', () async {
      await bootProvider();
      await Auth.login({'token': 'account-token'}, _user());
      Http.fake((MagicRequest request) {
        // Another account signs in while the read is in flight.
        Auth.fake(
          user: MagicStarterAuthUser.fromMap({'id': 43, 'name': 'Bob'}),
        );

        return Http.response({'opted_out': true});
      });

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();

      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
    });
  });

  test('a sign-in read answered after a save applies nothing', () async {
    await bootProvider();
    await Auth.login({'token': 'account-token'}, _user());
    final Completer<void> readGate = Completer<void>();
    Http.fake((MagicRequest request) async {
      if (request.method == 'PUT') {
        return Http.response({'opted_out': true});
      }

      // The read started before the save and answers after it.
      await readGate.future;

      return Http.response({'opted_out': false});
    });

    await Event.dispatch(AuthRestored(_user()));
    await MagicStarterAnalyticsPreferenceController.instance
        .updateAnalyticsPreference(optedOut: true);
    readGate.complete();
    await pumpEventQueue();

    expect(Analytics.isOptedOut, isTrue);
    expect(await Vault.get(_cacheKey), '1');
  });

  test('a failed save leaves a pending sign-in read in force', () async {
    await bootProvider();
    await Auth.login({'token': 'account-token'}, _user());
    final Completer<void> readGate = Completer<void>();
    Http.fake((MagicRequest request) async {
      if (request.method == 'PUT') {
        return Http.response({'message': 'Server Error'}, 500);
      }

      await readGate.future;

      return Http.response({'opted_out': true});
    });

    await Event.dispatch(AuthRestored(_user()));
    await MagicStarterAnalyticsPreferenceController.instance
        .updateAnalyticsPreference(optedOut: false);
    readGate.complete();
    await pumpEventQueue();

    expect(Analytics.isOptedOut, isTrue);
    expect(await Vault.get(_cacheKey), '1');
  });

  group('with a host applyAnalyticsOptOut hook', () {
    late List<bool> applied;

    /// Boots the provider with the hook set between register and boot, where
    /// a host's own provider sets it: `register()` binds a fresh manager.
    Future<void> bootWithHook() async {
      final provider = MagicStarterServiceProvider(MagicApp.instance);
      provider.register();
      MagicStarter.manager.applyAnalyticsOptOut = (bool optedOut) async {
        applied.add(optedOut);
      };
      await provider.boot();
    }

    setUp(() => applied = <bool>[]);

    tearDown(() => MagicStarter.manager.applyAnalyticsOptOut = null);

    test('boot hands a cached opt-out to the hook instead', () async {
      Vault.fake({_cacheKey: '1'});

      await bootWithHook();

      expect(applied, <bool>[true]);
      expect(Analytics.isOptedOut, isFalse);
    });

    test('a sign-in hands the account choice to the hook instead', () async {
      await bootWithHook();
      await Auth.login({'token': 'account-token'}, _user());
      fakeBackend();

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();

      expect(applied, <bool>[false]);
      expect(await Vault.get(_cacheKey), isNull);
    });

    test('a sign-out hands the lifted opt-out to the hook instead', () async {
      Vault.fake({_cacheKey: '1'});
      await bootWithHook();
      await Auth.login({'token': 'account-token'}, _user());
      await Analytics.setOptOut(true);
      applied.clear();

      await Auth.logout();
      await pumpEventQueue();

      expect(applied, <bool>[false]);
      expect(Analytics.isOptedOut, isTrue);
    });
  });

  group('on sign-out', () {
    test('clears the cache and lifts the opt-out', () async {
      Vault.fake({_cacheKey: '1'});
      await bootProvider();
      await Auth.login({'token': 'account-token'}, _user());

      await Auth.logout();
      await pumpEventQueue();

      expect(await Vault.get(_cacheKey), isNull);
      expect(Analytics.isOptedOut, isFalse);
    });

    test('leaves an opt-out it did not set', () async {
      await bootProvider();
      await Auth.login({'token': 'account-token'}, _user());
      await Analytics.setOptOut(true);

      await Auth.logout();
      await pumpEventQueue();

      expect(Analytics.isOptedOut, isTrue);
    });
  });

  group('with the analytics feature off', () {
    setUp(() {
      Config.set('magic_starter.features.analytics', false);
    });

    test('nothing reads /user/analytics', () async {
      Vault.fake({_cacheKey: '1'});
      await bootProvider();
      await Auth.login({'token': 'account-token'}, _user());
      final fake = Http.fake();

      await Event.dispatch(AuthLogin(_user()));
      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();

      fake.assertNotSent(
        (MagicRequest request) => request.url.contains('user/analytics'),
      );
      expect(Analytics.isOptedOut, isFalse);
    });
  });

  group('without the analytics provider', () {
    setUp(Analytics.unfake);

    test('boot, sign-in and sign-out neither throw nor read', () async {
      Vault.fake({_cacheKey: '1'});
      await expectLater(bootProvider(), completes);
      await Auth.login({'token': 'account-token'}, _user());
      final fake = Http.fake();

      await Event.dispatch(AuthLogin(_user()));
      await pumpEventQueue();
      await Auth.logout();
      await pumpEventQueue();

      expect(Magic.bound('analytics'), isFalse);
      fake.assertNotSent(
        (MagicRequest request) => request.url.contains('user/analytics'),
      );
    });
  });
}
