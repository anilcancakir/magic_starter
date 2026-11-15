import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the config that starter:publish copies turns every feature off', () {
    // The README, llms.txt and the configuration page say every feature
    // defaults to false and a screen appears only when its toggle is on, so
    // the template an app receives must not switch any of them on.
    final String source = File('lib/config/magic_starter.dart')
        .readAsStringSync();
    final Match? block = RegExp(r"'features':\s*\{([^}]*)\}")
        .firstMatch(source);

    expect(block, isNotNull, reason: 'the template has a features map');

    final Iterable<RegExpMatch> toggles = RegExp(r"'(\w+)':\s*(true|false)")
        .allMatches(block!.group(1)!);
    final List<String> enabled = <String>[
      for (final RegExpMatch toggle in toggles)
        if (toggle.group(2) == 'true') toggle.group(1)!,
    ];

    expect(toggles, isNotEmpty);
    expect(enabled, isEmpty);
  });
}
