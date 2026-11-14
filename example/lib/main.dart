import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// The `api/v1` base URL of a `magic-starter-laravel` backend.
///
/// Only the login screen's submit reaches it. Pass your own with
/// `flutter run -d chrome --dart-define=API_URL=https://api.example.com/api/v1`.
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// The view keys the status page asks the registry about.
const List<String> probedViewKeys = [
  'auth.login',
  'auth.forgot_password',
  'settings.hub',
  'auth.two_factor_challenge',
  'teams.create',
  'teams.billing',
];

/// Everything `Magic.init` needs, in one map, so the example runs without a
/// `.env` file or a generated `lib/config/` directory.
Map<String, dynamic> get exampleConfig => {
  'app': {
    'name': 'magic_starter example',
    'providers': [
      (app) => NetworkServiceProvider(app),
      (app) => VaultServiceProvider(app),
      (app) => AuthServiceProvider(app),
      (app) => LocalizationServiceProvider(app),
      (app) => ExampleServiceProvider(app),
      (app) => MagicStarterServiceProvider(app),
    ],
  },
  'network': {
    'default': 'api',
    'drivers': {
      'api': {
        'base_url': apiUrl,
        'timeout': 10000,
        'headers': {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      },
    },
  },
  'auth': {
    'defaults': {'guard': 'api'},
    'guards': {
      'api': {'driver': 'bearer'},
    },
    'endpoints': {'user': '/auth/user'},
    'auto_refresh': false,
  },
  'magic_starter': {
    // Every toggle defaults to false; these three are written out only so the
    // status page has something to read. Turning one on registers its routes
    // and view keys, and its screens then need the backend.
    'features': {'teams': false, 'two_factor': false, 'billing': false},
    'auth': {'email': true, 'phone': false},
  },
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Magic.init(configs: [exampleConfig]);

  runApp(
    MagicApplication(
      title: 'magic_starter example',
      windTheme: WindThemeData(aliases: MagicStarterTokens.defaultAliases),
    ),
  );
}

/// The host side of the wiring: the middleware aliases the starter's routes
/// name, the identity contract, one slot, and the routes.
class ExampleServiceProvider extends ServiceProvider {
  ExampleServiceProvider(super.app);

  @override
  void register() {
    // LocalizationServiceProvider loads `en` in its boot through whichever
    // loader is set by then.
    Translator.instance.setLoader(const StarterCatalogueLoader());

    // The starter's route groups ask for `auth` and `guest` by alias.
    Kernel.registerAll({
      'auth': () => EnsureAuthenticated(),
      'guest': () => RedirectIfAuthenticated(),
    });
  }

  @override
  Future<void> boot() async {
    // A real app passes its own `User.fromMap`; this example has no model.
    MagicStarter.bootstrap(
      userFactory: MagicStarterAuthUser.fromMap,
      onLogout: () async {
        await Auth.logout();
        MagicRoute.to(MagicStarterConfig.loginRoute());
      },
      locales: {'en': 'English'},
    );

    // A slot adds a widget to a shipped view without replacing it.
    MagicStarter.view.slot('auth.login', 'header', (context) {
      return const _Note(
        'This line is a slot the example registered on auth.login.',
      );
    });

    MagicRoute.page('/', () => const StatusPage()).title('Status');
    registerMagicStarterAuthRoutes();
  }
}

/// Reads the English catalogue the package bundles for `starter:install`.
///
/// A real app gets those keys merged into its own `assets/lang/en.json` by
/// `starter:install` and keeps magic's default `JsonAssetLoader`; the example
/// reads the bundled file so it carries no copy. Without a catalogue every
/// starter screen renders its translation keys as text.
class StarterCatalogueLoader implements TranslationLoader {
  const StarterCatalogueLoader();

  static const String path =
      'packages/magic_starter/assets/stubs/install/en.stub';

  @override
  Future<Map<String, dynamic>> load(Locale locale) async {
    final String source = await rootBundle.loadString(path);

    return JsonAssetLoader.flatten(jsonDecode(source) as Map<String, dynamic>);
  }
}

/// What the starter answers with no backend: the config it read, the view
/// keys it registered, and a link to the shipped login screen.
class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'w-full h-full bg-surface overflow-y-auto',
      child: WDiv(
        className: 'flex flex-col gap-6 p-6 max-w-2xl',
        children: [
          WText(
            'magic_starter example',
            className: 'text-2xl font-bold text-fg',
          ),
          MSCard(
            title: 'Config',
            child: WDiv(
              className: 'flex flex-col gap-2',
              children: [
                _Row(
                  'features.teams',
                  '${MagicStarterConfig.hasTeamFeatures()}',
                ),
                _Row(
                  'features.two_factor',
                  '${MagicStarterConfig.hasTwoFactorFeatures()}',
                ),
                _Row(
                  'features.billing',
                  '${MagicStarterConfig.hasBillingFeatures()}',
                ),
                _Row('routes.login', MagicStarterConfig.loginRoute()),
                _Row('MagicStarter.isReady', '${MagicStarter.isReady}'),
              ],
            ),
          ),
          MSCard(
            title: 'View registry',
            child: WDiv(
              className: 'flex flex-col gap-2',
              children: [
                for (final key in probedViewKeys)
                  _Row(key, MagicStarter.view.has(key) ? 'registered' : 'off'),
              ],
            ),
          ),
          MSCard(
            title: 'Login screen',
            child: WDiv(
              className: 'flex flex-col gap-4',
              children: [
                const _Note(
                  'Opens auth.login through the guest route group. The form '
                  'renders offline; submitting it posts to $apiUrl/auth/login, '
                  'and without a backend there it shows the error.',
                ),
                MSButton(
                  onPressed: () =>
                      MagicRoute.to(MagicStarterConfig.loginRoute()),
                  child: WText('Open the login screen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-row justify-between gap-4',
      children: [
        WText(label, className: 'text-sm text-fg-muted'),
        WText(value, className: 'text-sm font-medium text-fg'),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return WText(text, className: 'text-sm text-fg-muted');
  }
}
