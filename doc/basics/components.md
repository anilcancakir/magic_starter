# Design-System Components

The `MS`-prefixed Wind components the starter's screens are built from, and the semantic token layer that skins them.

- [Introduction](#introduction)
- [Semantic Token Layer](#semantic-token-layer)
  - [MagicStarterTokens](#magicstartertokens)
  - [Wiring into WindThemeData](#wiring-into-windthemedata)
  - [Token Reference](#token-reference)
- [Atomic Folder Shape](#atomic-folder-shape)
- [Component Families](#component-families)
  - [Form Controls](#form-controls)
  - [Display and Feedback](#display-and-feedback)
  - [Selection and Navigation](#selection-and-navigation)
  - [Overlay](#overlay)
  - [Composition and App Chrome](#composition-and-app-chrome)
- [Import Collisions](#import-collisions)
- [design.md.stub](#designmdstub)
- [Component Previews](#component-previews)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

Magic Starter ships an atomic design-system component library under `lib/src/ui/components/`. Each component is driven by a recipe that resolves colours through the `MagicStarterTokens` semantic alias layer, so a single brand configuration flows into all built-in screens and every component your host app composes directly.

The components are exported from `package:magic_starter/magic_starter.dart`. The families below cover the form, display, navigation, overlay and layout components; the barrel also exports `MSAvatar`, `MSConfirmDialog`, the settings rows (`MSSettingsSection`, `MSSettingsRow`, `MSSettingsNavRow`), `MSUpdateBanner`, `MSUpgradeDialog`, `MSUpgradeNudge` and `MSUsageMeter`.

<a name="semantic-token-layer"></a>
## Semantic Token Layer

<a name="magicstartertokens"></a>
### MagicStarterTokens

`MagicStarterTokens` is a `final` class with a `const` map, `defaultAliases`, and two helpers. `defaultAliases` maps semantic class names to light and dark Wind className pairs. Each key is the full class it replaces (`bg-surface`, `text-fg`, `border-color-border`), not a bare role name, because Wind expands an alias only when a whole token matches a key:

```dart
final aliases = MagicStarterTokens.defaultAliases;
// {
//   'bg-surface':               'bg-white dark:bg-gray-950',
//   'text-fg':                  'text-gray-900 dark:text-gray-50',
//   'bg-primary':               'bg-primary-600 dark:bg-primary-500',
//   'border-color-border':      'border-gray-200 dark:border-gray-700',
//   'bg-destructive':           'bg-red-600 dark:bg-red-500',
//   ...
// }
```

| Helper | Returns |
|:-------|:--------|
| `MagicStarterTokens.role(theme, token)` | The token itself when the theme defines it (an alias key, or a backing colour in `WindThemeData.colors`); otherwise the default alias or a fallback pair, so a partly configured theme never renders an invisible surface. |
| `MagicStarterTokens.readableOn(context, fill:, role:)` | The on-colour class for a fill: the host's own role when it defines one, otherwise `text-white` or `text-gray-950`, whichever has the better contrast against the fill in the current brightness. |

<a name="wiring-into-windthemedata"></a>
### Wiring into WindThemeData

Pass `MagicStarterTokens.defaultAliases` as the `aliases` argument of the `WindThemeData` you give `MagicApplication`, and hand the same theme to `MagicStarter.useWindTheme` so the navigation, modal, form, card, page header, layout, auth and dropdown themes are derived from it:

```dart
final windTheme = WindThemeData(
  colors: {'primary': myBrandColor},
  aliases: MagicStarterTokens.defaultAliases,
);

MagicApplication(
  title: 'Acme',
  windTheme: windTheme,
);

// In AppServiceProvider.boot():
MagicStarter.useWindTheme(windTheme);
```

Components that reference a semantic class (`bg-surface`, `text-fg`, `bg-primary`) resolve through this map at render time. Without the aliases wired in, those class names are silently skipped by Wind, so your brand colour and surface tokens do not apply. `useWindTheme` resets the button and field themes, so call `MagicStarter.useButtonTheme` and `useFieldTheme` after it.

<a name="token-reference"></a>
### Token Reference

| Alias key | Semantic meaning | Maps to (default) |
|:----------|:-----------------|:------------------|
| `bg-surface` | Page/card background | `bg-white dark:bg-gray-950` |
| `bg-surface-container` | Subtle recessed area | `bg-gray-50 dark:bg-gray-900` |
| `bg-surface-container-high` | Elevated container | `bg-gray-100 dark:bg-gray-800` |
| `text-fg` | Primary text | `text-gray-900 dark:text-gray-50` |
| `text-fg-muted` | Secondary/supporting text | `text-gray-500 dark:text-gray-400` |
| `text-fg-disabled` | Disabled state text | `text-gray-300 dark:text-gray-600` |
| `bg-primary` | Brand primary fill | `bg-primary-600 dark:bg-primary-500` |
| `text-on-primary` | Text on primary fill | `text-white dark:text-white` |
| `bg-primary-container` | Tinted primary area | `bg-primary-100 dark:bg-primary-900` |
| `bg-accent` | Secondary brand fill | `bg-indigo-600 dark:bg-indigo-500` |
| `border-color-border` | Standard border colour | `border-gray-200 dark:border-gray-700` |
| `border-color-border-subtle` | Faint separator colour | `border-gray-100 dark:border-gray-800` |
| `bg-destructive` | Danger / delete fill | `bg-red-600 dark:bg-red-500` |
| `text-on-destructive` | Text on danger fill | `text-white dark:text-white` |
| `bg-destructive-container` | Tinted danger area | `bg-red-100 dark:bg-red-900` |
| `bg-success` | Positive / confirmed | `bg-green-600 dark:bg-green-500` |
| `bg-warning` | Caution / review | `bg-amber-600 dark:bg-amber-500` |
| `bg-ai-soft` | Soft container for AI-authored content (replies, summaries) | `bg-violet-100 dark:bg-violet-900` |
| `text-ai-soft-foreground` | Text or icon on top of `bg-ai-soft` | `text-violet-700 dark:text-violet-200` |
| `border-ai` | Accent edge of AI-authored content | `border-violet-500 dark:border-violet-400` |
| `bg-warning-soft` | Soft amber container for a quiet status pill | `bg-amber-100 dark:bg-amber-900` |
| `text-warning-soft-foreground` | Text or icon on top of `bg-warning-soft` | `text-amber-800 dark:text-amber-200` |
| `bg-success-soft` | Soft green container for a quiet status pill | `bg-green-100 dark:bg-green-900` |
| `text-success-soft-foreground` | Text or icon on top of `bg-success-soft` | `text-green-800 dark:text-green-200` |

`text-destructive`, `text-primary`, `text-on-success` and `text-on-warning` are not alias keys: `MagicStarterTokens.role` answers them with a fallback pair when the host theme does not define them. The support screens use the AI pair and `border-ai` for the assistant's avatar, its bubble (a 2px left edge) and its chip, and the soft warning and success pairs for the "Team answering" and "Resolved" pills. A host theme that defines the same keys supplies its own map and wins.

To override individual roles, spread `defaultAliases` and replace specific keys:

```dart
WindThemeData(
  aliases: {
    ...MagicStarterTokens.defaultAliases,
    'bg-primary': 'bg-indigo-600 dark:bg-indigo-500',
    'text-on-primary': 'text-white dark:text-white',
  },
)
```

<a name="atomic-folder-shape"></a>
## Atomic Folder Shape

Every component lives in a 4-file atomic folder:

```
lib/src/ui/components/<name>/
  <name>.dart          # The widget class (StatelessWidget or StatefulWidget)
  <name>.recipe.dart   # Recipe: resolves className from theme tokens
  <name>.preview.dart  # Standalone preview widget for interactive inspection
  index.dart           # Barrel: re-exports the public API for this component
```

The `.recipe.dart` file holds the recipe: a top-level `WindRecipe` or slot recipe (`badgeRecipe`, `textareaRecipe`), or a function that builds a recipe or a slot-to-className map from a theme or state (`buildButtonRecipe`, `buildInputRecipe`, `buildCardRecipe`, `selectRecipe`). The widget delegates its className derivation to the recipe, so the visual contract is inspectable and testable in isolation.

<a name="component-families"></a>
## Component Families

<a name="form-controls"></a>
### Form Controls

| Component | Enums / Helpers | Notes |
|-----------|----------------|-------|
| `MSButton` | `ButtonIntent` (primary/secondary/ghost/destructive), `ButtonSize` (sm/md/lg), `buildButtonRecipe` | Use `ButtonIntent.destructive` for delete / danger actions; `fullWidth: true` fills the parent width (wraps in `SizedBox`, defaults `false`). Shape, the three sizes and the secondary border come from `MagicStarterButtonTheme` (`MagicStarter.useButtonTheme`). Below `lg`, every size keeps its painted size but takes a 44x44 hit area |
| `MSInput` | `InputState` (normal/error), `buildInputRecipe` | Pairs with `MSFormField` for label + error display; `fullWidth: true` fills the parent width (defaults `false`). A single-line field is 44px tall below `lg` and 40px from `lg` up (`py-3 lg:py-2.5` over a `leading-5` line); the padding and type of the text, placeholder and value come from `MagicStarterFieldTheme.inputSizeClassName` (`MagicStarter.useFieldTheme`) |
| `MSTextarea` | `TextareaState` (normal/error), `textareaRecipe` | Multi-line input, same state model as `MSInput`; `fullWidth: true` fills the parent width (defaults `false`). On iOS a focused field carries a Done toolbar above the keyboard, since a multiline field's Return key inserts a newline and would otherwise leave the keyboard with no way out. One consequence for consumer TESTS: while that toolbar is up it schedules a frame callback every frame, so `pumpAndSettle` under `debugDefaultTargetPlatformOverride = TargetPlatform.iOS` never settles; pump explicitly instead |
| `MSCheckbox` | | Boolean toggle; Wind-only, no Material dependency |
| `MSSwitch` | | Toggle that wraps `WSwitch` with semantic colours. An optional `label` renders beside the track and is part of the tap target; below `lg` the hit area is at least 44 px tall. Shows a focus ring on keyboard focus |
| `MSRadio` | | Single-select option |
| `MSSelect` | `selectRecipe` | Dropdown single-select backed by an item list; the trigger is the same height as `MSInput` (44px below `lg`, 40px from `lg` up), and its padding, minimum height and type come from `MagicStarterFieldTheme.selectSizeClassName` |
| `MSCombobox` | `comboboxRecipe` | Searchable single-select with filter input; the trigger is the same height as `MSInput` (44px below `lg`, 40px from `lg` up) and shares `MagicStarterFieldTheme.selectSizeClassName` with `MSSelect`. The search field's placeholder defaults to `trans('common.search_placeholder')` |
| `MSSwitchRow` | `switchRowRecipe` | An `MSSwitch` with its `label` beside it; the label doubles as the switch's accessibility name |
| `MSKeyValueEditor` | `MSKeyValueRow`, `keyValueEditorRecipe` | Controlled editor for an ordered list of key/value pairs (e.g. HTTP headers); every mutation emits a fresh list |
| `MSStringValueList` | `StringValueListTone`, `stringValueListRecipe` | Controlled editor for a short list of distinct strings rendered as chips; commits on Enter/IME-done, trims and de-duplicates |

<a name="display-and-feedback"></a>
### Display and Feedback

| Component | Enums / Helpers | Notes |
|-----------|----------------|-------|
| `MSBadge` | `BadgeTone` (neutral/primary/accent/success/warning/destructive/outline) | Inline label chip |
| `MSTypography` | `TypographyVariant` (h1/h2/h3/body/caption) | Semantic text wrapper |
| `MSSkeleton` | `SkeletonShape` (block/text/circle) | Placeholder loading block |
| `MSToast` | `ToastVariant` (info/success/warning/error) | Transient feedback banner (the message is `text-sm font-medium`; `messageClassName` is appended after it, so `text-[15px] leading-5 font-normal` sets another body type, with or without an action); presents nothing itself, so the host shows it (through its own `OverlayEntry`) and decides how long it stays. `Magic.toast(String)` cannot carry an action and its overlay ignores pointers, so an action needs the host's own overlay. `actionLabel` and `onAction` (both or neither) add a trailing text action such as Undo: a cell at least 44 px tall and wide at every width (it grows with the label at a large text size), named by `actionLabel` for assistive technology, with a ring inside the toast on keyboard focus. A long message wraps beside it and the action keeps its size; a one line toast is as tall with an action as without |
| `MSTooltip` | | Hover/long-press hint bubble |
| `MSEmptyState` | | Centred placeholder with optional icon, title, description and action |
| `MSErrorState` | | Same slots as `MSEmptyState` with a destructive tone; the retry is whatever `action` widget you pass |
| `MSDataTable` | `MSDataColumn`, `dataTable*ClassName` | Header plus rows, with the columns passed in. Two modes: the default renders `rows` eagerly (right for a short, complete list); `MSDataTable.paginated` hands the body to magic's `MagicPaginatedListView` inside a bounded box, so a long collection costs the viewport rather than the result and reaching the tail asks the paginator for its next page. The header stays outside the scrolling body. `bodyHeight` is what bounds it, since a `ListView` needs a bound and `shrinkWrap: true` would build every row anyway. Column labels and `loadingLabel` are ALREADY TRANSLATED strings, not keys: half the callers render a label that is not a key at all (a currency code, a region name) |

<a name="selection-and-navigation"></a>
### Selection and Navigation

| Component | Enums / Helpers | Notes |
|-----------|----------------|-------|
| `MSSegmentedControl` | `SegmentedControlSize`, `segmentedControlRecipe` | Inline tab switcher; below `lg` each segment is at least 44 px tall to tap, the painted pill unchanged. The pill's padding and type per size and the root's padding come from `MagicStarterFieldTheme` (`segmentedSmClassName`, `segmentedMdClassName`, `segmentedPaddingClassName`); the hit cell is not themed. In a horizontal scroller (the `overflow-x-auto` root override, or your own scroll view that holds nothing but the control) it scrolls the selected segment into view on mount and when `selectedIndex` changes; a page view, a vertical list or a strip with padding or other content around the control is left alone, and the page's vertical scroll never moves |
| `MSTabs` | `tabsRecipe` | Full tab bar with content panels |
| `MSAccordion` | `MSAccordionItem`, `accordionRecipe` | Collapsible section list |
| `MSNavbar` | | Horizontal top navigation bar |
| `MSDropdownMenu` | `MSDropdownMenuItem` | Contextual action menu |

<a name="overlay"></a>
### Overlay

| Component | Notes |
|-----------|-------|
| `MSDialog` | Modal dialog shell; reads `MagicStarterModalTheme` tokens. `scrollable: false` hands a body that scrolls itself the bounded height, as on `MSBottomSheet`. With the modal theme's `presentation: MagicStarterModalPresentation.sheet`, `MSDialog.show` opens the same content as a bottom sheet, and the widget draws the sheet panel inside a bottom sheet route |
| `MSBottomSheet` | Slide-up sheet; reads `MagicStarterModalTheme` tokens. `MSBottomSheet.show(..., dialogBreakpoint: 'lg')` presents an `MSDialog` from that Wind breakpoint up, with the same title, description, body, footer and `scrollable`, so one call serves a phone and a desktop; the width is read when the call is made. Null (the default) always presents a sheet, and so does the `sheet` presentation, which ignores the breakpoint; the `adaptive` presentation ignores it too and swaps at `MagicStarterModalTheme.dialogBreakpoint` for every call. Built in a dialog route (an overlay route under `adaptive`), the widget draws the dialog shell. `canDismiss` (a `ValueListenable<bool>`, read at the gesture) holds a sheet with unsaved input open: while false a drag down is off (the handle stays drawn), and a scrim tap or its semantics dismiss, Back and Escape leave it open and call `onDismissBlocked(sheetContext)`, where the app asks the person and, on a confirmed discard, closes it with `Navigator.of(sheetContext).pop()` (a `pop` skips the guard; the opener's context would pop the wrong navigator, since the sheet sits on the root one); the dialog from `dialogBreakpoint` is held the same way |

<a name="composition-and-app-chrome"></a>
### Composition and App Chrome

| Component | Notes |
|-----------|-------|
| `MSFormField` | Label + input + hint + error layout wrapper |
| `MSCard` | Surface/inset/elevated variants |
| `MSPageHeader` | Full-width responsive header (title, subtitle, leading, actions). Stacked below `sm`, a row above it; `inlineActions` (or `MagicStarterPageHeaderTheme.inlineActions`) makes it a row at every width AND lets a long title shrink instead of overflowing. `size` picks `MSPageHeaderSize.regular`, `.large` (the theme's `largeTitleClassName`, display size on a phone and one step smaller from `lg`) or `.compact` (a 44 pt bar below the top safe area: leading control, centred one-line title, actions, over a translucent fill and a backdrop blur that turn opaque under high contrast). Null follows `MagicStarterPageHeaderTheme.largeTitle`. `className` is appended to the container after the theme's container class, for a page under a bar of its own (`pt-0` or `lg:pt-0` takes the header's top padding off); it styles the regular and the large header, and the compact bar ignores it. Under `MagicStarter.useHostPageChrome`, where the predicate answers true, it draws only its actions and reports its title, subtitle and back control to `MagicStarter.pageChrome` ([host-owned page chrome](../architecture/manager.md#host-page-chrome)) |
| `MSSocialDivider` | "Or continue with" separator for auth forms |
| `MSUserProfileDropdown` | Avatar menu with profile links, theme toggle and logout |
| `MSTeamSelector` | Current-team switcher; requires a registered team resolver |
| `MSPageContainer` | Shared page geometry: width cap, edge margins, vertical rhythm, horizontal safe area. Reads `MagicStarter.manager.pageContainerClassName` |
| `MSPageScaffold` | Full page treatment: page surface + own scroll + `MSPageContainer` + `MSPageHeader` + `gap-6` sections column. `footer` docks a widget below the scroll area, outside it, in the same width and edge margins; it clears the bottom safe area and rides above the on-screen keyboard (a chat composer is the use). A docked layout needs a bounded height, as the app shell provides. `scrollController` hands the scroll area to the page, to keep a thread on its newest message. `containerClassName` is appended to the page container after the host's geometry, for a page under a bar of its own (`pt-4` replaces the host's top padding). `headerClassName` is handed to the regular and the large header the same way (`lg:pt-0` takes the header's own top padding off from `lg` up); the compact bar is built without it. `largeTitle: true` (or `MagicStarterPageHeaderTheme.largeTitle`, which also reaches the starter's own pages) renders a large header that collapses into the compact bar pinned over the page once it has scrolled under it, fading in 200 ms (a swap under Reduce Motion). Under host-owned page chrome it builds neither the large title nor the bar |
| `MSMasterDetail` | A list and its selected item side by side from `breakpoint` (`lg` by default): `master` in a fixed `w-96` column, `detail` (or `placeholder` while it is null) in the rest. Below the breakpoint it renders `detail ?? master`, which is push navigation when the selection lives in the route. Owns no page geometry or scroll, so it goes inside `MSPageScaffold`; `MSMasterDetail.isSplit(context)` gives a page the same answer for its header |
| `MSFormActions` | Cancel/submit footer row for a form; `cancelLabel`/`onCancel` are optional (omitting both renders no cancel button) |
| `MSHeaderAction` | Page-header action that collapses to an icon-only glyph below `lg` and a labelled `MSButton` at `lg` and up; `label` becomes the icon form's accessibility label |

> [!NOTE]
> The bell-icon dropdown is not in this table. It moved to `magic_notifications` as `NotificationDropdown`; see [Notifications](notifications.md).

<a name="import-collisions"></a>
## Import Collisions

Every component class carries an `MS` prefix (`MSButton`, `MSDialog`, `MSSwitch`, ...), so the barrel's component exports do not collide with `package:material_ui/material_ui.dart` (`Switch`, `Dialog`, ...). Import both without a `hide` clause:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:magic_starter/magic_starter.dart';

// No ambiguity: MSSwitch is the component, Switch is Material's.
```

<a name="designmdstub"></a>
## design.md.stub

`assets/stubs/design.md.stub` is a `DESIGN.md` template covering the colour roles, typography, rounded and spacing scales, and key component entries, with `{{ placeholder }}` tokens for the app name, brand colours and font family.

Copy it from the package source into your project root as `DESIGN.md` (a hosted dependency sits in the pub cache; `.dart_tool/package_config.json` lists its `rootUri`), fill in the brand hex values and fonts, then run the core commands:

```bash
# Validate your DESIGN.md against the schema
dart run magic:dowel design:lint

# Generate the Wind theme from your DESIGN.md
dart run magic:dowel design:sync
```

`design:sync` writes a Dart file (`lib/config/wind_theme.g.dart` by default, `--output` changes it) with an alias map for `WindThemeData(aliases: ...)` and a brand `primary` colour ramp. Pass that map where this page passes `MagicStarterTokens.defaultAliases`. See [Magic CLI](https://anilcancakir.com/magic/docs/packages/magic-cli) for the command reference.

<a name="component-previews"></a>
## Component Previews

`package:magic_starter/previews.dart` is a dev-only library, kept out of the runtime barrel. `starterComponentPreviews()` returns one `StarterComponentPreview` record per component: a `label`, a URL-safe `slug` (the component folder name) and a `WidgetBuilder` that renders the component's variants. Feed it to your own preview catalog behind a release guard, so a release build that never reaches the call tree-shakes every preview:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:magic_starter/previews.dart';

List<StarterComponentPreview> catalogPreviews() {
  if (kReleaseMode) return const <StarterComponentPreview>[];

  return starterComponentPreviews();
}

Widget buildPreview(BuildContext context, String slug) {
  final StarterComponentPreview preview = catalogPreviews().firstWhere(
    (StarterComponentPreview entry) => entry.slug == slug,
  );

  return preview.builder(context);
}
```

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Adding a bare role such as `primary` to your `aliases` | Alias keys are full classes (`bg-primary`, `text-fg`, `border-color-border`); Wind expands only a whole token that matches a key. |
| Leaving `aliases` out of the `WindThemeData` | The semantic classes are silently skipped and the components lose their colours. Pass `MagicStarterTokens.defaultAliases` or a `design:sync` map. |
| Calling `useButtonTheme` or `useFieldTheme` before `useWindTheme` | `useWindTheme` resets both, so call them after it. |
| Hardcoding `className: 'py-3 ...'` on an `MSButton` | A caller className is appended after the theme and wins, which breaks a host's button standard; set the shape and sizes through `MagicStarter.useButtonTheme`. |
| Calling `Magic.toast()` to show an `MSToast` with an action | `Magic.toast(String)` carries no action and its overlay ignores pointers; show the `MSToast` through your own `OverlayEntry`. |
| Putting `Icons.*` inline in a `build()` | Extract it to `static const _icon = Icons.xxx`; Flutter web cannot tree-shake an inline icon. |

<a name="related-documentation"></a>
## Related Documentation

- [Views and Layouts](./views-and-layouts.md): the screens these components compose into.
- [Manager](../architecture/manager.md): the sub-themes (`useTheme`, `useButtonTheme`, `useFieldTheme`) and the page container.
- [Wind Theme Adoption](../guides/wind-theme-adoption.md): moving a host's palette onto the semantic aliases.
- [Notifications](./notifications.md): the bell dropdown that lives in `magic_notifications`.
