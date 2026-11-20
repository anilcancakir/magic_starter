import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_analytics/magic_analytics.dart';
import 'package:magic_starter/magic_starter.dart';

const String _cacheKey = 'magic_starter.analytics_opted_out';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MagicStarterAnalyticsPreferenceController controller;
  late List<bool> hookCalls;

  /// Answers every `/user/analytics` request with [statusCode] and echoes the
  /// value a PUT sent, the shape magic-starter-laravel answers with.
  FakeNetworkDriver fakeBackend({int statusCode = 200, bool optedOut = false}) {
    return Http.fake((MagicRequest request) {
      if (statusCode != 200) {
        return Http.response({'message': 'Server Error'}, statusCode);
      }

      final bool answer = request.method == 'PUT'
          ? (request.data as Map<String, dynamic>)['opted_out'] as bool
          : optedOut;

      return Http.response({'opted_out': answer});
    });
  }

  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Log.fake();
    Vault.fake();
    Analytics.fake();
    Auth.fake();
    setUpMagicStarterForTests();

    hookCalls = <bool>[];
    MagicStarter.manager.onAnalyticsPreferenceChanged = (bool optedOut) async {
      hookCalls.add(optedOut);
    };

    controller = MagicStarterAnalyticsPreferenceController.instance;
  });

  tearDown(() {
    Auth.unfake();
    Http.unfake();
    Vault.unfake();
    Analytics.unfake();
    Log.unfake();
  });

  group('getAnalyticsPreference', () {
    test('reads GET /user/analytics and holds the answer', () async {
      final fake = fakeBackend(optedOut: true);

      await controller.getAnalyticsPreference();

      fake.assertSent(
        (MagicRequest request) =>
            request.method == 'GET' && request.url == '/user/analytics',
      );
      expect(controller.isSuccess, isTrue);
      expect(controller.optedOut, isTrue);
    });

    test('a read applies nothing on the device', () async {
      fakeBackend(optedOut: true);

      await controller.getAnalyticsPreference();

      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
      expect(hookCalls, isEmpty);
    });

    test('a read answered after the account changed keeps nothing', () async {
      Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 1, 'name': 'A'}));
      Http.fake((MagicRequest request) {
        // Another account signs in while the read is in flight.
        Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 2, 'name': 'B'}));

        return Http.response({'opted_out': true});
      });

      await controller.getAnalyticsPreference();

      expect(controller.optedOut, isNull);
    });

    test('a failed read sets the fetch error', () async {
      fakeBackend(statusCode: 500);

      await controller.getAnalyticsPreference();

      expect(controller.isError, isTrue);
      expect(controller.optedOut, isNull);
    });
  });

  group('updateAnalyticsPreference', () {
    test('PUTs the choice to /user/analytics', () async {
      final fake = fakeBackend();

      await controller.updateAnalyticsPreference(optedOut: true);

      fake.assertSent(
        (MagicRequest request) =>
            request.method == 'PUT' &&
            request.url == '/user/analytics' &&
            (request.data as Map<String, dynamic>)['opted_out'] == true,
      );
      expect(controller.isSuccess, isTrue);
      expect(controller.optedOut, isTrue);
    });

    test('an opt-out stops analytics and caches it on the device', () async {
      fakeBackend();

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(Analytics.isOptedOut, isTrue);
      expect(await Vault.get(_cacheKey), '1');
    });

    test('opting back in resumes analytics and drops the cache', () async {
      fakeBackend();
      await controller.updateAnalyticsPreference(optedOut: true);

      await controller.updateAnalyticsPreference(optedOut: false);

      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
    });

    test('calls onAnalyticsPreferenceChanged with the new value', () async {
      fakeBackend();

      await controller.updateAnalyticsPreference(optedOut: true);
      await controller.updateAnalyticsPreference(optedOut: false);

      expect(hookCalls, [true, false]);
    });

    test('a failed save applies nothing and sets the update error', () async {
      fakeBackend(statusCode: 500);

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(controller.isError, isTrue);
      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
      expect(hookCalls, isEmpty);
    });

    test('a refused value applies nothing', () async {
      Http.fake({
        'user/analytics': Http.response({
          'message': 'The opted out field must be true or false.',
          'errors': {
            'opted_out': ['The opted out field must be true or false.'],
          },
        }, 422),
      });

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
      expect(hookCalls, isEmpty);
    });

    test('a throwing hook is logged and the save still lands', () async {
      fakeBackend();
      MagicStarter.manager.onAnalyticsPreferenceChanged = (bool _) async {
        throw StateError('boom');
      };

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(controller.isSuccess, isTrue);
      expect(Analytics.isOptedOut, isTrue);
    });

    test('a save answered after the account changed applies nothing', () async {
      Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 1, 'name': 'A'}));
      Http.fake((MagicRequest request) {
        // Another account signs in while the PUT is in flight.
        Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 2, 'name': 'B'}));

        return Http.response({'opted_out': true});
      });

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), isNull);
      expect(hookCalls, isEmpty);
    });

    test('an accepted save counts even when applying it throws', () async {
      fakeBackend();
      MagicStarter.manager.applyAnalyticsOptOut = (bool _) async {
        throw StateError('device apply failed');
      };
      addTearDown(() => MagicStarter.manager.applyAnalyticsOptOut = null);

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(controller.isSuccess, isTrue);
      expect(controller.optedOut, isTrue);
    });

    test(
      'a session change during the device apply skips the host hook',
      () async {
        Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 1, 'name': 'A'}));
        fakeBackend();
        MagicStarter.manager.applyAnalyticsOptOut = (bool _) async {
          Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 2, 'name': 'B'}));
        };
        addTearDown(() => MagicStarter.manager.applyAnalyticsOptOut = null);

        await controller.updateAnalyticsPreference(optedOut: true);

        expect(hookCalls, isEmpty);
      },
    );

    test('a vault that fails to write still applies the opt-out', () async {
      Vault.fake().throwOnPut(StateError('keychain locked'));
      fakeBackend();

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(Analytics.isOptedOut, isTrue);
      expect(controller.isSuccess, isTrue);
    });

    test('a throwing device apply still caches the accepted choice', () async {
      fakeBackend();
      MagicStarter.manager.applyAnalyticsOptOut = (bool _) async {
        throw StateError('device apply failed');
      };
      addTearDown(() => MagicStarter.manager.applyAnalyticsOptOut = null);

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(await Vault.get(_cacheKey), '1');
    });

    test('a host applyAnalyticsOptOut hook replaces the facade call', () async {
      final List<bool> applied = <bool>[];
      MagicStarter.manager.applyAnalyticsOptOut = (bool optedOut) async {
        applied.add(optedOut);
      };
      addTearDown(() => MagicStarter.manager.applyAnalyticsOptOut = null);
      fakeBackend();

      await controller.updateAnalyticsPreference(optedOut: true);

      expect(applied, <bool>[true]);
      expect(Analytics.isOptedOut, isFalse);
      expect(await Vault.get(_cacheKey), '1');
      expect(hookCalls, <bool>[true]);
    });

    test(
      'without the analytics provider the save lands and nothing throws',
      () async {
        Analytics.unfake();
        fakeBackend();

        await controller.updateAnalyticsPreference(optedOut: true);

        expect(Magic.bound('analytics'), isFalse);
        expect(controller.isSuccess, isTrue);
        expect(await Vault.get(_cacheKey), '1');
        expect(hookCalls, [true]);
      },
    );
  });

  test('another account forgets the previous account answer', () async {
    Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 1, 'name': 'A'}));
    final fake = fakeBackend(optedOut: true);
    await controller.getAnalyticsPreference();
    expect(controller.optedOut, isTrue);

    Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 2, 'name': 'B'}));
    await controller.resetForSession();

    expect(controller, isA<SessionScoped>());
    expect(controller.optedOut, isNull);
    // The page reads on mount; a sign-in sends nothing here.
    expect(fake.recorded, hasLength(1));
  });

  test('a team switch keeps the same account answer', () async {
    // The choice belongs to the user, not the team, so an open page keeps a
    // usable switch across a team switch.
    Auth.fake(user: MagicStarterAuthUser.fromMap({'id': 1, 'name': 'A'}));
    final fake = fakeBackend(optedOut: true);
    await controller.getAnalyticsPreference();

    await controller.resetForSession();

    expect(controller.optedOut, isTrue);
    expect(controller.isSuccess, isTrue);
    expect(fake.recorded, hasLength(1));
  });

  test('reset() clears both analytics hooks', () {
    MagicStarter.manager.applyAnalyticsOptOut = (bool _) async {};
    MagicStarter.manager.reset();

    expect(MagicStarter.manager.onAnalyticsPreferenceChanged, isNull);
    expect(MagicStarter.manager.applyAnalyticsOptOut, isNull);
  });
}
