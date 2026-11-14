# State Management

How to write a controller in your own app on the same pattern the starter's controllers use: `MagicController`, `MagicStateMixin`, a lazy `instance` accessor and a `MagicStatefulView`.

- [Introduction](#introduction)
- [Creating a State Class](#creating-a-state-class)
    - [Extend MagicController](#extend-magiccontroller)
    - [Add the Singleton Accessor](#add-the-singleton-accessor)
    - [Implement Async Methods](#implement-async-methods)
- [Registration Decision Tree](#registration-decision-tree)
- [Connecting State to Views](#connecting-state-to-views)
    - [Pattern A: MagicStatefulView](#pattern-a-magicstatefulview)
    - [Pattern B: StatefulWidget + Manual Access](#pattern-b-statefulwidget--manual-access)
- [Testing](#testing)
- [Complete Example](#complete-example)
- [Related Documentation](#related-documentation)

<a name="introduction"></a>
## Introduction

The model has three parts, all from the Magic framework:

1. **`MagicController`**: the base class. It extends `ChangeNotifier` and carries the `onInit()` and `onClose()` lifecycle.
2. **`MagicStateMixin<T>`**: a four-state machine (loading, success, error, empty) driven by `setLoading()`, `setSuccess()`, `setError()` and `setEmpty()`, rendered with `renderState()`.
3. **The container**: `Magic.findOrPut()` returns the existing instance of a controller type or creates and registers one.

`dart run magic:dowel make:controller Project` generates a controller of this shape; see the [Magic CLI](https://anilcancakir.com/magic/docs/packages/magic-cli). Views bind to the controller's `instance` accessor and call `renderState()` to choose what to draw. How the starter applies the pattern is in [Controllers](../architecture/controllers.md).

<a name="creating-a-state-class"></a>
## Creating a State Class

<a name="extend-magiccontroller"></a>
### Extend MagicController

```dart
import 'package:magic/magic.dart';

class ProjectController extends MagicController
    with MagicStateMixin<List<Map<String, dynamic>>> {
  // ...
}
```

The type parameter of `MagicStateMixin<T>` is the value passed to `setSuccess(value)`: a list for collections, `bool` for form submissions, a model class for a single resource.

<a name="add-the-singleton-accessor"></a>
### Add the Singleton Accessor

```dart
class ProjectController extends MagicController
    with MagicStateMixin<List<Map<String, dynamic>>> {
  static ProjectController get instance =>
      Magic.findOrPut(ProjectController.new);
}
```

`Magic.findOrPut(ProjectController.new)` returns the registered `ProjectController` if there is one; otherwise it calls the constructor tear-off, registers the result and returns it. Every view that calls `ProjectController.instance` gets the same object.

> [!NOTE]
> Never call `ProjectController()` in a view: the `instance` accessor is what shares one state across views. Tests are the exception, see [Testing](#testing).

<a name="implement-async-methods"></a>
### Implement Async Methods

Each async action follows one lifecycle:

1. Guard against re-entrant calls with a flag.
2. Call `setLoading()`.
3. Make the HTTP call with `Http.get()`, `Http.post()` and the like.
4. Call `setSuccess(value)` (or `setEmpty()` for an empty result) on the happy path, `setError(message)` on failure.
5. Reset the guard in `finally`.

```dart
class ProjectController extends MagicController
    with MagicStateMixin<List<Map<String, dynamic>>> {
  static ProjectController get instance =>
      Magic.findOrPut(ProjectController.new);

  bool _isLoading = false;

  /// Fetches all projects and exposes them through the state machine.
  Future<void> loadProjects() async {
    if (_isLoading) return;
    _isLoading = true;
    setLoading();

    try {
      final response = await Http.get('/api/projects');

      if (!response.successful) {
        setError('Failed to load projects.');
        return;
      }

      final data = response.data['data'];
      final projects = data is List
          ? data.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      if (projects.isEmpty) {
        setEmpty();
        return;
      }

      setSuccess(projects);
    } catch (e, stackTrace) {
      Log.error('[ProjectController.loadProjects] $e\n$stackTrace');
      setError('An unexpected error occurred.');
    } finally {
      _isLoading = false;
    }
  }
}
```

| Method | Resulting state | Read with |
|:-------|:----------------|:----------|
| `setLoading()` | loading | `isLoading` |
| `setSuccess(value)` | success, `value` available | `isSuccess`, `rxState` |
| `setError(message)` | error, message stored | `isError` |
| `setEmpty()` | empty | `isEmpty` |

`clearErrors()` and `hasErrors` belong to the separate `ValidatesRequests` mixin, which a controller adds when it submits forms the backend validates.

A controller that caches the rows of one signed-in user or team also implements magic's `SessionScoped`, so a sign-out or a team switch cannot leave the previous session's rows on screen; see [Session Scope](../basics/session-scope.md).

<a name="registration-decision-tree"></a>
## Registration Decision Tree

```
Does the controller need to be ready before any view renders?
│
├─ YES → Register eagerly in AppServiceProvider.boot()
│        Magic.findOrPut(ProjectController.new);
│        Views resolve the same singleton
│
└─ NO  → Use lazy findOrPut() (default pattern)
         static ProjectController get instance =>
             Magic.findOrPut(ProjectController.new);
         The first access registers it

         Is the controller shared across multiple views?
         │
         ├─ YES → findOrPut(): the same singleton everywhere
         │
         └─ NO  → Consider a plain StatefulWidget with a local ChangeNotifier
                  (no container involvement for purely local state)
```

| Scenario | Registration | Example |
|:---------|:-------------|:--------|
| Data needed right after sign-in (a badge count in the navigation) | Eager, `AppServiceProvider.boot()` | A controller that polls from boot |
| Feature data (a project list, a report) | Lazy, `findOrPut()` | `ProjectController`, loaded when its screen mounts |
| Single-view transient state (a modal open or closed) | Local `ChangeNotifier` | No container |

> [!TIP]
> Prefer the lazy pattern for feature controllers. Eager registration is for data that has to exist before any view asks for it.

<a name="connecting-state-to-views"></a>
## Connecting State to Views

<a name="pattern-a-magicstatefulview"></a>
### Pattern A: MagicStatefulView

Use `MagicStatefulView<ControllerType>` for full-page views. Its state class gets `controller` from `Magic.find<ControllerType>()`, which throws when the controller was never registered, and it listens to the controller for you. So register the controller before the view mounts: call `instance` in the route builder.

```dart
MagicRoute.page('/projects', () {
  ProjectController.instance; // registers the controller before the view mounts
  return const ProjectListView();
});
```

```dart
import 'package:material_ui/material_ui.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

class ProjectListView extends MagicStatefulView<ProjectController> {
  const ProjectListView({super.key});

  @override
  State<ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState
    extends MagicStatefulViewState<ProjectController, ProjectListView> {
  @override
  void onInit() {
    controller.loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return controller.renderState(
      (projects) => _buildList(projects),
      onEmpty: _buildEmpty(),
      onError: (message) => _buildError(message),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> projects) {
    return WDiv(
      className: 'flex flex-col',
      children: [
        MSPageHeader(
          title: 'Projects',
          subtitle: 'Manage your projects',
          actions: [
            WButton(
              onTap: controller.isLoading ? null : controller.loadProjects,
              className: 'py-2 px-4 rounded-lg bg-primary text-white text-sm',
              child: WText('Refresh'),
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-col gap-2 p-6',
          children: [
            for (final project in projects)
              MSCard(
                child: WText(
                  project['name'] as String,
                  className: 'text-gray-900 dark:text-white text-sm',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return WDiv(
      className: 'flex flex-col items-center justify-center p-12',
      children: [
        WText(
          'No projects yet.',
          className: 'text-gray-500 dark:text-gray-400 text-sm',
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return WDiv(
      className: 'flex flex-col items-center justify-center p-12',
      children: [
        WText(message, className: 'text-sm text-red-500'),
      ],
    );
  }
}
```

`renderState()` picks the builder from the current state:

| Argument | Rendered when |
|:---------|:--------------|
| First positional `(T value) => Widget` | The controller called `setSuccess(value)` |
| `onEmpty:` | The controller called `setEmpty()`, or the state is the initial one |
| `onError: (String message) => Widget` | The controller called `setError(message)` |
| `onLoading:` | The controller called `setLoading()`; without it `renderState()` draws a built-in loading indicator |

<a name="pattern-b-statefulwidget--manual-access"></a>
### Pattern B: StatefulWidget + Manual Access

Use a plain `StatefulWidget` and the `instance` accessor for a non-page widget (a dropdown, a card action, a sub-widget of an existing view):

```dart
import 'package:material_ui/material_ui.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

class ProjectCountBadge extends StatefulWidget {
  const ProjectCountBadge({super.key});

  @override
  State<ProjectCountBadge> createState() => _ProjectCountBadgeState();
}

class _ProjectCountBadgeState extends State<ProjectCountBadge> {
  late final ProjectController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProjectController.instance;
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final count = _controller.rxState?.length ?? 0;

    return WDiv(
      className: 'flex items-center gap-1',
      children: [
        WIcon(Icons.folder_outlined, className: 'text-gray-500 text-base'),
        WText(
          '$count Projects',
          className: 'text-sm text-gray-700 dark:text-gray-300',
        ),
      ],
    );
  }
}
```

> [!NOTE]
> `ProjectController.instance` registers the controller on demand through `findOrPut()`. Prefer it to a raw `Magic.find<T>()`, which throws when the controller has not been registered yet.

<a name="testing"></a>
## Testing

Magic's test helpers reset the container between tests and fake the network, so a controller test needs no hand-written driver. `MagicTest.init()` registers the `setUp` and `tearDown` hooks; `Http.fake()` stubs responses by URL pattern (a leading `/` is ignored) and records requests for assertions:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:magic/testing.dart';

void main() {
  MagicTest.init();

  group('ProjectController', () {
    late ProjectController controller;

    setUp(() {
      controller = ProjectController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('loadProjects success moves to the success state', () async {
      final fake = Http.fake({
        'api/projects': Http.response({
          'data': [
            {'id': 1, 'name': 'Apollo'},
            {'id': 2, 'name': 'Borealis'},
          ],
        }),
      });

      await controller.loadProjects();

      expect(controller.isSuccess, isTrue);
      fake.assertSent(
        (request) => request.method == 'GET' && request.url == '/api/projects',
      );
    });

    test('loadProjects 500 moves to the error state', () async {
      Http.fake({
        'api/projects': Http.response({}, 500),
      });

      await controller.loadProjects();

      expect(controller.isError, isTrue);
    });

    test('loadProjects is not re-entrant', () async {
      final fake = Http.fake({
        'api/projects': Http.response({'data': []}),
      });

      await Future.wait([controller.loadProjects(), controller.loadProjects()]);

      fake.assertSentCount(1);
    });
  });
}
```

In a test, construct the controller directly (`ProjectController()`) rather than through `instance`: it keeps the test independent of what the container cached. A test that depends on a starter feature flag sets it with `Config.set('magic_starter.features.teams', true)` in `setUp`. The faking API, stub patterns and assertions are in the [Magic testing guide](https://anilcancakir.com/magic/docs/testing/getting-started).

<a name="complete-example"></a>
## Complete Example

An end-to-end `ProjectList` feature is three files and one route:

| File | Holds |
|:-----|:------|
| `lib/app/controllers/project_controller.dart` | The `ProjectController` from [Implement Async Methods](#implement-async-methods) |
| `lib/resources/views/projects/project_list_view.dart` | The `ProjectListView` from [Pattern A](#pattern-a-magicstatefulview) |
| `test/app/controllers/project_controller_test.dart` | The test from [Testing](#testing) |

The route goes inside the starter's authenticated group, so the page renders in the app shell and shares its layout:

```dart
MagicRoute.group(
  layout: (child) => MagicStarter.view.makeLayout('layout.app', child: child),
  middleware: ['auth'],
  layoutId: MagicStarterLayoutIds.app,
  routes: () {
    MagicRoute.page('/projects', () {
      ProjectController.instance;
      return const ProjectListView();
    });
  },
);
```

<a name="related-documentation"></a>
## Related Documentation

- [Controllers](../architecture/controllers.md): how the starter's own controllers apply the pattern.
- [Service Provider](../architecture/service-provider.md): the boot sequence, where eager registration belongs.
- [Session Scope](../basics/session-scope.md): resetting a controller when the session changes.
- [Views and Layouts](../basics/views-and-layouts.md): `MagicStatefulView` and `renderState()` in the starter's views.
- [Magic IoC container](https://anilcancakir.com/magic/docs/architecture/service-container): `findOrPut` and the other bindings.
