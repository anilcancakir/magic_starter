import 'package:magic/magic.dart';

/// The catalogue line for [key], or the English [fallback] when the host's
/// catalogue does not carry it.
///
/// For the names of the icon-only controls: `trans` answers a missing key with
/// the key itself, and a screen reader would then announce "auth dot show
/// underscore password" to someone installed before the key shipped in the
/// stub.
String magicStarterControlName(String key, String fallback) {
  return Lang.has(key) ? trans(key) : fallback;
}

/// The accessible name of a password field's show-or-hide eye.
///
/// Names the action the next tap performs, so it flips with [obscured].
String magicStarterPasswordToggleName({required bool obscured}) {
  return obscured
      ? magicStarterControlName('auth.show_password', 'Show password')
      : magicStarterControlName('auth.hide_password', 'Hide password');
}
