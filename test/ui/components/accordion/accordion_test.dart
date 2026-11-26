import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void main() {
  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Magic.singleton('magic_starter', () => MagicStarterManager());
  });

  tearDown(() {
    MagicApp.reset();
    Magic.flush();
  });

  Widget wrap(Widget widget) {
    return MaterialApp(
      home: WindTheme(
        data: WindThemeData(),
        child: Scaffold(body: widget),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recipe slot-class assertions
  // ---------------------------------------------------------------------------

  group('accordion recipe', () {
    test('root slot is non-empty', () {
      final cls = accordionRecipe();
      expect(cls['root'], isNotEmpty);
    });

    test('item slot is non-empty', () {
      final cls = accordionRecipe();
      expect(cls['item'], isNotEmpty);
    });

    test('header slot is non-empty', () {
      final cls = accordionRecipe();
      expect(cls['header'], isNotEmpty);
    });

    test('trigger slot is non-empty', () {
      final cls = accordionRecipe();
      expect(cls['trigger'], isNotEmpty);
    });

    test('panel slot is non-empty', () {
      final cls = accordionRecipe();
      expect(cls['panel'], isNotEmpty);
    });

    test('all six required slots are present', () {
      final cls = accordionRecipe();
      expect(
        cls.keys,
        containsAll(['root', 'item', 'header', 'trigger', 'panel', 'icon']),
      );
    });

    test('icon slot sizes the chevron and colours it from the tokens', () {
      final cls = accordionRecipe();
      expect(cls['icon'], contains('text-[18px]'));
      expect(cls['icon'], contains('text-fg'));
    });

    test('a classNames override reaches the icon slot', () {
      final cls = accordionRecipe(classNames: {'icon': 'text-primary'});
      expect(cls['icon'], contains('text-primary'));
    });
  });

  // ---------------------------------------------------------------------------
  // Chevron
  // ---------------------------------------------------------------------------

  group('Accordion chevron', () {
    Widget wrapThemed(
      Widget widget, {
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        home: WindTheme(
          data: WindThemeData(
            brightness: brightness,
            syncWithSystem: false,
            aliases: MagicStarterTokens.defaultAliases,
          ),
          child: Scaffold(body: widget),
        ),
      );
    }

    MSAccordion accordion({Map<String, String>? classNames}) {
      return MSAccordion(
        classNames: classNames,
        items: const [
          MSAccordionItem(title: 'Section 1', body: Text('Content 1')),
        ],
      );
    }

    testWidgets('is a WIcon carrying the icon slot className', (tester) async {
      await tester.pumpWidget(wrapThemed(accordion()));

      final WIcon chevron = tester.widget<WIcon>(find.byType(WIcon));
      expect(chevron.className, accordionRecipe()['icon']);
      expect(chevron.icon, Icons.keyboard_arrow_down);
    });

    testWidgets('flips to the up arrow when the item opens', (tester) async {
      await tester.pumpWidget(wrapThemed(accordion()));
      await tester.tap(find.text('Section 1'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<WIcon>(find.byType(WIcon)).icon,
        Icons.keyboard_arrow_up,
      );
    });

    testWidgets('a classNames icon override reaches the chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapThemed(accordion(classNames: {'icon': 'text-[24px]'})),
      );

      final Icon chevron = tester.widget<Icon>(find.byType(Icon));
      expect(chevron.size, 24);
    });

    testWidgets('light and dark resolve different colours from the slot', (
      tester,
    ) async {
      await tester.pumpWidget(wrapThemed(accordion()));
      final Color? light = tester.widget<Icon>(find.byType(Icon)).color;

      await tester.pumpWidget(
        wrapThemed(accordion(), brightness: Brightness.dark),
      );
      final Color? dark = tester.widget<Icon>(find.byType(Icon)).color;

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(dark, isNot(light));
      expect(tester.widget<Icon>(find.byType(Icon)).size, 18);
    });

    testWidgets('dark mode takes the dark colour of the text-fg alias', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapThemed(accordion(), brightness: Brightness.dark),
      );

      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        WindThemeData().getColor('gray', 50),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Widget interaction tests
  // ---------------------------------------------------------------------------

  group('Accordion widget', () {
    testWidgets('renders item titles', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSAccordion(
            items: const [
              MSAccordionItem(title: 'Section 1', body: Text('Content 1')),
              MSAccordionItem(title: 'Section 2', body: Text('Content 2')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
    });

    testWidgets('content is hidden by default (collapsed)', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSAccordion(
            items: const [
              MSAccordionItem(title: 'Section 1', body: Text('Content 1')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content 1'), findsNothing);
    });

    testWidgets('tapping header expands the panel', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSAccordion(
            items: const [
              MSAccordionItem(title: 'Section 1', body: Text('Content 1')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Section 1'));
      await tester.pumpAndSettle();

      expect(find.text('Content 1'), findsOneWidget);
    });

    testWidgets('tapping expanded header collapses the panel', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSAccordion(
            items: const [
              MSAccordionItem(title: 'Section 1', body: Text('Content 1')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand.
      await tester.tap(find.text('Section 1'));
      await tester.pumpAndSettle();
      expect(find.text('Content 1'), findsOneWidget);

      // Collapse.
      await tester.tap(find.text('Section 1'));
      await tester.pumpAndSettle();
      expect(find.text('Content 1'), findsNothing);
    });
  });
}
