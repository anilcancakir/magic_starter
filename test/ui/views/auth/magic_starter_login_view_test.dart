import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// A host catalogue that names the auth controls in its own words, so a test
/// can tell a translated label from the shipped English fallback.
class _ControlCopyLoader implements TranslationLoader {
  const _ControlCopyLoader();

  @override
  Future<Map<String, dynamic>> load(Locale _) async => <String, dynamic>{
    'common.toggle_theme': 'Switch appearance',
    'auth.show_password': 'Reveal password',
    'auth.hide_password': 'Conceal password',
  };
}

void main() {
  Widget wrap(Widget widget) {
    return MaterialApp(
      home: WindTheme(
        data: WindThemeData(),
        child: Scaffold(body: SingleChildScrollView(child: widget)),
      ),
    );
  }

  group('MagicStarterLoginView — identity modes', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
      Magic.singleton('log', () => LogManager());
      Magic.singleton('magic_starter', () => MagicStarterManager());
      Magic.put(MagicStarterAuthController());
    });

    testWidgets('shows email field in email-only mode (default)', (
      tester,
    ) async {
      Config.set('magic_starter.auth.email', true);
      Config.set('magic_starter.auth.phone', false);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));

      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(WFormInput, trans('attributes.email')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(WFormInput, trans('attributes.phone')),
        findsNothing,
      );
    });

    testWidgets('shows phone field in phone-only mode', (tester) async {
      Config.set('magic_starter.auth.email', false);
      Config.set('magic_starter.auth.phone', true);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));

      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(WFormInput, trans('attributes.phone')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(WFormInput, trans('attributes.email')),
        findsNothing,
      );
    });

    testWidgets('shows segmented toggle in both mode', (tester) async {
      Config.set('magic_starter.auth.email', true);
      Config.set('magic_starter.auth.phone', true);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));

      await tester.pumpAndSettle();

      // Segmented control renders labels as WText inside WAnchor.
      expect(find.text(trans('attributes.email')), findsWidgets);
      expect(find.text(trans('attributes.phone')), findsWidgets);
    });

    testWidgets('switching to phone tab shows phone field in both mode', (
      tester,
    ) async {
      Config.set('magic_starter.auth.email', true);
      Config.set('magic_starter.auth.phone', true);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      // Initially shows email field.
      expect(
        find.widgetWithText(WFormInput, trans('attributes.email')),
        findsOneWidget,
      );

      // Tap phone segment (WAnchor wrapping the label text).
      await tester.tap(find.text(trans('attributes.phone')).first);
      await tester.pumpAndSettle();

      // Now shows phone field.
      expect(
        find.widgetWithText(WFormInput, trans('attributes.phone')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(WFormInput, trans('attributes.email')),
        findsNothing,
      );
    });
  });

  group('MagicStarterLoginView — slot injection', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
      Magic.singleton('log', () => LogManager());
      Magic.singleton('magic_starter', () => MagicStarterManager());
      Magic.put(MagicStarterAuthController());
    });

    testWidgets('renders header slot when registered', (tester) async {
      MagicStarter.view.slot(
        'auth.login',
        'header',
        (ctx) => const Text('Custom Header'),
      );

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expect(find.text('Custom Header'), findsOneWidget);
    });

    testWidgets('renders footer slot when registered', (tester) async {
      MagicStarter.view.slot(
        'auth.login',
        'footer',
        (ctx) => const Text('Custom Footer'),
      );

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expect(find.text('Custom Footer'), findsOneWidget);
    });
  });

  group('MagicStarterLoginView — theme consumption', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
      Magic.singleton('log', () => LogManager());
      Magic.singleton('magic_starter', () => MagicStarterManager());
      Magic.put(MagicStarterAuthController());
    });

    testWidgets('renders without crash when custom FormTheme is set', (
      tester,
    ) async {
      MagicStarter.useFormTheme(
        const MagicStarterFormTheme(
          inputClassName: 'custom-input',
          labelClassName: 'custom-label',
          primaryButtonClassName: 'custom-button',
        ),
      );

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expect(find.byType(MagicStarterLoginView), findsOneWidget);
    });
  });

  group('MagicStarterLoginView autofill', () {
    late MagicStarterAuthController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      Magic.singleton('log', () => LogManager());
      Magic.singleton('magic_starter', () => MagicStarterManager());
      controller = MagicStarterAuthController();
      Magic.put(controller);
    });

    tearDown(() => controller.dispose());

    List<List<String>?> hintsOf(WidgetTester tester) {
      return tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((field) => field.autofillHints?.toList())
          .toList();
    }

    testWidgets('hints the email and password fields', (tester) async {
      Config.set('magic_starter.auth.email', true);
      Config.set('magic_starter.auth.phone', false);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expect(hintsOf(tester), [
        [AutofillHints.username, AutofillHints.email],
        [AutofillHints.password],
      ]);
    });

    testWidgets('hints the phone field as a telephone number', (tester) async {
      Config.set('magic_starter.auth.email', false);
      Config.set('magic_starter.auth.phone', true);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expect(hintsOf(tester), [
        [AutofillHints.telephoneNumber],
        [AutofillHints.password],
      ]);
    });

    testWidgets('groups both fields and cancels the context on dispose', (
      tester,
    ) async {
      Config.set('magic_starter.auth.email', true);
      Config.set('magic_starter.auth.phone', false);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      final group = tester.widget<AutofillGroup>(find.byType(AutofillGroup));
      expect(group.onDisposeAction, AutofillContextAction.cancel);
      expect(
        find.descendant(
          of: find.byType(AutofillGroup),
          matching: find.byType(EditableText),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('keeps the fields mounted while the sign-in is in flight', (
      tester,
    ) async {
      // An unmounted group is a cancelled one, so a save after the response
      // would find no context left to commit.
      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      controller.setLoading();
      await tester.pump();

      expect(find.byType(EditableText), findsNWidgets(2));
    });
  });

  group('MagicStarterLoginView: icon-only control names', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
      Magic.singleton('log', () => LogManager());
      Magic.singleton('magic_starter', () => MagicStarterManager());
      Magic.put(MagicStarterAuthController());
    });

    // A semantics node reads as a named button, never as `button ""`.
    void expectNamedButton(WidgetTester tester, String label) {
      final finder = find.bySemanticsLabel(label);

      expect(finder, findsOneWidget, reason: 'no node is named "$label"');
      expect(
        tester.getSemantics(finder).getSemanticsData().flagsCollection.isButton,
        isTrue,
        reason: '"$label" is not announced as a button',
      );
    }

    testWidgets('names the theme toggle and the password eye', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expectNamedButton(tester, 'Toggle theme');
      expectNamedButton(tester, 'Show password');
      for (final key in const [
        'common.toggle_theme',
        'auth.show_password',
        'auth.hide_password',
      ]) {
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(key))),
          findsNothing,
          reason: 'the raw key "$key" reached the tree',
        );
      }

      handle.dispose();
    });

    testWidgets('the password eye label follows its state', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pumpAndSettle();

      expectNamedButton(tester, 'Hide password');
      expect(find.bySemanticsLabel('Show password'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Hide password'));
      await tester.pumpAndSettle();

      expectNamedButton(tester, 'Show password');
      expect(find.bySemanticsLabel('Hide password'), findsNothing);

      handle.dispose();
    });

    testWidgets('reads the names from the catalogue when it has them', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Translator.instance.setLoader(const _ControlCopyLoader());
      await Translator.instance.setLocale(const Locale('en'));
      addTearDown(Translator.reset);

      await tester.pumpWidget(wrap(const MagicStarterLoginView()));
      await tester.pumpAndSettle();

      expectNamedButton(tester, 'Switch appearance');
      expectNamedButton(tester, 'Reveal password');

      await tester.tap(find.bySemanticsLabel('Reveal password'));
      await tester.pumpAndSettle();

      expectNamedButton(tester, 'Conceal password');

      handle.dispose();
    });

    test('the control names ship in the install stub', () {
      final stub = jsonDecode(
        File('assets/stubs/install/en.stub').readAsStringSync(),
      ) as Map<String, dynamic>;
      final auth = stub['auth'] as Map<String, dynamic>;
      final common = stub['common'] as Map<String, dynamic>;

      expect(auth['show_password'], 'Show password');
      expect(auth['hide_password'], 'Hide password');
      expect(common['toggle_theme'], 'Toggle theme');
    });
  });

  _nextQueryTests();
}

