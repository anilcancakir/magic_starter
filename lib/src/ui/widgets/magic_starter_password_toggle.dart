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
/// pointer floors, while the glyph stays 20 px. The sizes are spelled in pixels
/// because Wind multiplies a numeric size by the theme's spacing unit, which
/// would shrink the floor on a host that lowers it. A field with an eye is as
/// tall as the box: the suffix is centred in the field's `Row`, so a field
/// shorter than the box grows to it and a taller one is left alone.
class MagicStarterPasswordToggle extends StatelessWidget {
  static const _iconVisible = Icons.visibility;
  static const _iconHidden = Icons.visibility_off;

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
        className:
            'w-[44px] h-[44px] lg:w-[40px] lg:h-[40px] '
            'flex items-center justify-center',
        child: WIcon(
          obscured ? _iconVisible : _iconHidden,
          className: 'text-fg-muted text-xl',
        ),
      ),
    );
  }
}
