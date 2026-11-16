import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../support/control_name.dart';

/// The show-or-hide eye at the end of a password field.
///
/// Pass it as a `WFormInput` `suffix`. Its name is the action the next tap
/// performs ([magicStarterPasswordToggleName]), so it flips with [obscured].
///
/// The box is 44 px square below `lg` and 40 px from `lg` up, the touch and the
/// pointer floors, while the glyph stays 20 px. Both fit inside the field's own
/// height (44 px below `lg`, 40 px from `lg` up), and a suffix is centred in a
/// `Row`, so the eye adds nothing to the height of the field it sits in.
class MagicStarterPasswordToggle extends StatelessWidget {
  /// Creates the eye for a field that is [obscured] or shown.
  const MagicStarterPasswordToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  /// Whether the field currently hides its text.
  final bool obscured;

  /// Flips the field between hidden and shown.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return WAnchor(
      onTap: onToggle,
      semanticLabel: magicStarterPasswordToggleName(obscured: obscured),
      child: WDiv(
        className: 'w-11 h-11 lg:w-10 lg:h-10 flex items-center justify-center',
        child: WIcon(
          obscured ? Icons.visibility : Icons.visibility_off,
          className: 'text-fg-muted text-xl',
        ),
      ),
    );
  }
}
