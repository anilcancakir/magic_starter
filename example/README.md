# magic_starter example

A Magic app that boots `MagicStarterServiceProvider` with every feature off and shows what the starter answers without a backend: the config it read (`MagicStarterConfig`), which view keys the registry holds (`MagicStarter.view.has`) and `MagicStarter.isReady`. A button opens the shipped login screen (`auth.login`) through the starter's guest route group, with a header slot the example registers on it.

```bash
cd example
flutter create --platforms=web .
flutter run -d chrome
```

`flutter create` adds the platform folder once; it leaves `lib/` and `pubspec.yaml` as they are.

What works offline: boot, the config, the view registry, the slot, the routes and the login form itself. What needs a backend: signing in. The form posts to `<API_URL>/auth/login`, which is `magic-starter-laravel`'s `api/v1`; with nothing listening there the screen shows the error. Point it at your own backend with `flutter run -d chrome --dart-define=API_URL=https://api.example.com/api/v1`. Keep tokens and keys out of the repo.

The example has no `User` model, no generated `lib/config/` and no `assets/lang/en.json`, so it passes `MagicStarterAuthUser.fromMap` to `MagicStarter.bootstrap()` and reads the English catalogue the package bundles for `starter:install`. A real app runs `dart run magic:dowel plugin:install magic_starter`, which writes all three, and turns features on in `lib/config/magic_starter.dart`. Push notifications, store review and store billing need a device as well as the backend.
