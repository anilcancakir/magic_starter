# Controllers

The starter's controllers hold the business logic and async state behind each screen: every view delegates its API calls, state transitions and navigation to a paired controller.

- [Introduction](#introduction)
- [Lazy Singleton Pattern](#lazy-singleton-pattern)
- [MagicController and MagicStateMixin](#magiccontroller-and-magicstatemixin)
- [Controller Lifecycle](#controller-lifecycle)
- [View Binding](#view-binding)
- [Fine-Grained Reactivity](#fine-grained-reactivity)
- [Consumer Apps](#consumer-apps)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

A view renders state and forwards user input; the controller calls the backend, moves the state machine and navigates. Controllers live in `lib/src/http/controllers/` and are exported from `package:magic_starter/magic_starter.dart`. They share two small mixins from `concerns/`:

| Mixin | Provides |
|:------|:---------|
| `NavigatesRoutes` | `navigateTo(path, {query})` and `navigateHome()`, which are no-ops while no navigator is mounted and send the user to the intended URL or `routes.home` |
| `CompletesSignIn` | `completeSignIn(...)`, the one way a sign-in concludes (password, social, two-factor challenge, OTP, guest, handoff), which also announces a cancelled account deletion |

Notification preferences state moved with the notification UI: `NotificationPreferencesController` lives in `magic_notifications` and follows the same lazy-singleton shape.

<a name="lazy-singleton-pattern"></a>
## Lazy Singleton Pattern

A controller exposes one static accessor that delegates instantiation to the Magic container:

```dart
class MagicStarterAuthController extends MagicController
    with MagicStateMixin<bool>, ValidatesRequests, NavigatesRoutes, CompletesSignIn {
  static MagicStarterAuthController get instance =>
      Magic.findOrPut(MagicStarterAuthController.new);
}
```

`Magic.findOrPut` checks whether a binding for the controller's runtime type exists. On first access it calls the tear-off constructor, stores the result and returns it; every later call returns the cached instance. A controller is created only when first needed and lives as long as the container.

| Controller | State mixin | Also |
|:-----------|:------------|:-----|
| `MagicStarterAuthController` | `MagicStateMixin<bool>` | `ValidatesRequests`, `NavigatesRoutes`, `CompletesSignIn` |
| `MagicStarterOtpController` | `MagicStateMixin` | `ValidatesRequests`, `NavigatesRoutes`, `CompletesSignIn` |
| `MagicStarterGuestAuthController` | `MagicStateMixin<bool>` | `ValidatesRequests`, `NavigatesRoutes`, `CompletesSignIn` |
| `MagicStarterHandoffController` | none | `NavigatesRoutes`, `CompletesSignIn`, `SessionScoped` |
| `MagicStarterProfileController` | `MagicStateMixin<bool>` | `ValidatesRequests`, `NavigatesRoutes` |
| `MagicStarterNewsletterController` | `MagicStateMixin` | `ValidatesRequests` |
| `MagicStarterAnalyticsPreferenceController` | `MagicStateMixin` | `ValidatesRequests`, `SessionScoped` |
| `MagicStarterReleasesController` | `MagicStateMixin<MagicStarterReleaseFeed>` | none |
| `MagicStarterTeamController` | `MagicStateMixin<bool>` | `ValidatesRequests`, `SessionScoped` |
| `MagicStarterSupportController` | none | `ValidatesRequests`, `SessionScoped` |
| `MagicStarterFeedbackController` | none | `ValidatesRequests`, `SessionScoped` |

Each has a static `instance` accessor like the one above. `MagicStarterBillingController` is the exception: it takes required collaborators (the usage copy and number formatter), so there is no zero-argument constructor for `findOrPut` to call, and the host registers it with `Magic.put(...)`; see [Teams](../basics/teams.md).

> [!NOTE]
> `Magic.findOrPut` is distinct from `Magic.singleton`. `singleton` registers a factory under a string key so the container can resolve it by name. `findOrPut` uses the concrete type as the implicit key and creates the instance on first access, with no upfront registration.

<a name="magiccontroller-and-magicstatemixin"></a>
## MagicController and MagicStateMixin

Every starter controller extends `MagicController`, which extends `ChangeNotifier`, so each one is a `Listenable`. Most add `MagicStateMixin<T>`, a typed state machine on top of it:

| Member | Description |
|:-------|:------------|
| `setLoading()` | Moves to the loading state and notifies listeners |
| `setSuccess(T value)` | Moves to success with a typed payload |
| `setError(String message)` | Moves to error with a message |
| `setEmpty()` | Resets to the empty (idle) state |
| `isLoading`, `isSuccess`, `isError`, `isEmpty` | The current state |
| `renderState(onSuccess, {onLoading, onError, onEmpty})` | A widget factory that dispatches on the current state |

`T` is the success payload type. `MagicStateMixin<bool>` is the common choice because most controllers only signal success or failure. `clearErrors()` and `hasErrors` come from the `ValidatesRequests` mixin and concern the field validation errors a backend 422 sets, not the state machine.

A standard async action:

```dart
Future<void> doLogin({
  required String password,
  String? email,
}) async {
  setLoading();
  clearErrors();

  try {
    final response = await Http.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    if (!response.successful) {
      handleApiError(response, fallback: trans('auth.login_failed'));
      return;
    }

    // ... complete the sign-in
  } catch (e, stackTrace) {
    Log.error('[doLogin] $e\n$stackTrace');
    setError(trans('errors.unexpected'));
  }
}
```

A throw before the response (a timeout, a dropped connection) would leave the controller in the loading state, so the action catches it, logs it and sets an error state. `MagicStarterAuthController.doLogin` also maps a timeout and a socket failure to their own messages.

> [!TIP]
> Call `setLoading()` and `clearErrors()` at the top of an async action, before the first `await`. The view gets immediate feedback and stale errors from the previous run are gone.

<a name="controller-lifecycle"></a>
## Controller Lifecycle

Because `findOrPut` stores the instance in the container, a controller outlives any view. Navigate away from the login screen and back and `MagicStarterAuthController.instance` is the same object.

- The controller's own `onInit()` runs once per instance lifetime, the first time it backs a view, not on every mount.
- The view state's `onInit()` runs on every mount. When a view mounts, magic clears the controller's validation errors and turns an error status back to empty without notifying, so a failed attempt does not greet the next visit. A controller still holds its other state (a success value, `ValueNotifier` contents) between visits: reset what you need in the view's `onInit()`.
- A controller that caches data of one signed-in user or team implements magic's `SessionScoped`, so a sign-out or a team switch resets it. The team, support, feedback, handoff, billing and analytics preference controllers do; see [Session Scope](../basics/session-scope.md).
- `ValueNotifier` fields are disposed with the controller. In tests call `controller.dispose()` in `tearDown`.
- `Magic.flush()` or `MagicApp.reset()` replaces the container; the next `findOrPut` builds a fresh instance. That is the test isolation mechanism.

<a name="view-binding"></a>
## View Binding

Every page-level view extends `MagicStatefulView<ControllerType>`. The state class resolves the controller with `Magic.find<T>()`, so the controller has to be registered first: the starter's routes do it by calling `instance` (or `Magic.findOrPut`) in the route builder, before the view mounts. The controller is then available through the `controller` getter.

```dart
class MagicStarterLoginView
    extends MagicStatefulView<MagicStarterAuthController> {
  const MagicStarterLoginView({super.key});

  @override
  State<MagicStarterLoginView> createState() => _MagicStarterLoginViewState();
}

class _MagicStarterLoginViewState extends MagicStatefulViewState<
    MagicStarterAuthController, MagicStarterLoginView> {
  late final form = MagicFormData(
    {'email': '', 'phone': '', 'password': '', 'remember_me': false},
    controller: controller,
  );

  @override
  void onInit() {
    controller.clearErrors();
    controller.setEmpty();
  }

  @override
  void onClose() => form.dispose();

  @override
  Widget build(BuildContext context) {
    return controller.renderState(
      (_) => _buildForm(),
      onEmpty: _buildForm(),
      onLoading: _buildForm(),
      onError: (message) => _buildForm(errorMessage: message),
    );
  }
}
```

| Hook | Called when | Typical use |
|:-----|:------------|:------------|
| `onInit()` | After `initState()`, on every mount | Reset controller state, start the first load |
| `onClose()` | In `dispose()` | Dispose a `MagicFormData`, cancel subscriptions |

The view subscribes to the controller through `ChangeNotifier` and calls `setState` on every `notifyListeners`, so `renderState` always shows the latest state without manual subscription code. The login form renders itself in the loading state too (`onLoading`), because the form group must outlive the request.

<a name="fine-grained-reactivity"></a>
## Fine-Grained Reactivity

`MagicStateMixin` notifies on every transition, which rebuilds the whole view listening to the controller. For a view with several independently loading sections that can flicker. The cure is one `ValueNotifier` per section. The team controller keeps its member and invitation lists that way:

```dart
final ValueNotifier<List<Map<String, dynamic>>> members = ValueNotifier([]);
final ValueNotifier<List<Map<String, dynamic>>> invitations = ValueNotifier([]);
```

and the team settings view wraps only the section that depends on one:

```dart
ValueListenableBuilder<List<Map<String, dynamic>>>(
  valueListenable: controller.members,
  builder: (context, members, _) => _buildMembers(members),
)
```

The builder rebuilds only its own subtree when `members.value` changes.

`MagicStarterProfileController` adds `withoutNotifying()`, which suppresses full-page notifications while a section-level action drives its own loading indicator through `MagicFormData.process`:

```dart
await form.process(() => controller.withoutNotifying(
  () => controller.doUpdateProfile(name: 'Alice', email: 'a@example.com'),
));
```

The suppression is a depth counter, so two overlapping actions do not un-suppress each other.

<a name="consumer-apps"></a>
## Consumer Apps

An app building its own features on top of the starter follows the same conventions: a lazy `instance` accessor, `MagicStateMixin`, a view on `MagicStatefulView`. The registration options (lazy, eager in `boot()`, per-view `ChangeNotifier`), the view patterns and the test setup are in [State Management](../guides/state-management.md).

<a name="related-documentation"></a>
## Related Documentation

- [State Management](../guides/state-management.md): writing your own controller on the same pattern.
- [Service Provider](service-provider.md): the bootstrap, IoC bindings and Gate abilities.
- [Manager](manager.md): the singleton holding every customisation registration.
- [Session Scope](../basics/session-scope.md): resetting session-scoped controllers.
- [Views and Layouts](../basics/views-and-layouts.md): the `MagicStatefulView` lifecycle and rendering conventions.
- [Magic controllers](https://anilcancakir.com/magic/docs/basics/controllers): `MagicController` and `MagicStateMixin` in core.
