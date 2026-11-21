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

  /// Boots the starter provider, which is what applies the account choice,
  /// with the one line a host writes to connect magic_analytics. The hook is
  /// set between register and boot, where a host's own provider sets it:
  /// `register()` binds a fresh manager.
  Future<void> bootProvider() async {
    final provider = MagicStarterServiceProvider(MagicApp.instance);
    provider.register();
    MagicStarter.manager.applyAnalyticsOptOut = Analytics.setOptOut;
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

  // A host hook may await (it combines the account's choice with its own
  // consent), so two hook calls made in order can finish in reverse order. The
  // device applies therefore run one at a time: the account's newest choice is
  // the last one a hook finishes.
  group('device applies run one at a time', () {
    final List<bool> started = <bool>[];
    final List<bool> finished = <bool>[];
    final List<Completer<void>> gates = <Completer<void>>[];
    var hold = true;

    /// A hook that waits on a gate while [hold] is set.
    Future<void> slowHook(bool optedOut) async {
      started.add(optedOut);

      if (hold) {
        final Completer<void> gate = Completer<void>();
        gates.add(gate);
        await gate.future;
      }

      finished.add(optedOut);
    }

    /// Releases the newest waiting hook first until none waits, so an apply
    /// the starter started earlier finishes last if it was allowed to overlap.
    Future<void> drain() async {
      for (var round = 0; round < 20; round++) {
        await pumpEventQueue();

        final List<Completer<void>> waiting = gates
            .where((Completer<void> gate) => !gate.isCompleted)
            .toList();
        if (waiting.isEmpty) return;

        waiting.last.complete();
      }
    }

    MagicStarterServiceProvider registerWithSlowHook() {
      final provider = MagicStarterServiceProvider(MagicApp.instance);
      provider.register();
      MagicStarter.manager.applyAnalyticsOptOut = slowHook;

      return provider;
    }

    /// Answers the read with false and accepts a save as true.
    void backendThatSaves() {
      Http.fake((MagicRequest request) {
        return Http.response({'opted_out': request.method == 'PUT'});
      });
    }

    setUp(() {
      started.clear();
      finished.clear();
      gates.clear();
      hold = true;
    });

    tearDown(() async {
      hold = false;
      for (final Completer<void> gate in gates) {
        if (!gate.isCompleted) gate.complete();
      }
      await pumpEventQueue();
    });

    test('a slow sign-in apply does not finish after a later save', () async {
      final provider = registerWithSlowHook();
      hold = false;
      await provider.boot();
      hold = true;
      await Auth.login({'token': 'account-token'}, _user());
      backendThatSaves();

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();
      final Future<void> save = MagicStarterAnalyticsPreferenceController
          .instance
          .updateAnalyticsPreference(optedOut: true);
      await drain();
      await save;

      expect(finished.last, isTrue);
      expect(await Vault.get(_cacheKey), '1');
    });

    test('a read that waited behind a slow apply is dropped once a save '
        'lands', () async {
      Vault.fake({_cacheKey: '1'});
      final provider = registerWithSlowHook();
      final Future<void> booting = provider.boot();
      await pumpEventQueue();
      await Auth.login({'token': 'account-token'}, _user());
      backendThatSaves();

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();
      final Future<void> save = MagicStarterAnalyticsPreferenceController
          .instance
          .updateAnalyticsPreference(optedOut: true);
      await drain();
      await booting;
      await save;

      expect(started, isNot(contains(false)));
      expect(finished.last, isTrue);
      expect(await Vault.get(_cacheKey), '1');
    });

    test('a sign-in answer is dropped when the account changed while it '
        'waited', () async {
      Vault.fake({_cacheKey: '1'});
      final provider = registerWithSlowHook();
      final Future<void> booting = provider.boot();
      await pumpEventQueue();
      await Auth.login({'token': 'account-token'}, _user());
      backendThatSaves();

      await Event.dispatch(AuthRestored(_user()));
      await pumpEventQueue();
      Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 43, 'name': 'Bob'}));
      await drain();
      await booting;

      // Only the boot's cached apply reached the hook: the answer read for
      // account 42 was dropped when its turn came.
      expect(started, <bool>[true]);
      expect(await Vault.get(_cacheKey), '1');
    });

    test('a saved choice is dropped when the account changed while it '
        'waited', () async {
      Vault.fake({_cacheKey: '1'});
      final provider = registerWithSlowHook();
      final Future<void> booting = provider.boot();
      await pumpEventQueue();
      await Auth.login({'token': 'account-token'}, _user());
      backendThatSaves();

      final Future<void> save = MagicStarterAnalyticsPreferenceController
          .instance
          .updateAnalyticsPreference(optedOut: true);
      await pumpEventQueue();
      Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 43, 'name': 'Bob'}));
      await drain();
      await booting;
      await save;

      // The save was accepted for account 42, then waited behind the boot's
      // apply; account 43 must not inherit it.
      expect(started, <bool>[true]);
    });

    test('a sign-out lift does not finish after a later apply', () async {
      Vault.fake({_cacheKey: '1'});
      final provider = registerWithSlowHook();
      hold = false;
      await provider.boot();
      hold = true;
      started.clear();
      finished.clear();
      await Auth.login({'token': 'account-token'}, _user());

      final Future<void> signOut = Auth.logout();
      await pumpEventQueue();
      final Future<void> next =
          MagicStarterAnalyticsPreferenceController.applyOnDevice(true);
      await drain();
      await signOut;
      await next;

      expect(finished.last, isTrue);
      expect(await Vault.get(_cacheKey), '1');
    });

    test('a throwing hook does not stall the applies behind it', () async {
      registerWithSlowHook();
      hold = false;
      var calls = 0;
      MagicStarter.manager.applyAnalyticsOptOut = (bool optedOut) async {
        calls++;
        if (calls == 1) throw StateError('host hook failed');
      };

      await expectLater(
        MagicStarterAnalyticsPreferenceController.applyOnDevice(true),
        throwsA(isA<StateError>()),
      );
      await MagicStarterAnalyticsPreferenceController.applyOnDevice(false);

      expect(calls, 2);
      expect(await Vault.get(_cacheKey), isNull);
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

  group('without an applyAnalyticsOptOut hook', () {
    Future<void> bootWithoutHook() async {
      final provider = MagicStarterServiceProvider(MagicApp.instance);
      provider.register();
      await provider.boot();
    }

    test('boot refuses while the analytics feature is on', () async {
      await expectLater(
        bootWithoutHook(),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            allOf(
              contains('applyAnalyticsOptOut'),
              contains('magic_starter.features.analytics'),
            ),
          ),
        ),
      );
    });

    test('boot completes while the analytics feature is off', () async {
      Config.set('magic_starter.features.analytics', false);

      await expectLater(bootWithoutHook(), completes);
    });

    test('boot applies a cached opt-out through the hook alone', () async {
      // Only the hook matters to the starter; the plugin is the host's. With
      // nothing bound under `analytics`, the cached choice still reaches it.
      Analytics.unfake();
      expect(Magic.bound('analytics'), isFalse);
      Vault.fake({_cacheKey: '1'});
      final List<bool> applied = <bool>[];
      final provider = MagicStarterServiceProvider(MagicApp.instance);
      provider.register();
      MagicStarter.manager.applyAnalyticsOptOut = (bool optedOut) async {
        applied.add(optedOut);
      };

      await provider.boot();

      expect(applied, <bool>[true]);
    });

    test(
      'a hook passed to bootstrap() after register lets boot complete',
      () async {
        // The order a host follows: every register() runs first, then the
        // host's own provider calls bootstrap(), then the starter boots.
        final provider = MagicStarterServiceProvider(MagicApp.instance);
        provider.register();

        MagicStarter.bootstrap(
          userFactory: (data) => MagicStarterAuthUser.fromMap(data),
          onLogout: () async {},
          locales: const {'en': 'English'},
          applyAnalyticsOptOut: (bool optedOut) async {},
        );

        await expectLater(provider.boot(), completes);
        expect(MagicStarter.manager.applyAnalyticsOptOut, isNotNull);
      },
    );
  });
}
