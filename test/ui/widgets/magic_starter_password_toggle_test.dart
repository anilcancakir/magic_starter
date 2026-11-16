import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void main() {
  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Magic.singleton('log', () => LogManager());
    Magic.singleton('magic_starter', () => MagicStarterManager());
  });

  void useViewport(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: WindTheme(
        data: WindThemeData(),
        child: Scaffold(body: child),
      ),
    );
  }

  Widget toggle({bool obscured = true, VoidCallback? onToggle}) {
    return MagicStarterPasswordToggle(
      obscured: obscured,
      onToggle: onToggle ?? () {},
    );
  }

  Size nodeSize(WidgetTester tester, String label) {
    return tester.getSemantics(find.bySemanticsLabel(label)).rect.size;
  }

  group('MagicStarterPasswordToggle', () {
    testWidgets('names the next tap and flips with the state', (tester) async {
      final handle = tester.ensureSemantics();
      var obscured = true;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => toggle(
              obscured: obscured,
              onToggle: () => setState(() => obscured = !obscured),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Show password'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
      expect(find.bySemanticsLabel('Show password'), findsNothing);

      handle.dispose();
    });

    testWidgets('is at least 44x44 below lg', (tester) async {
      final handle = tester.ensureSemantics();
      useViewport(tester, 390);

      await tester.pumpWidget(wrap(toggle()));
      await tester.pumpAndSettle();

      final size = nodeSize(tester, 'Show password');
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));

      handle.dispose();
    });

    testWidgets('is at least 40x40 from lg up', (tester) async {
      final handle = tester.ensureSemantics();
      useViewport(tester, 1440);

      await tester.pumpWidget(wrap(toggle()));
      await tester.pumpAndSettle();

      final size = nodeSize(tester, 'Show password');
      expect(size.width, greaterThanOrEqualTo(40));
      expect(size.height, greaterThanOrEqualTo(40));

      handle.dispose();
    });

    testWidgets('taps through its whole box, not only the icon', (
      tester,
    ) async {
      useViewport(tester, 390);
      var taps = 0;

      await tester.pumpWidget(wrap(toggle(onToggle: () => taps++)));
      await tester.pumpAndSettle();

      // A point 14 px left of the icon's centre is outside the 20 px glyph and
      // inside the 44 px box.
      final centre = tester.getCenter(find.byType(MagicStarterPasswordToggle));
      await tester.tapAt(centre.translate(-14, 14));

      expect(taps, 1);
    });

    // The field is shorter than the box (38 px at 14 px text), so the eye lifts
    // it to the box and no further: the box is the one thing that sets the
    // height of a field that has an eye.
    for (final (width, box) in const [(390.0, 44.0), (1440.0, 40.0)]) {
      testWidgets('lifts the field to its own ${box}px box and no further at '
          '$width', (tester) async {
        useViewport(tester, width);
        final plain = TextEditingController();
        final withEye = TextEditingController();
        addTearDown(plain.dispose);
        addTearDown(withEye.dispose);

        await tester.pumpWidget(
          wrap(
            Column(
              children: [
                WFormInput(
                  key: const Key('plain'),
                  controller: plain,
                  type: InputType.password,
                  className: MagicStarter.formTheme.inputClassName,
                ),
                WFormInput(
                  key: const Key('with-eye'),
                  controller: withEye,
                  type: InputType.password,
                  suffix: toggle(),
                  className: MagicStarter.formTheme.inputClassName,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byKey(const Key('with-eye'))).height, box);
        expect(
          tester.getSize(find.byKey(const Key('plain'))).height,
          lessThan(box),
        );
      });
    }
  });
}
