import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Stand-in for a host app's own shell widget, used to prove that a
/// registered override replaces the default `layout.app` builder rather
/// than merely coexisting with it.
class _CustomAppShell extends StatelessWidget {
  const _CustomAppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

void main() {
  group('layout.app override seam', () {
    late MagicStarterManager manager;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      Magic.singleton('magic_starter', () => MagicStarterManager());
      manager = Magic.make<MagicStarterManager>('magic_starter');
    });

    test('the default MagicStarterAppLayout renders when no override is registered', () {
      final Widget resolved = manager.view.makeLayout(
        'layout.app',
        child: const SizedBox(),
      );

      expect(resolved, isA<MagicStarterAppLayout>());
      expect(resolved, isNot(isA<_CustomAppShell>()));
    });

    test(
      'a registered override replaces the default, regardless of call order',
      () {
        // 1. The manager's constructor already registered the default
        //    'layout.app' builder (conditionally, via _registerDefaultLayout).
        expect(manager.view.hasLayout('layout.app'), isTrue);

        // 2. registerLayout() is an unconditional write, so calling it after
        //    the default was set still replaces the entry outright.
        manager.view.registerLayout(
          'layout.app',
          (child) => _CustomAppShell(child: child),
        );

        final Widget resolved = manager.view.makeLayout(
          'layout.app',
          child: const SizedBox(),
        );

        expect(resolved, isA<_CustomAppShell>());
        expect(resolved, isNot(isA<MagicStarterAppLayout>()));
      },
    );

    test('hands the override the child it was given, unwrapped', () {
      // Under a route group the child is go_router's shell navigator. A
      // wrapper keyed on the route path above it recreates the navigator's
      // state on every route change under go_router 18, which freezes a page
      // that reads GoRouterState in build (layout_shell_child_test.dart).
      Widget? received;
      manager.view.registerLayout('layout.app', (child) {
        received = child;

        return _CustomAppShell(child: child);
      });

      const Widget page = SizedBox(key: Key('page'));
      manager.view.makeLayout('layout.app', child: page);

      expect(received, same(page));
    });

    test('the key stays "layout.app" after an override is registered', () {
      manager.view.registerLayout(
        'layout.app',
        (child) => _CustomAppShell(child: child),
      );

      expect(manager.view.hasLayout('layout.app'), isTrue);
      expect(
        () => manager.view.makeLayout('layout.app', child: const SizedBox()),
        returnsNormally,
      );
    });
  });
}
