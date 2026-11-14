# Teams

Create teams, switch between them, invite members and manage team settings through `MagicStarterTeamController`, with a team resolver that bridges your own team model to the starter.

- [Basic Usage](#basic-usage)
- [Team Resolver](#team-resolver)
- [Creating Teams](#creating-teams)
- [Team Switching](#team-switching)
- [Billing](#billing)
    - [The Billable Subject](#the-billable-subject)
    - [Price Format](#price-format)
    - [Free Trials](#free-trials)
    - [Changing a Web Plan](#changing-a-web-plan)
    - [Campaigns](#campaigns)
- [Invitations](#invitations)
    - [Sending Invitations](#sending-invitations)
    - [Accepting Invitations](#accepting-invitations)
    - [Cancelling Invitations](#cancelling-invitations)
- [Team Settings](#team-settings)
    - [Updating the Team Name](#updating-the-team-name)
    - [Managing Members](#managing-members)
- [Controller](#controller)
- [Overriding a View](#overriding-a-view)
- [MSTeamSelector](#msteamselector)
- [MagicStarterTeam](#magicstarterteam)
- [Gotchas](#gotchas)
- [Related Documentation](#related-documentation)

<a name="basic-usage"></a>
## Basic Usage

Turn the feature on in `lib/config/magic_starter.dart`, register the routes from your route provider and register a team resolver (see [Team Resolver](#team-resolver)):

```dart
'features': {
  'teams': true,
},
```

```dart
registerMagicStarterAuthRoutes();
registerMagicStarterTeamRoutes();
```

With `teams` off, `registerMagicStarterTeamRoutes()` is a no-op and the default team views are not registered. The routes sit under `MagicStarterConfig.teamsPrefix()` (`magic_starter.routes.teams_prefix`, default `/teams`), behind the `auth` middleware alias, inside the `layout.app` shell.

| Registry key | View | Route |
|:-------------|:-----|:------|
| `teams.create` | `MagicStarterTeamCreateView` | `MagicStarterConfig.teamCreateRoute()` (`/teams/create`) |
| `teams.settings` | `MagicStarterTeamSettingsView` | `MagicStarterConfig.teamSettingsRoute()` (`/teams/settings`) |
| `teams.invitation_accept` | `MagicStarterTeamInvitationAcceptView` | `/invitations/:token/accept` |
| `teams.billing` | `MagicStarterBillingView` | Registered by the `billing` feature alone, with no route of its own: your route provider points `MagicStarterConfig.billingRoute()` (`/teams/billing`) at `MagicStarter.view.make('teams.billing')` |

Create and settings are pushed (`.stacked()`), so the back gesture returns to the team switcher. Invitation acceptance is an arrival from an email link, so it is not stacked. The backend side is `magic-starter-laravel`'s `teams` feature; turn on both.

<a name="team-resolver"></a>
## Team Resolver

The team resolver is the bridge between your application's team model and the starter. Register it during app boot with `MagicStarter.useTeamResolver()`:

```dart
MagicStarter.useTeamResolver(
  currentTeam: () => User.current.currentTeam?.toMagicStarterTeam(),
  allTeams: () => User.current.allTeams
      .map((t) => t.toMagicStarterTeam())
      .toList(),
  onSwitch: (id) => MagicStarter.switchTeam('$id'),
);
```

| Callback | Return type | Purpose |
|:---------|:------------|:--------|
| `currentTeam` | `MagicStarterTeam?` | The user's active team |
| `allTeams` | `List<MagicStarterTeam>` | Every team the user belongs to |
| `onSwitch` | `Future<void>` | Called when the user picks a different team |

The starter reads these callbacks to fill the team selector, show the active team name and handle switching. Register the resolver in your service provider's `boot()`, before any team UI renders. `MagicStarter.bootstrap()` takes the same three callbacks and throws a `StateError` when `teams` is on and none are passed (an `ArgumentError` when only some are).

<a name="creating-teams"></a>
## Creating Teams

```dart
final success = await MagicStarterTeamController.instance.doCreate(
  name: form.get('name'),
);
```

The controller sends `POST /teams` with the team name. With the new team's `id` it then sends `PUT /user/current-team`, stores the id in `currentTeamId.value` and applies the user that answer carries (falling back to `Auth.restore()`), so the sidebar names the new team. A toast confirms the creation.

<a name="team-switching"></a>
## Team Switching

Switch the active team with `MagicStarter.switchTeam()`, which answers whether the backend accepted it:

```dart
if (!await MagicStarter.switchTeam(teamId)) return;

MagicRoute.to('/projects/$projectId');
```

It goes through `MagicStarterTeamController.instance.switchTeam()`, which sends `PUT /user/current-team` with the target `team_id` and, on success, updates `currentTeamId.value` and applies the signed-in user the switch answers with, so the session is on the new team before the future completes. An answer without that user (an empty `data`, a team record) falls back to `Auth.restore()`. In an app that never calls `SessionScope.attach()`, the switch also resets every `SessionScoped` controller registered with `Magic` (see [Session Scope](./session-scope.md)). A refused switch answers `false` and leaves the session on the team it was on, so a caller that navigates after a switch must check the answer first.

On success it also re-identifies the store rail as the paying subject (`StoreIdentitySync.syncNow()` from `magic_payments`), so a purchase made after the switch is not attributed to the team that was left. A build without a store rail (web, desktop) identifies nothing, and a refused switch identifies nothing.

Pass `MagicStarter.switchTeam` as the resolver's `onSwitch` so the team selector gets the same behaviour. `MagicStarter.currentTeamId()` answers the active team's id as a string (`null` without a resolver or an active team), so an int id from your model and a string id from a link or a push payload compare equal.

<a name="billing"></a>
## Billing

The billing screen (`teams.billing`, with the `billing` feature) sells plans through `magic_payments`: Stripe on the web, the store on mobile. It needs `magic_starter.billing.web_origin`, an absolute url, for the web rail; its absence fails silently at Stripe.

### The Billable Subject

`magic_starter.billing.billable` names what a store purchase is billed to, and it mirrors `magic-starter-laravel`'s key of the same name. The two must agree:

| Value | The store rail is identified as |
|:------|:--------------------------------|
| `'user'` (default) | `Auth.id()` |
| `'team'` | The active team id |

```dart
'billing': {
  'web_origin': 'https://app.example.com',
  'billable': 'team',
},
```

`MagicStarterServiceProvider` reads it at boot and sets `StoreIdentitySync.billableId`; any other value refuses the boot with a `StateError`, because a typo that fell back to `'user'` would bind every purchase to the wrong subject. Identifying on login and restore as well stays your call: add `StoreIdentitySync.attach()` to your provider's `boot()`.

### Price Format

Every web price the billing screen shows reads the producer's `display` string, such as `379.00 TRY`, which carries no separator and no symbol. An app that writes money its own way registers a `MagicStarterPriceFormat` on the controller:

```dart
Magic.put(
  MagicStarterBillingController(
    usageCopy: usageCopy,
    formatNumber: Number.format,
    formatPrice: (MagicStarterWebPrice price) => switch (price.currency) {
      'TRY' => '${Number.format(price.amountMinor / 100)} TL',
      _ => price.display,
    },
  ),
);
```

`MagicStarterWebPrice` carries `amountMinor` (in the currency's minor unit), `currency` (the ISO 4217 code) and `display`. Return `price.display` for any currency the app does not format itself. `usageCopy` is your own `MagicStarterUsageCopy`; the controller takes required collaborators, so it is registered with `Magic.put` rather than `findOrPut`.

### Free Trials

The billing screen shows a trial and a store introductory offer without further setup, provided the backend's catalogue rows carry `trial_days` per product. `MagicStarterProduct.trialDays` is the free days a purchase of that product starts with, and `0` for none. The backend answers it for the signed-in caller, so `0` also means a trial already used. `MagicStarterBillingController.trialEnd` is the date a running trial ends (`null` unless the plan status is `trialing`); a store trial has no `trial_ends_at`, so it falls back to the entitlement's current period end.

| Where | What it shows |
|:------|:--------------|
| Current plan card | A "Trial" badge beside the plan name, and one line in place of the renewal line saying when the trial ends and what is billed after it (or that it will not renew once cancelled) |
| Web plan card | For a product with `trialDays` above zero, "Free for :period. Card required, then :price per :cycle." above the call to action, which reads "Start free trial". Web build only |
| Store plan card | "Free for :intro_period, then :price per :period" for a free introductory offer, only when the store says this customer is eligible (`StoreProductOffer.introEligible`) |

The translator has no plural API, so each count is chosen in Dart: a count of one reads the `_one` key and any other count the `_other` key. A store introductory period is read from its ISO 8601 form when it is one whole unit (`P14D`, `P2W`, `P1M`, `P1Y`); anything else (`P1Y2M`) states no offer and keeps the plain line.

### Changing a Web Plan

A team that already holds a web (Stripe) subscription changes tier or cycle by moving that subscription, never by buying a second one: `magic-starter-laravel` refuses a checkout with a 409 `subscription_exists` while one still grants. `MagicStarterBillingController.holdsWebSubscription` is `true` once the entitlement names `BillingProvider.stripe` with a plan status that still grants (`trialing`, `active`, `pastDue`, `grace`), and while it is, a tap on another paid tier opens a confirmation instead of a checkout. On confirm the screen calls `WebBillingService.swap(productKey:)` (`POST /billing/swap`), re-reads the payment method and the invoices, and polls the entitlement with `awaitEntitlementChange(before)`, because the backend answers the swap before Stripe's webhook writes the new tier. A team with no web subscription still goes through the hosted checkout, and the move to the free tier still opens the billing portal.

The confirmation states what the backend does with the money:

| Move | The sentence |
|:-----|:-------------|
| During a running trial | Nothing is charged until the trial ends |
| A higher tier, or a held tier the catalogue cannot rank | The card on file is charged the prorated difference now |
| A lower tier on another cycle | The new billing period is billed at once, less the unused time on the current plan |
| A lower tier on the same cycle | The change applies now and the unused time is credited to the next invoice |

An upgrade the card declines, or one the bank asks to confirm with 3D Secure, is refused with a 402, which `magic_payments` reports as `BillingErrorCode.paymentDeclined` and `paymentRequiresAction`; the toast says the plan has not changed and why.

### Campaigns

A staff-run, time-boxed offer on `magic-starter-laravel` (`GET /billing/campaign`) reaches a floor-tier team owner on the web rail as an app-wide banner and a tag on the plan cards it discounts. The backend answers `{"data": null}` unless the caller is the audience, so nothing here decides who qualifies; the client only declines to ask when it could not act on the offer.

`MagicStarterBillingController.loadCampaign()` reads the offer. It is separate from `load()` and asks only when the `billing` feature is on and `canPurchaseViaWeb` holds (a web rail, no store managing the subscription, not a known non-owner). The answer lives on the controller as `campaign`, a `MagicStarterCampaign` (`id`, `startsAt`, `endsAt`, `products`, `discount`, and `headlineFor(languageCode)` and `bodyFor(languageCode)`, which pick the app locale, then `magic_starter.defaults.locale`, then any copy the backend sent). A team switch or a sign-in clears it and the mounted banner asks again. The backend answers 404 when its `campaigns` feature is off, which is read as no campaign and logs nothing; any other failed read is logged as a warning.

| Where | What it shows |
|:------|:--------------|
| `MagicStarterCampaignBanner` | The headline and body above every page, a "See plans" action to `MagicStarterConfig.billingRoute()` and a "Dismiss" action. `MagicStarterAppLayout` mounts it when `billing` is on; a host that maps `layout.app` to its own layout places it itself. It hides itself once `endsAt` has passed |
| Plan card | For a card whose product at the selected billing cycle is in the campaign, a "Limited offer" tag and the discount under the card's price. The tag follows the cycle toggle, and a fixed-amount discount tags only a card priced in the campaign's own currency or one the coupon lists in `currency_options`. The billing screen reads the campaign itself, so a host without the banner still gets the tag |

"Dismiss" stores the campaign id in the `Vault` under `MagicStarterCampaignBanner.dismissalKey()`, which is `dismissedCampaignKey` plus the signed-in account's id, so a second account on the same device does not inherit the first one's dismissal. The next campaign has a new id and shows again. A fixed-sum discount passes through the app's `MagicStarterPriceFormat` when one is registered; otherwise it is written the producer's way (`5.00 USD`), which assumes a currency with two decimals.

The package ships English copy only. The headline and body come from the backend per language; the labels are keys under `magic_starter.billing` in `assets/stubs/install/en.stub`, and an app that published its own `en.json` adds new keys by hand.

<a name="invitations"></a>
## Invitations

### Sending Invitations

Invite a member to the current team by email and role:

```dart
final success = await MagicStarterTeamController.instance.doInvite(
  email: 'colleague@example.com',
  role: 'member',
);
```

The controller sends `POST /teams/{teamId}/invitations` and refreshes the lists with `loadMembersAndInvitations()` on success. The team id is `activeTeamId`: the explicit `currentTeamId.value`, else the resolver's `currentTeam()`. With neither, the controller sets an error and returns `false`. The shipped settings view offers the roles `member` and `admin`.

### Accepting Invitations

Accept an invitation with the token from the invitation URL:

```dart
final success = await MagicStarterTeamController.instance.doAcceptInvitation(
  token: invitationToken,
);
```

This sends `POST /invitations/{token}/accept` and, on success, calls `Auth.restore()` so the user model includes the new team. The accept view (`teams.invitation_accept`) reads the token from its own route once, in `didChangeDependencies`, because route state cannot be read in `initState`:

```dart
_token ??= MagicRouter.instance.pathParameterOf(context, 'token');
```

The static `pathParameter()` would answer for whichever page was built last, which across layout shells is not always this one.

### Cancelling Invitations

Cancel a pending invitation (a team admin action):

```dart
final success = await MagicStarterTeamController.instance.cancelInvitation(
  invitationId,
);
```

This sends `DELETE /teams/{teamId}/invitations/{invitationId}`.

<a name="team-settings"></a>
## Team Settings

### Updating the Team Name

```dart
final success = await MagicStarterTeamController.instance.doUpdate(
  name: form.get('name'),
);
```

This sends `PUT /teams/{teamId}` and calls `Auth.restore()` on success.

### Managing Members

```dart
await MagicStarterTeamController.instance.loadMembersAndInvitations();
```

This fires `GET /teams/{teamId}/members` and `GET /teams/{teamId}/invitations` together and stores the results in the `members` and `invitations` notifiers. A newer read for another team supersedes an older one, so a slow answer never lands on the wrong team's screen.

```dart
final removed = await MagicStarterTeamController.instance.removeMember(memberId);
```

This sends `DELETE /teams/{teamId}/members/{memberId}` and updates the local `members` list.

<a name="controller"></a>
## Controller

`MagicStarterTeamController.instance` is the singleton. It implements `SessionScoped`: a login or a team switch drops its members and invitations and re-points `currentTeamId` at the resolver's current team.

| Member | Type | Purpose |
|:-------|:-----|:--------|
| `currentTeamId` | `ValueNotifier<dynamic>` | An explicitly set team id; overrides the resolver |
| `members` | `ValueNotifier<List<Map<String, dynamic>>>` | The current team's members |
| `invitations` | `ValueNotifier<List<Map<String, dynamic>>>` | Pending invitations |
| `activeTeamId` | `dynamic` | `currentTeamId.value`, else the resolver's `currentTeam()` id |
| `activeTeamName` | `String?` | The name matching `activeTeamId`, from the resolver |

Use `ValueListenableBuilder` on `members` and `invitations` for fine-grained rebuilds. The controller's `dispose()` disposes all three notifiers, so dispose it in test `tearDown()`.

<a name="overriding-a-view"></a>
## Overriding a View

Every team screen resolves through the view registry, so a host replaces one by registering a builder under the same key:

```dart
MagicStarter.view.register('teams.settings', () => const MyTeamSettingsView());
```

<a name="msteamselector"></a>
## MSTeamSelector

A dropdown built from the resolver's callbacks. It lists the user's teams and calls `onSwitch` when the selection changes:

```dart
const MSTeamSelector()
```

Pass `compact: true` for an icon-only trigger. It renders nothing without a registered resolver or with an empty `allTeams()`. The shipped app layout places it in the sidebar; a host layout places it where it wants.

<a name="magicstarterteam"></a>
## MagicStarterTeam

A lightweight team DTO (`id`, `name`, `photoUrl`, `isPersonalTeam`) that bridges your app's team model with the starter. `MagicStarterTeam.fromMap()` normalises a backend map, including a `personal_team` that arrives as `true` or `1`. Give your own model a conversion:

```dart
extension on Team {
  MagicStarterTeam toMagicStarterTeam() {
    return MagicStarterTeam(
      id: id,
      name: name,
      photoUrl: profilePhotoUrl,
      isPersonalTeam: personalTeam,
    );
  }
}
```

<a name="gotchas"></a>
## Gotchas

| Mistake | Fix |
|:--------|:----|
| Enabling `teams` without a team resolver | Register `MagicStarter.useTeamResolver()`, or pass the callbacks to `MagicStarter.bootstrap()`. The selector and the current team name read it. |
| Navigating after `switchTeam` without reading the answer | A refused switch answers `false` and leaves the session on the old team; check it first. |
| Calling `Auth.restore()` in your own switch path | Apply the switch answer's user directly, as the controller does, or the session identity flips late. |
| Setting `billable: 'team'` on one side only | `magic_starter.billing.billable` and the backend key of the same name must agree. Any value other than `'user'` or `'team'` refuses the boot. |
| Forgetting `billing.web_origin` | The web checkout needs an absolute url; without it Stripe fails silently. |
| Expecting `members` and `invitations` to refill after a team switch | The controller refetches them only while a settings screen is mounted. Call `loadMembersAndInvitations()` from your own screen. |

<a name="related-documentation"></a>
## Related Documentation

- [Session Scope](./session-scope.md): what resets when the team changes.
- [Profile](./profile.md): the settings hub and account pages.
- [Authentication](./authentication.md): sign-in and `Auth.restore()`.
- [Views and Layouts](./views-and-layouts.md): the view registry and the app shell.
- [Configuration](../getting-started/configuration.md): the `teams` and `billing` flags and keys.
