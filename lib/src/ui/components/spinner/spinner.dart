import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import 'spinner.recipe.dart';

// Static const so web tree-shaking keeps the glyph.
const _kIcon = Icons.refresh;

/// Size variants for [MSSpinner].
enum SpinnerSize {
  /// 16 logical pixels: inside a button or the send circle.
  sm,

  /// 20 logical pixels: the height of a select's arrow.
  md,

  /// 32 logical pixels: the sole content of a card.
  lg,
}

/// An indeterminate loading spinner built on [WIcon], so its colour comes from
/// the host's wind tokens and `dark:` setup rather than from Material's theme.
///
/// The glyph spins with `animate-spin` and takes the host's `primary` colour.
/// A spinner on a filled surface passes the surface's text role as [className]
/// (`text-on-primary` on a `bg-primary` circle).
///
/// The animation never settles, so a test that mounts one pumps frames
/// instead of calling `pumpAndSettle`.
///
/// ```dart
/// const MSSpinner()                                   // 20 px, primary
/// const MSSpinner(size: SpinnerSize.lg)               // 32 px
/// const MSSpinner(size: SpinnerSize.sm, className: 'text-on-primary')
/// ```
@immutable
class MSSpinner extends StatelessWidget {
  /// The side of the spinner. Defaults to [SpinnerSize.md].
  final SpinnerSize size;

  /// Optional caller className appended after the recipe output.
  ///
  /// Wind's parse-time per-family last-wins lets these tokens override the
  /// matching recipe classes while every non-overridden base class survives.
  final String? className;

  /// Creates a [MSSpinner] widget.
  const MSSpinner({super.key, this.size = SpinnerSize.md, this.className});

  @override
  Widget build(BuildContext context) {
    return WIcon(
      _kIcon,
      className: spinnerRecipe(
        variants: {kSpinnerSizeAxis: size.name},
        className: className,
      ),
    );
  }
}
