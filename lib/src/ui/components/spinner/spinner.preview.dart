import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import 'spinner.dart';

/// Static variant-matrix preview for [MSSpinner].
///
/// Renders every [SpinnerSize], then the spinner on a `bg-primary` surface with
/// `text-on-primary`, so the catalog can show both in light and dark. One
/// preview class per file is the canonical Wave 4 contract.
class SpinnerPreview extends StatelessWidget {
  /// Creates the spinner variant-matrix preview.
  const SpinnerPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-6 p-6',
      children: [
        for (final SpinnerSize size in SpinnerSize.values)
          WDiv(
            className: 'flex flex-col gap-2',
            children: [
              WText(size.name, className: 'text-xs text-fg-muted'),
              MSSpinner(size: size),
            ],
          ),
        WDiv(
          className: 'flex flex-col gap-2',
          children: [
            WText('on primary', className: 'text-xs text-fg-muted'),
            WDiv(
              className:
                  'w-9 h-9 rounded-full flex items-center justify-center '
                  'bg-primary',
              child: const MSSpinner(
                size: SpinnerSize.sm,
                className: 'text-on-primary',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
