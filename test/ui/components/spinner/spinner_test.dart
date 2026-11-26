import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';
import 'package:magic_starter/src/ui/components/spinner/spinner.preview.dart';

void main() {
  setUp(() {
    // The style cache is keyed by className and brightness, not by the host's
    // colours, so a test that changes `primary` starts from an empty one.
    WindParser.clearCache();
    MagicApp.reset();
    Magic.flush();
    Magic.singleton('magic_starter', () => MagicStarterManager());
  });

  tearDown(() {
    MagicApp.reset();
    Magic.flush();
  });

  // `syncWithSystem: false` keeps a dark theme dark: a syncing one is reset to
  // the test platform's light brightness when it first mounts.
  Widget wrap(Widget widget, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      home: WindTheme(
        data: WindThemeData(
          brightness: brightness,
          syncWithSystem: false,
          aliases: MagicStarterTokens.defaultAliases,
        ),
        child: Scaffold(body: Center(child: widget)),
      ),
    );
  }

  Icon icon(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon));

  group('spinner recipe', () {
    test('every size spins and carries a colour pair', () {
      for (final SpinnerSize size in SpinnerSize.values) {
        final String cls = spinnerRecipe(
          variants: {kSpinnerSizeAxis: size.name},
        );

        expect(cls, contains('animate-spin'), reason: size.name);
        expect(cls, contains('text-primary-600'), reason: size.name);
        expect(cls, contains('dark:text-primary-500'), reason: size.name);
      }
    });

    test('sizes map to 16, 20 and 32 logical pixels', () {
      expect(
        spinnerRecipe(variants: {kSpinnerSizeAxis: 'sm'}),
        contains('text-[16px]'),
      );
      expect(
        spinnerRecipe(variants: {kSpinnerSizeAxis: 'md'}),
        contains('text-[20px]'),
      );
      expect(
        spinnerRecipe(variants: {kSpinnerSizeAxis: 'lg'}),
        contains('text-[32px]'),
      );
    });

    test('default size is md', () {
      expect(spinnerRecipe(), contains('text-[20px]'));
    });
  });

  group('MSSpinner', () {
    testWidgets('is a spinning WIcon and no Material progress indicator', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const MSSpinner()));

      expect(find.byType(WIcon), findsOneWidget);
      expect(
        tester.widget<WIcon>(find.byType(WIcon)).className,
        contains('animate-spin'),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('paints each size as a square of that side', (tester) async {
      const Map<SpinnerSize, double> sides = {
        SpinnerSize.sm: 16,
        SpinnerSize.md: 20,
        SpinnerSize.lg: 32,
      };

      for (final MapEntry<SpinnerSize, double> entry in sides.entries) {
        await tester.pumpWidget(wrap(MSSpinner(size: entry.key)));

        expect(
          tester.getSize(find.byType(MSSpinner)),
          Size.square(entry.value),
          reason: entry.key.name,
        );
      }
    });

    testWidgets('takes the host primary, 600 in light and 500 in dark', (
      tester,
    ) async {
      const ink = MaterialColor(0xFF223344, <int, Color>{
        50: Color(0xFF000001),
        100: Color(0xFF000002),
        200: Color(0xFF000003),
        300: Color(0xFF000004),
        400: Color(0xFF000005),
        500: Color(0xFF000006),
        600: Color(0xFF000007),
        700: Color(0xFF000008),
        800: Color(0xFF000009),
        900: Color(0xFF00000A),
      });

      Widget host(Brightness brightness) => MaterialApp(
        home: WindTheme(
          data: WindThemeData(
            brightness: brightness,
            syncWithSystem: false,
            colors: const {'primary': ink},
          ),
          child: const Scaffold(body: MSSpinner()),
        ),
      );

      await tester.pumpWidget(host(Brightness.light));
      expect(icon(tester).color, ink[600]);

      await tester.pumpWidget(host(Brightness.dark));
      expect(icon(tester).color, ink[500]);
    });

    testWidgets('a caller colour replaces the recipe colour in both modes', (
      tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        await tester.pumpWidget(
          wrap(
            const MSSpinner(className: 'text-on-primary'),
            brightness: brightness,
          ),
        );

        expect(
          icon(tester).color,
          const Color(0xFFFFFFFF),
          reason: '$brightness',
        );
      }
    });

    testWidgets('preview renders every size and the on-primary case', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const SpinnerPreview()));

      // One per size, then the spinner on a `bg-primary` circle.
      expect(
        find.byType(MSSpinner),
        findsNWidgets(SpinnerSize.values.length + 1),
      );
    });
  });
}
