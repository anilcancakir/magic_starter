import 'dart:io';

import 'package:dowel/dowel.dart';
import 'package:magic_starter/src/cli/commands/magic_starter_publish_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _HostPublishCommand extends MagicStarterPublishCommand {
  _HostPublishCommand(this._projectRoot, this._pluginSourceDir);

  final String _projectRoot;
  final String _pluginSourceDir;

  @override
  String getProjectRoot() => _projectRoot;

  @override
  String? getPluginSourceDir() => _pluginSourceDir;
}

/// The provider a `starter:install` host carries, reduced to the import that
/// matters here: it imports the package barrel, which exports every original
/// view and layout under the same class name the published copy declares.
const _hostProvider = '''
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  @override
  void register() {}

  @override
  Future<void> boot() async {
    // existing boot code
  }
}
''';

/// Where each `--tag=views:<key>` and `--tag=layouts:<key>` file lands.
const _registryKeyedFiles = [
  'lib/resources/views/starter/auth/magic_starter_login_view.dart',
  'lib/resources/views/starter/auth/magic_starter_register_view.dart',
  'lib/resources/views/starter/auth/magic_starter_forgot_password_view.dart',
  'lib/resources/views/starter/auth/magic_starter_reset_password_view.dart',
  'lib/resources/views/starter/auth/magic_starter_verify_email_view.dart',
  'lib/resources/views/starter/auth/magic_starter_two_factor_challenge_view.dart',
  'lib/resources/views/starter/auth/magic_starter_otp_verify_view.dart',
  'lib/resources/views/starter/profile/magic_starter_profile_settings_view.dart',
  'lib/resources/views/starter/teams/magic_starter_team_create_view.dart',
  'lib/resources/views/starter/teams/magic_starter_team_settings_view.dart',
  'lib/resources/views/starter/teams/magic_starter_team_invitation_accept_view.dart',
  'lib/resources/layouts/starter/magic_starter_app_layout.dart',
  'lib/resources/layouts/starter/magic_starter_guest_layout.dart',
];

/// Publishes the package's real views and layouts into a throwaway host app
/// that depends on `magic_starter` by path, then runs the analyzer over the
/// host. A published file that does not compile fails this test with the
/// analyzer's own diagnostics.
void main() {
  late Directory hostDir;
  final pluginDir = Directory.current.path;

  setUp(() {
    // The analyzer reports resolved paths (`/private/var` on macOS), so the
    // host root is resolved too for the relative paths in the failure list.
    hostDir = Directory(
      Directory.systemTemp
          .createTempSync('publish_host_')
          .resolveSymbolicLinksSync(),
    );
    File(p.join(hostDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: publish_host
publish_to: none
environment:
  sdk: ">=3.13.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
  magic: any
  magic_starter:
    path: ${pluginDir.replaceAll(r'\', '/')}
''');
    File(p.join(hostDir.path, 'lib/app/providers/app_service_provider.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(_hostProvider);
  });

  tearDown(() {
    if (hostDir.existsSync()) {
      hostDir.deleteSync(recursive: true);
    }
  });

  test(
    'every published view and layout analyzes clean in a host app',
    () async {
      // 1. Publish views and layouts the way an adopter does.
      final command = _HostPublishCommand(hostDir.path, pluginDir);
      for (final tag in ['views', 'layouts']) {
        final code = await command.handle(
          DowelContext.bare(
            MapInput(<String, dynamic>{'tag': tag, 'force': true}),
            BufferedOutput(),
          ),
        );
        expect(code, 0, reason: 'starter:publish --tag=$tag failed');
      }

      // 2. Collect relative imports: they were written for the package's own
      //    tree, and a single-key publish has no sibling to point at.
      final published = Directory(p.join(hostDir.path, 'lib', 'resources'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(published, isNotEmpty);
      final relativeImport = RegExp(
        r'''^(?:import|export)\s+['"](?!package:|dart:)''',
        multiLine: true,
      );
      final relative = [
        for (final file in published)
          if (relativeImport.hasMatch(file.readAsStringSync()))
            p.relative(file.path, from: hostDir.path),
      ];

      // The files `--tag=views:<key>` and `--tag=layouts:<key>` publish reach
      // the package through its barrel only, so a host on `flutter_lints`
      // gets no `implementation_imports` finding from them.
      final reachesIntoSrc = [
        for (final path in _registryKeyedFiles)
          if (File(p.join(hostDir.path, path))
              .readAsStringSync()
              .contains('package:magic_starter/src/'))
            path,
      ];

      // 3. Resolve the host and analyze it.
      final get = await Process.run('flutter', [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: hostDir.path);
      expect(get.exitCode, 0, reason: '${get.stdout}\n${get.stderr}');

      final analyze = await Process.run('dart', [
        'analyze',
        '--format=machine',
        'lib',
      ], workingDirectory: hostDir.path);
      final problems = (analyze.stdout as String)
          .split('\n')
          .where(
            (line) => line.startsWith('ERROR|') || line.startsWith('WARNING|'),
          )
          .map((line) {
            final fields = line.split('|');
            final path = p.relative(fields[3], from: hostDir.path);

            return '$path:${fields[4]} ${fields[2]} ${fields[7]}';
          })
          .toList();
      expect(problems, isEmpty, reason: problems.join('\n'));
      expect(relative, isEmpty, reason: 'relative imports survived publish');
      expect(reachesIntoSrc, isEmpty, reason: 'imports into lib/src');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
