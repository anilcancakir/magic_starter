import 'package:material_ui/material_ui.dart'
    hide DropdownMenu, DropdownMenuItem, DropdownMenuEntry;
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

void main() {
  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Magic.singleton('magic_starter', () => MagicStarterManager());
  });

  Widget wrap(Widget widget) {
    return MaterialApp(
      home: WindTheme(
        data: WindThemeData(),
        child: Scaffold(body: Center(child: widget)),
      ),
    );
  }

  group('DropdownMenu', () {
    testWidgets('renders trigger child', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            items: const [MSDropdownMenuItem(label: 'Item 1')],
            child: const Text('open menu'),
          ),
        ),
      );

      expect(find.text('open menu'), findsOneWidget);
    });

    testWidgets('items are not visible when closed', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            items: const [MSDropdownMenuItem(label: 'Hidden Item')],
            child: const Text('open menu'),
          ),
        ),
      );

      expect(find.text('Hidden Item'), findsNothing);
    });

    testWidgets('tapping trigger opens the menu items', (tester) async {
      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            items: const [MSDropdownMenuItem(label: 'Visible Item')],
            child: const Text('open menu'),
          ),
        ),
      );

      await tester.tap(find.text('open menu'));
      await tester.pump();

      expect(find.text('Visible Item'), findsOneWidget);
    });

    testWidgets('tapping an item invokes onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            items: [
              MSDropdownMenuItem(label: 'Tap me', onTap: () => tapped = true),
            ],
            child: const Text('open menu'),
          ),
        ),
      );

      await tester.tap(find.text('open menu'));
      // Newer wind_kit lays the panel out in an ignored measuring frame first,
      // so a second frame is needed before the item takes taps.
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('DropdownMenuItem disabled label is rendered in menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            items: const [
              MSDropdownMenuItem(label: 'Normal'),
              MSDropdownMenuItem(label: 'Disabled', disabled: true),
            ],
            child: const Text('open menu'),
          ),
        ),
      );

      await tester.tap(find.text('open menu'));
      await tester.pump();

      // Both labels should be visible; the disabled item is rendered but
      // without a tap handler (no WAnchor wrapper).
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // DropdownMenuItem data class
  // ---------------------------------------------------------------------------

  test('DropdownMenuItem holds label, onTap, disabled', () {
    const item = MSDropdownMenuItem(label: 'Test', disabled: false);
    // Data-class field assertions use the type directly (not tester.widget).
    expect(item.label, 'Test');
    expect(item.disabled, isFalse);
    expect(item.onTap, isNull);
  });

  // Verify DropdownMenu is re-exported from index.dart
  test('DropdownMenu is re-exported from index.dart', () {
    expect(MSDropdownMenu, isNotNull);
  });

  // ---------------------------------------------------------------------------
  // Caller className append (WIND-1)
  // ---------------------------------------------------------------------------

  group('DropdownMenu className append', () {
    testWidgets('panel appends caller className onto the default', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            className: 'mt-10',
            items: const [MSDropdownMenuItem(label: 'Item 1')],
            child: const Text('open menu'),
          ),
        ),
      );
      final popover = tester.widget<WPopover>(find.byType(WPopover));
      expect(popover.className, contains('bg-surface'));
      expect(popover.className, contains('mt-10'));
    });

    testWidgets('item appends caller className onto the item default', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MSDropdownMenu(
            items: const [
              MSDropdownMenuItem(label: 'Edit', className: 'mt-10'),
            ],
            child: const Text('open menu'),
          ),
        ),
      );
      await tester.tap(find.text('open menu'));
      await tester.pump();
      final itemDiv = tester
          .widgetList<WDiv>(find.byType(WDiv))
          .firstWhere((w) => w.className?.contains('mt-10') == true);
      expect(itemDiv.className, contains('px-4'));
    });

    testWidgets(
      'disabled item appends caller className onto the disabled default',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            MSDropdownMenu(
              items: const [
                MSDropdownMenuItem(
                  label: 'Gone',
                  disabled: true,
                  className: 'mt-10',
                ),
              ],
              child: const Text('open menu'),
            ),
          ),
        );
        await tester.tap(find.text('open menu'));
        await tester.pump();
        final itemDiv = tester
            .widgetList<WDiv>(find.byType(WDiv))
            .firstWhere((w) => w.className?.contains('mt-10') == true);
        expect(itemDiv.className, contains('text-fg-disabled'));
      },
    );
  });

  group('DropdownMenu long labels', () {
    const longLabel = 'A label far wider than the pinned menu panel';

    Future<void> openMenu(
      WidgetTester tester, {
      required List<MSDropdownMenuItem> items,
      String? className,
      double textScale = 1.0,
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: wrap(
            MSDropdownMenu(
              className: className,
              items: items,
              child: const Text('open menu'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open menu'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('an active label wraps inside a pinned panel at 1.3x', (
      tester,
    ) async {
      await openMenu(
        tester,
        className: 'w-48',
        textScale: 1.3,
        items: const [
          MSDropdownMenuItem(
            label: longLabel,
            leading: SizedBox(width: 16, height: 16),
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      final label = tester.getSize(find.text(longLabel));
      expect(label.width, lessThanOrEqualTo(192));
      expect(label.height, greaterThan(14 * 1.3 * 2));
    });

    testWidgets('a disabled label wraps inside a pinned panel', (tester) async {
      await openMenu(
        tester,
        className: 'w-48',
        items: const [
          MSDropdownMenuItem(
            label: longLabel,
            disabled: true,
            leading: SizedBox(width: 16, height: 16),
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text(longLabel)).width,
        lessThanOrEqualTo(192),
      );
    });

    testWidgets('an unpinned panel still sizes to a short label', (
      tester,
    ) async {
      await openMenu(tester, items: const [MSDropdownMenuItem(label: 'Edit')]);

      final panel = tester.getSize(
        find
            .ancestor(
              of: find.text('Edit'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(panel.width, lessThan(400));
    });
  });
}
