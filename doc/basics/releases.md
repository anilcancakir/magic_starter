# Releases

The opt-in `releases` and `app_update` features: a "What's new" page, a build caption and an update banner, all read from the backend's `GET releases` and from the web bundle's `version.json`.

- [Basic Usage](#basic-usage)
- [The Releases Feed](#the-releases-feed)
- [The Changelog Page](#the-changelog-page)
- [The Version Caption](#the-version-caption)
- [The Update Banner](#the-update-banner)
- [Web](#web)
- [iOS and Android](#ios-and-android)
- [Translations](#translations)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="basic-usage"></a>
## Basic Usage

`releases` adds a "What's new" page, a row for it on the settings hub and a version caption. `app_update` adds a banner that offers the newest build without interrupting the customer. Turn either on, or both, in `lib/config/magic_starter.dart`:

```dart
'features': {
  'releases': true,
  'app_update': true,
},
```

Both default to `false`. `registerMagicStarterProfileRoutes()` registers the changelog route like every other settings page, so a host that already calls it adds nothing else.

Both features read one guest-readable endpoint of `magic-starter-laravel`, `GET releases`. The backend has to enable its `releases` feature (`Features::releases()` in `config/magic-starter.php`) as well: with it off the endpoint answers 404, the changelog page shows its error state and the store banner stays quiet. The client reads no flag from the backend, so the two sides are switched on separately. The web banner does not use the endpoint; it reads `version.json` (see [Web](#web)).

<a name="the-releases-feed"></a>
## The Releases Feed

The client reads one body, newest release first, capped on the backend by `magic-starter.releases.limit` (default 50):

```json
{
  "data": [
    {
      "version": "1.1.0",
      "published_at": "2026-10-20T09:00:00.000000Z",
      "ios_build": 15,
      "android_build": 15,
      "items": [
        { "type": "new", "text": { "en": "Dark mode", "tr": "Koyu tema" } }
      ]
    }
  ],
  "meta": {
    "latest_build": { "ios": 15, "android": 15 }
  }
}
```

An item's `type` is `new`, `improved` or `fixed`; an item with any other type is skipped, so an older app keeps working when the backend learns a new one. The page shows the reader's own language, then `magic_starter.defaults.locale`, then the first entry that is not empty. `published_at`, `ios_build`, `android_build` and both `latest_build` values may be `null`, and `meta` may be missing.

`MagicStarterReleasesController` reads it. `readFeed()` is the stateless read the banner uses and answers `null` on any failure (logged as a warning); `fetchReleases()` loads the feed into the controller state for the page.

<a name="the-changelog-page"></a>
## The Changelog Page

With `releases` on, the settings hub gets a "What's new" row in its Preferences group, and the page opens at `MagicStarterConfig.settingsChangelogRoute()` (`/settings/changelog`, which follows `profile_prefix`). It is pushed (`.stacked()`), so the back gesture returns to the hub.

Each release is a card with its version, its date and one line per change, tagged with a New, Improved or Fixed badge. A failed read shows an error state with "Try again", and a feed with no releases shows an empty state.

The view key is `settings.changelog`. Replace the page the usual way:

```dart
MagicStarter.view.register('settings.changelog', () => const MyChangelogView());
```

<a name="the-version-caption"></a>
## The Version Caption

`MagicStarterAppVersion` is a one-line caption naming the build the app runs. The settings hub and the changelog page show it when `releases` is on; on the hub it closes the page, below anything a host registers in the hub's `footer` slot. A host that wants it elsewhere places the widget itself:

```dart
const MagicStarterAppVersion()
```

The text is the `magic_starter.releases.version_caption` line (`Version :version`), where the version reads `1.0.0 (14)` on iOS and Android, with `14` as the build number, and `1.0.0 · <build>` on the web. It shows only the version when the build number is empty. Pass `className` to replace the default style (`text-xs text-fg-muted text-center`). The widget renders nothing while the read is pending and when the platform cannot answer.

The support conversation's client info reads the same package info, so the caption and the report agree.

<a name="the-update-banner"></a>
## The Update Banner

`MagicStarterAppUpdateBanner` is a non-modal strip with a message, one action and "Later". The shipped app layout mounts it when `app_update` is on. A host with its own layout places it by hand, near the top of the content:

```dart
const MagicStarterAppUpdateBanner()
```

It checks once after mounting and again whenever the app resumes, at most once per 15 minutes (`MagicStarterAppUpdateBanner.checkInterval`). It never reloads by itself and never opens a dialog.

"Later" remembers the offered build in the `Vault` under `magic_starter.app_update.dismissed_build`, so the banner stays hidden for that build and returns only for a newer one. If the write fails, the banner is still hidden for the rest of the session.

A check that cannot read a build (no network, a refusal, an unreadable store) logs a warning and leaves the banner as it was. Desktop, debug and profile builds, and an app with `app_update` off, render nothing and start no timer.

<a name="web"></a>
## Web

On the web the banner compares the build the page is running with the `build_number` in the `version.json` the server serves now. The package fetches that file from the page's own origin, next to `index.html`, not through the `Http` facade (so it carries no base url and no bearer token), with a cache buster and `no-store`. It polls every 15 minutes and on resume, which a browser reports when the tab comes back to the front.

A difference is not shown at once. The banner waits 60 seconds from the moment it first sees the new build (`MagicStarterAppUpdateBanner.revealDelay`), so a deploy that is still rolling out does not flash it at every customer. The action is "Reload", which reloads the page.

The check needs a build number on both sides, so it stays quiet when `version.json` is missing or carries no `build_number`. Two deploys with the same build number look identical to it. Flutter writes the number it was built with into `version.json`, so give each deploy its own:

```bash
flutter build web --release --build-number="$GITHUB_SHA"
```

The running build is read once, at boot (when `app_update` or `releases` is on), and kept for the life of the page: a later first read could already see the next deploy and report it as the one that is loaded. Serving the new bundle after "Reload" is up to your server and CDN; the package configures nothing there.

<a name="ios-and-android"></a>
## iOS and Android

On a phone the banner compares the installed build number with `meta.latest_build` from the feed (`ios` or `android`) and shows at once when the store build is higher. It checks on mount and on resume, at most once per 15 minutes; there is no periodic timer.

It only looks at release builds installed from the store: the App Store (installer `com.apple`) and Google Play (`com.android.vending`). TestFlight, the simulator, a debug build and a sideload stay quiet for the rest of the session, since a store build would not replace them.

"Update" opens the store page:

| Platform | Opens |
|:---------|:------|
| iOS | `https://apps.apple.com/app/id<app_store_id>` |
| Android | `https://play.google.com/store/apps/details?id=<package>` |

iOS needs the App Store id, the same one the store review feature reads (the `store_review` feature itself can stay off):

```dart
'store_review': {
  'app_store_id': '1234567890',
},
```

Without it the iOS banner stays hidden and logs a warning. The banner also stays quiet until the backend publishes a release with a build number for the platform; a build that is not a plain number, on either side, is never counted as newer.

<a name="translations"></a>
## Translations

The copy lives under `magic_starter.releases.*`, `magic_starter.app_update.*` and `magic_starter.titles.changelog`. `starter:publish --tag=lang` skips an `assets/lang/en.json` that already exists unless you pass `--force`, so an existing app merges the new keys by hand from `assets/stubs/install/en.stub`. A missing key shows as the key itself.

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Enabling `releases` on the client only | The backend answers 404 until its own `releases` feature is on, and the page shows its error state. |
| Expecting the web banner to read the backend | It compares the bundle's build number with `version.json`; only the store banner reads `GET releases`. |
| Building every web deploy with the same build number | The banner cannot tell them apart. Pass a distinct `--build-number`. |
| Expecting the iOS banner without an App Store id | Set `magic_starter.store_review.app_store_id`; without it the banner stays hidden and logs a warning. |
| Testing the store banner from a debug build, TestFlight or a sideload | Only a release build installed from the App Store or Google Play checks. |
| Using the banner in a custom layout | The shipped layout mounts it; a host layout places `MagicStarterAppUpdateBanner` itself. |

<a name="related-documentation"></a>
## Related Documentation

- [Profile](./profile.md): the settings hub that carries the What's new row.
- [Support](./support.md): the conversation client info that shares the build caption.
- [Views and Layouts](./views-and-layouts.md): the view registry and the app shell that mounts the banner.
- [Configuration](../getting-started/configuration.md): the feature flags and the `store_review` keys.
