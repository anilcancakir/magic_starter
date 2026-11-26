import 'package:magic/magic.dart';

/// The size axis key for the spinner recipe (`SpinnerSize.<value>.name`).
const String kSpinnerSizeAxis = 'size';

/// Builds the spinner [WindRecipe] from the host's `primary` colour.
///
/// The recipe is a top-level const because the spinner has no theme-override
/// hook.
///
/// Base spins the glyph and colours it with the same shades as the `bg-primary`
/// alias (600 in light, 500 in dark), so a host's `primary` re-skins it. Every
/// token is a palette shade with its own `dark:` pair, since `primary-*` is
/// not an alias key; a caller that sits on a filled surface replaces the pair
/// with a role such as `text-on-primary`.
///
/// Emission order: `base ++ size-variant`.
///
/// Size -> additional className, in logical pixels (arbitrary values, so a
/// host's `fontSize` scale never moves the box):
/// - sm: `text-[16px]`, inside a button or the send circle
/// - md: `text-[20px]`, the height of a select's arrow
/// - lg: `text-[32px]`, the sole content of a card
const WindRecipe spinnerRecipe = WindRecipe(
  base: 'animate-spin text-primary-600 dark:text-primary-500',
  variants: {
    kSpinnerSizeAxis: {
      'sm': 'text-[16px]',
      'md': 'text-[20px]',
      'lg': 'text-[32px]',
    },
  },
  defaultVariants: {kSpinnerSizeAxis: 'md'},
);
