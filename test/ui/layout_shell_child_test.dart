import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// A host app's own shell, of the shape a consumer registers: it wraps the one
/// child it is handed and adds no keying of its own.
class _HostShell extends StatelessWidget {
  const _HostShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(child: child);
}

/// A page that reads the router state while it builds, as a page reading a
/// query parameter or a path parameter does.
class _StatePage extends StatelessWidget {
  const _StatePage();

  @override
  Widget build(BuildContext context) {
    return Text('at ${GoRouterState.of(context).uri.path}');
  }
}

/// A long page, the shape the persistent shell has to swap cleanly.
///
/// Its own list when [scrolls] is true; a plain column otherwise, for a layout
/// that already puts its child in a scroll view (the guest layout does).
class _ScrollPage extends StatelessWidget {
  const _ScrollPage(this.label, {required this.scrolls});

  final String label;

  final bool scrolls;

  @override
  Widget build(BuildContext context) {
    if (!scrolls) {
      return Column(
        children: <Widget>[
          for (int index = 0; index < 60; index++)
            SizedBox(height: 40, child: Text('$label $index')),
        ],
      );
    }

    return ListView.builder(
      itemCount: 200,
      itemBuilder: (BuildContext context, int index) =>
          SizedBox(height: 40, child: Text('$label $index')),
    );
  }
}

/// What `makeLayout` hands a layout is go_router's shell child, the nested
/// navigator, and that child must not be keyed on the route path.
///
/// go_router 18 keys the shell navigator's own state with a plain
/// `ValueKey(navigatorKey)`. A path key above it recreates that state on every
/// route change while the `Navigator` (a `GlobalKey`) survives, so the outgoing
/// page rebuilds against a registry that does not know it and
/// `GoRouterState.of` loops forever. The first group pins that freeze; the
/// second pins that a persistent shell still swaps scrollable pages cleanly
/// without the key, the reason the key was added.
void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() {
    MagicApp.reset();
    Magic.flush();
    TitleManager.reset();
    MagicRouter.reset();
    Auth.fake();
    Magic.singleton('magic_starter', MagicStarterManager.new);
  });

  tearDown(Auth.unfake);

  MagicStarterManager manager() {
    return Magic.make<MagicStarterManager>('magic_starter');
  }

  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      WindTheme(
        data: WindThemeData(),
        child: MaterialApp.router(
          routerConfig: MagicRouter.instance.routerConfig,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final String layoutKey in const <String>[
    'layout.host',
    'layout.guest',
  ]) {
    group('a persistent shell built with $layoutKey', () {
      setUp(() {
        // The guest layout ships with the starter; only the host key needs
        // registering.
        if (layoutKey == 'layout.host') {
          manager().view.registerLayout(
            layoutKey,
            (Widget child) => _HostShell(child: child),
          );
        }
      });

      testWidgets('leaves a page that reads GoRouterState in build', (
        WidgetTester tester,
      ) async {
        // `layoutId` makes the shell PERSISTENT across both routes, so one
        // layout element hands the same shell child slot from page to page.
        MagicRoute.group(
          layoutId: 'shell',
          layout: (Widget child) =>
              manager().view.makeLayout(layoutKey, child: child),
          routes: () {
            MagicRoute.page('/a', () => const _StatePage());
            MagicRoute.page('/a/b', () => const _StatePage());
          },
        );
        MagicRouter.instance.setInitialLocation('/a/b');

        await pumpRouter(tester);
        expect(find.text('at /a/b'), findsOneWidget);

        MagicRouter.instance.routerConfig.go('/a');
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('at /a'), findsOneWidget);
        expect(find.text('at /a/b'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('swaps scrollable pages under RouteTransition.none', (
        WidgetTester tester,
      ) async {
        final bool scrolls = layoutKey == 'layout.host';

        MagicRoute.group(
          layoutId: 'shell',
          layout: (Widget child) =>
              manager().view.makeLayout(layoutKey, child: child),
          routes: () {
            MagicRoute.page(
              '/one',
              () => _ScrollPage('one', scrolls: scrolls),
            ).transition(RouteTransition.none);
            MagicRoute.page(
              '/two',
              () => _ScrollPage('two', scrolls: scrolls),
            ).transition(RouteTransition.none);
          },
        );
        MagicRouter.instance.setInitialLocation('/one');

        await pumpRouter(tester);

        // Accumulated navigation, scrolled each time, is the arrangement the
        // render-object teardown needed: each leg leaves a scrolled list
        // behind and mounts the other in the same shell child slot.
        for (int leg = 0; leg < 12; leg++) {
          final String from = leg.isEven ? 'one' : 'two';
          final String to = leg.isEven ? 'two' : 'one';

          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -300),
          );
          await tester.pump();

          MagicRoute.to('/$to');
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('$to 0'), findsOneWidget);
          expect(find.text('$from 0'), findsNothing);
        }
      });
    });
  }
}