/// The `?next=` handling, behind a real router so the page has a query.
void _nextQueryTests() {
  group('MagicStarterLoginView: ?next=', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
      MagicRouter.reset();
      Magic.singleton('log', () => LogManager());
      Magic.singleton('magic_starter', () => MagicStarterManager());
      Magic.put(MagicStarterAuthController());
    });

    tearDown(() {
      MagicRouter.instance.pullIntendedUrl();
      MagicRouter.reset();
    });

    Future<void> mount(WidgetTester tester, String location) async {
      MagicRoute.page('/auth/login', () => const MagicStarterLoginView());
      MagicRouter.instance.setInitialLocation(location);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: MagicRouter.instance.routerConfig,
          builder: (context, child) => WindTheme(
            data: WindThemeData(),
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stores a valid next as where the sign-in lands', (
      tester,
    ) async {
      await mount(tester, '/auth/login?next=%2Fmonitors%2F42%3Ftab%3Dchecks');

      expect(MagicRouter.instance.pullIntendedUrl(), '/monitors/42?tab=checks');
    });

    testWidgets('ignores an unsafe next', (tester) async {
      await mount(tester, '/auth/login?next=%2F%2Fevil.example');

      expect(MagicRouter.instance.hasIntendedUrl, isFalse);
    });

    testWidgets('without next it records nothing and keeps an earlier intent', (
      tester,
    ) async {
      MagicRouter.instance.setIntendedUrl('/teams');

      await mount(tester, '/auth/login');

      expect(MagicRouter.instance.pullIntendedUrl(), '/teams');
    });
  });
}
