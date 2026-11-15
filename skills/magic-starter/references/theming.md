# Theming

The screens, layouts and `MS` components read className strings from sub-themes on the manager at build time. Every setter lives on the `MagicStarter` facade and assigns its whole struct.

## Sub-themes

| Setter | Class | Drives |
|:-------|:------|:-------|
| `useNavigationTheme` | `MagicStarterNavigationTheme` | Active and hover nav items, brand (`brandClassName`, or `brandBuilder`, which wins; `compactBrandBuilder` for the icon rail), bottom bar, avatars, nav badge |
| `useModalTheme` | `MagicStarterModalTheme` | Dialog container, title, buttons, inputs; `maxWidth` (448), `presentation`, `dialogBreakpoint` (`'lg'`), `headlessBodyClassName` |
| `useFormTheme` | `MagicStarterFormTheme` | Form inputs (`inputClassName`, also the trigger of the starter's own `WFormSelect`s), labels, buttons, links |
| `useAuthTheme` | `MagicStarterAuthTheme` | Auth card, title, error banner, social divider, guest button |
| `useCardTheme` | `MagicStarterCardTheme` | `MSCard` variants (`surface`, `inset`, `elevated`) |
| `usePageHeaderTheme` | `MagicStarterPageHeaderTheme` | `MSPageHeader` container, title, subtitle; `inlineActions`, `largeTitle` |
| `useLayoutTheme` | `MagicStarterLayoutTheme` | Sidebar, header, drawer, content; `sidebarWidth` (256), `navigationBreakpoint` (`'lg'`), `sidebarExpandedBreakpoint` (`'lg'`), `sidebarCompactWidth` (80) |
| `useDropdownTheme` | `MagicStarterDropdownTheme` | The team switcher and user menu panels; keep a border in `panelClassName` (`border border-transparent` at least), or Wind clips the shadow |
| `useButtonTheme` | `MagicStarterButtonTheme` | `MSButton` shape (`shapeClassName`), the `sm`, `md`, `lg` sizes, the secondary border |
| `useFieldTheme` | `MagicStarterFieldTheme` | The padding, minimum height and type of `MSInput`, `MSSelect`, `MSCombobox`, `MagicStarterTimezoneSelect` and `MSSegmentedControl` |

`useTheme(MagicStarterTheme(...))` sets all of them; `MagicStarterTheme` has `copyWith` for every sub-theme. `useWindTheme(WindThemeData)` is not a `useTheme` call: it derives a theme through `MagicStarterTheme.fromWind(theme)` and merges it onto the fields the host has not set (`manager.applyWindTheme`). A field is the host's when it differs from its sub-theme's default and from what the previous `useWindTheme()` derived; those are kept. The derivation reads the palette's semantic roles (`bg-surface`, `bg-surface-container`, `text-fg`, `text-fg-muted`, `bg-primary`, `text-on-primary`, `border-color-border`, `bg-destructive`, ...), keeps the shipped default for a role the palette does not define, and derives nothing for the button and field themes, so they keep what you set and otherwise stay at their defaults.

## Order

1. `useWindTheme()` or `useTheme()`.
2. Single setters, `useButtonTheme()` and `useFieldTheme()` among them: `useTheme()` resets both, so set them after it. `useWindTheme()` keeps, field by field, what a setter called before it set. A setter called after `useWindTheme()` assigns its whole struct, so build it from the active theme (`MagicStarter.useLayoutTheme(MagicStarter.layoutTheme.copyWith(...))`) or the derived colours it omits go back to their stock defaults. A field set to exactly its stock default, or to exactly what the previous `useWindTheme()` derived for it, reads as unset, and the next `useWindTheme()` replaces it; to keep such a value, set a different one, or set it again after `useWindTheme()` with `copyWith`.
3. One string at a time with `copyWith`: `MagicStarter.useFormTheme(MagicStarter.formTheme.copyWith(inputClassName: ...))`, `MagicStarter.useModalTheme(MagicStarter.modalTheme.copyWith(presentation: ...))`. Every sub-theme has `copyWith`; a new struct hands every omitted field back to its default.

Call them from a provider's `boot()`, before the shell first paints.

## Buttons and fields

- A `className` passed to an `MS` component is appended after the theme and wins on every family it names.
- 44 px comes from vertical padding around a fixed line height (`py-[11px] text-[17px] leading-[22px]`), never `min-h-11` alone: Wind gives the box a minimum height and no alignment, so the label sits at the top.
- A text input paints its border inside its padding and a select trigger adds it, so one `py-*` cannot make both the same height. The auth, profile and settings forms use `WFormInput` on `formTheme.inputClassName`, outside the field theme.
- `secondaryBorderClassName: ''` drops the secondary border; `border-0` still paints a hairline.
- The dialogs and the team invite button draw raw `WButton`s on the modal theme and ignore the button theme.

## Modal presentation

`MagicStarterModalPresentation.dialog` (default) is a centred dialog capped at `maxWidth`; `sheet` opens the starter's modals (`MSDialog.show`, `MSConfirmDialog.show`, the password confirm, step-up and two-factor dialogs) as a bottom sheet at every width; `adaptive` is the sheet below `dialogBreakpoint` and the dialog from it, and also applies to `MSBottomSheet.show` and to overlay routes through `MagicRoute.useOverlayPresentation`. `UpgradePrompt` opens through magic's `MagicFeedback.showCustomDialog` and stays a dialog. `MagicStarterBreakpoints.isAtLeast` throws `StateError` for a breakpoint name the Wind theme lacks.

## Tokens

`MagicStarterTokens.defaultAliases` is the semantic alias map the components resolve (`bg-surface`, `text-fg`, `text-fg-muted`, `bg-primary`, `text-on-primary`, `border-color-border`, `bg-destructive`, `bg-success`, `bg-warning`, ...). Pass it, or your own map with the same keys, as `WindThemeData(aliases: ...)`. Each alias carries its own `dark:` pair. An unknown alias is dropped silently: assert a resolved colour in a test, never the className string. `MagicStarterTokens.role(theme, 'text-destructive')` resolves a role the alias set does not ship with a fallback pair.
