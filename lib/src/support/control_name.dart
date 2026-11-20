import 'package:magic/magic.dart';

/// The catalogue line for [key], or the English [fallback] when the host's
/// catalogue does not carry it.
///
/// For a line added to the install stub after hosts copied it: `trans`
/// answers a missing key with the key itself, so an icon-only control would
/// be announced as "auth dot show underscore password" and a new settings row
/// would read `magic_starter.privacy.title` to someone installed before the
/// key shipped.
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
