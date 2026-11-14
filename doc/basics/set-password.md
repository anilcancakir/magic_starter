# Set a Password

How the Security password page lets an account created through a provider set its first password, and what the backend refuses.

- [Introduction](#introduction)
- [The Page](#the-page)
- [doSetPassword](#dosetpassword)
- [Refusals](#refusals)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

An account created through a provider has no password (`has_password` is `false`), so there is nothing to change. The Security password page becomes **Set password** for it, and the user can then also sign in with email and password. The page is `settings.security.password`, reached from the Security group of the settings hub (see [Profile](./profile.md)).

<a name="the-page"></a>
## The Page

`MagicStarterPasswordView` reads `has_password` from `Auth.user()` on every build:

| `has_password` | Page |
|:---------------|:-----|
| `true`, or absent (a backend that predates social login) | The change form: current, new and confirm password, `doUpdatePassword`. |
| `false` | **Set password**: new and confirm password only, with the `profile.set_password_description` footer. |

Submitting the set form confirms the user's identity first (see [Confirming Identity](./identity-confirmation.md)): a first password is a new way into the account, so a password-less account steps up with a TOTP `code` or a `confirmation_token`, and a guest passes without a dialog. The dialog stays open while the backend refuses the proof, so the user retries with a fresh one. On success the user is restored, which flips `has_password` and with it the page from set to change.

<a name="dosetpassword"></a>
## doSetPassword

```dart
final success = await MagicStarterProfileController.instance.doSetPassword(
  password: form.get('password'),
  passwordConfirmation: form.get('password_confirmation'),
  proof: proof,
);
```

It sends `POST /user/password/set` with `password`, `password_confirmation` and the spread `proof`. The backend applies the same rules as a password change (at least 8 characters with letters, numbers and mixed case, confirmed). On success the controller calls `Auth.restore()`, shows the `profile.password_set` toast and sets success state; on a refusal it shows the refusal's own sentence or the `profile.password_set_failed` fallback.

`magic-starter-laravel` registers `POST /user/password/set` only with its `socialLogin` feature on. With it off the route does not exist and the call fails as any other 404.

<a name="refusals"></a>
## Refusals

The controller reads a refusal by its `code`:

| Code | Meaning | Client behaviour |
|:-----|:--------|:-----------------|
| `password_already_set` (422) | The account already has a password. | The user is restored; the page rebuilds with the change form. |
| `step_up_required` (422) | The proof was missing or spent. | The step-up dialog narrows to the proofs in `accepts` and stays open. |

The mirror case: `PUT /user/password` on a password-less account answers 422 `password_not_set`, the user is restored, and the page rebuilds with the set form.

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Calling `doSetPassword` without a `proof` | `proof` is required. Produce it with `confirmIdentity`, or let the page do it through `confirmAndRun`. |
| Showing the change form to a password-less account | Read `has_password` from `Auth.user()` (absent means `true`); the controller restores the user on `password_not_set` so the page can correct itself. |
| Switching on the set flow with the backend's social login off | The set route is registered only with the backend's `socialLogin` feature; enable both sides. |
| Matching a refusal by its message | Read the `code` (`password_already_set`, `step_up_required`); the sentence is translated. |

<a name="related-documentation"></a>
## Related Documentation

- [Confirming Identity](./identity-confirmation.md): how the `proof` is produced.
- [Profile](./profile.md): the settings hub and the change-password flow.
- [Connected Accounts](./connected-accounts.md): linking and unlinking providers.
- [Authentication](./authentication.md): sign-in and social login.
