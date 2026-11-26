import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/src/support/support_client_context.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MagicApp.reset();
    Magic.flush();
    PackageInfo.setMockInitialValues(
      appName: 'Example',
      packageName: 'com.example.app',
      version: '1.4.0',
      buildNumber: '27',
      buildSignature: '',
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    MagicPlatform.debugTvOSOverride = null;
  });

  group('platform', () {
    test('is the target platform name on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final Map<String, String> context =
          await MagicStarterSupportClientContext.collect();

      expect(context['platform'], 'iOS');
    });

    test('is tvOS on an Apple TV, which reports as iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      MagicPlatform.debugTvOSOverride = true;

      final Map<String, String> context =
          await MagicStarterSupportClientContext.collect();

      expect(context['platform'], 'tvOS');
    });
  });
}
