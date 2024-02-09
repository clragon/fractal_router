import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fractal_router/src/app_bar_dismissal_proxy.dart';
import 'package:fractal_router/src/fractal_error_page.dart';
import 'package:fractal_router/src/fractal_route.dart';
import 'package:fractal_router/src/fractal_router.dart';
import 'package:fractal_router/src/uris.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

class FractalDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  FractalDelegate({
    required List<FractalRoute> routes,
    String initialPath = _root,
    FractalDelegate? parent,
    bool? alwaysRenderRoot,
    FractalPopBehavior? popBehaviour,
    VoidCallback? onPopRoot,
    FractalRouteBuilder? errorBuilder,
  })  : _routes = routes,
        _path = initialPath,
        _parent = parent,
        _alwaysRenderRoot = alwaysRenderRoot,
        _popBehaviour = popBehaviour,
        _onPopRoot = onPopRoot,
        _errorBuilder = errorBuilder {
    _updateParent(_parent);
    _updateRoute(_path);
  }

  @override
  void dispose() {
    if (_parent != null) {
      _parent!.removeListener(_updateParentPath);
    }
    super.dispose();
  }

  /// The root location path.
  static const String _root = '/';

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// The [GlobalKey] passed to the navigator of this delegate.
  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// The parent delegate of this delegate.
  ///
  /// If this is null, this delegate is considered a root delegate of its tree.
  /// A root delegate directly changes the path and manages the route history.
  FractalDelegate? get parent => _parent;
  set parent(FractalDelegate? value) => update(parent: (value,));
  FractalDelegate? _parent;

  /// Whether this delegate is a root delegate.
  ///
  /// A root delegate directly changes the path and manages the route history.
  ///
  /// A non-root delegate is a child of another delegate and does not change its own path,
  /// but instead passes changes to the parent.
  bool get isRoot => _parent == null;

  /// Visits this delegate and all its parents.
  ///
  /// Return false to stop visiting.
  void _visit(bool Function(FractalDelegate delegate) visitor) {
    if (visitor(this)) {
      _parent?._visit(visitor);
    }
  }

  /// The routes of this navigator.
  ///
  /// The first segment of [path] is matched against the [FractalRoute.path] of each route.
  /// An empty path is matched against the root location.
  List<FractalRoute> get routes => _routes;
  set routes(List<FractalRoute> value) => update(routes: (value,));
  List<FractalRoute> _routes;

  /// Whether this delegate has a root route.
  bool get _hasRootRoute => _routes.any((e) => e.path == _root);

  /// The path handled by this delegate.
  /// The first segment of the path is used to determine the Location to navigate to.
  ///
  /// If this delegate is not a root delegate, this path will not be equivalent to the full path.
  String get path => _path;
  set path(String value) => update(path: (value,));
  String _path;

  /// The path of this delegate as a [Uri].
  Uri get _uri => Uri.parse(path).formatted().asRoot();

  /// The route of this delegate.
  /// This is the route that matches the first segment of [path].
  ///
  /// If no route matches, this is null.
  FractalRoute? get route => _route;
  FractalRoute? _route;

  /// Whether this delegate is at its root route.
  /// TODO: what is this needed for?
  bool get _routeIsRoot => route?.path == _root;

  /// The segment of [path] that was matched to [route].
  ///
  /// If no route matches, this is null.
  String? get segment {
    if (route == null) return null;
    int count = route!.path.split('/').length;
    Iterable<String> parts = _uri.path.split('/').take(count);
    return Uri(pathSegments: parts).formatted().asRoot().toString();
  }

  /// The trailing part of [path] that was not matched to [route].
  /// This is the path that may be used by nested routers.
  ///
  /// If no route matches, this is null.
  String? get trailing {
    String? segment = this.segment;
    if (segment == null) return null;
    String path = _uri.path;
    assert(path.startsWith(segment));
    return path.substring(segment.length);
  }

  /// The path parameters of the path of this router.
  ///
  /// Does not include parameters in the trailing path.
  Map<String, String> get params {
    Map<String, String> result = {};
    _visit((delegate) {
      result.addAll(delegate._params);
      return true;
    });
    return result;
  }

  /// The path parameters of the segment of this router.
  Map<String, String> get _params {
    if (route != null) {
      List<String> keys = [];
      RegExp regex = pathToRegExp(route!.path, parameters: keys);
      Match? match = regex.firstMatch(segment!);
      assert(match != null);
      if (match != null) {
        return extract(keys, match);
      }
    }
    return {};
  }

  /// The query parameters of the path of this router.
  Map<String, String>? get query => _uri.queryParameters;

  /// The path of the root delegate.
  ///
  /// This may or may not be the same as [path].
  String get rootPath {
    String? path;
    _visit((delegate) {
      if (delegate.isRoot) {
        path = delegate.path;
        return false;
      }
      return true;
    });
    assert(path != null, 'FractalDelegate found no root delegate.');
    return path!;
  }

  /// If true, the root location will be rendered below the current location.
  /// This can be used to render the full tree of a path and makes sure the State of upper routes is preserved.
  /// If the routes list do not contain a root location, this is ignored.
  ///
  /// Commonly used with [FractalPopBehavior.hierarchical].
  bool? get alwaysRenderRoot => _alwaysRenderRoot;
  set alwaysRenderRoot(bool? value) => update(alwaysRenderRoot: (value,));
  bool? _alwaysRenderRoot;

  /// Called when when the delegate can no longer pop, but pop is called.
  ///
  /// This happens when this delegate is the root delegate and either of these conditions are met:
  /// - up is called when the current route is root
  /// - back is called when there is no history.
  ///
  /// If this is null, the delegate considers its root route not poppable.
  ///
  /// This is useful for interopability with non-fractal routers.
  ///
  /// Note that this will configure the AppBar of the child Pages.
  /// If you wish to have custom behaviours when pop is called without
  /// enabling this kind of configuration, you should use a [PopScope].
  VoidCallback? get onPopRoot => _onPopRoot;
  set onPopRoot(VoidCallback? value) => update(onPopRoot: (value,));
  VoidCallback? _onPopRoot;

  /// Whether the enclosing route can be popped.
  ///
  /// This is the case when one of the following is true:
  /// - The parent delegate is not null -> we delegate the pop
  /// - The current route is not the root route -> we can pop to the root route
  /// - [onPopRoot] is not null -> we can call [onPopRoot]
  bool get canPop => !isRoot || !_routeIsRoot || _onPopRoot != null;

  /// Build when [path] cannot be matched to a route.
  FractalRouteBuilder? get errorBuilder => _errorBuilder;
  set errorBuilder(FractalRouteBuilder? value) =>
      update(errorBuilder: (value,));
  FractalRouteBuilder? _errorBuilder;

  /// The default error page builder.
  Widget _defaultErrorBuilder(BuildContext context, FractalDelegate router) =>
      FractalRouterErrorPage(path: router.path);

  /// Defines how pop operations are handled.
  ///
  /// Hierarchical routers will pop their current location and then their parent location.
  /// Chronological routers will return to the previously visited location.
  ///
  /// If this delegate is not the root delegate, this is ignored.
  FractalPopBehavior? get popBehaviour => _popBehaviour;
  set popBehaviour(FractalPopBehavior? value) => update(popBehaviour: (value,));
  FractalPopBehavior? _popBehaviour;

  /// The history of paths that were visited.
  List<String> get history => List.unmodifiable(_history);
  set history(List<String> value) => update(history: (value,));
  List<String> _history = List.unmodifiable([]);

  /// Changes the path of this delegate.
  ///
  /// Paths follow the same rules as [Uri] paths.
  ///
  /// A absolute path will be used as is.
  /// For example:
  /// - The current path is `/a/b/c`
  /// - `change('/d')` will change the path to `/d`
  ///
  /// A relative path will be resolved against the current path.
  /// For example:
  /// - The current path is `/a/b/c`
  /// - `change('d')` will change the path to `/a/b/c/d`
  ///
  /// A relative path that goes up will be resolved against the parent path.
  /// For example:
  /// - The current path is `/a/b/c`
  /// - `change('..')` will change the path to `/a/b`
  void change(String path) => update(path: (path,));

  /// The previous path that this delegate was updated with.
  String? _lastPath;

  /// Updates the path of this delegate.
  /// Handles resolving relative and absolute paths.
  ///
  /// Returns true if the path was changed.
  bool _updatePath(String path) {
    if (path == _lastPath) return false;
    _lastPath = path;

    Uri uri = Uri.parse(path).formatted();
    if (!uri.path.startsWith('/')) {
      String? segment = this.segment;
      segment ??= _uri.pathSegments.firstOrNull ?? '';

      // this is a relative path
      uri = _uri.head // scheme and host
          .withChild(Uri.parse(segment)) // our path piece
          .withChild(uri); // the new path piece
      path = uri.toString();
    } else {
      // this is an absolute path
      // this doesnt require any special handling
    }

    if (!isRoot) {
      _parent!.change(path);
      return false;
    }

    if (!path.startsWith('/')) {
      path = Uri.parse('/$path').toString();
    }

    if (_path == path) return false;

    _path = path;

    _updateRoute(path);
    return true;
  }

  /// Updates the route of this delegate.
  /// Also produces the segment and trailing parts of the path.
  void _updateRoute(String path) {
    if (path.isEmpty) {
      path = _root;
    }

    String? match;

    if (path == _root) {
      match = _root;
    } else {
      match = UriPathNode.from(_routes.map((e) => e.path))
          .match(path)
          ?.getFullPath();
      match = '/$match';
    }

    final route = _routes.where((e) => e.path == match).firstOrNull;
    if (route == null) {
      _route = null;
      return;
    }
    if (route is FractalRedirectRoute) {
      change(route.redirect);
      return;
    } else if (route is FractalWidgetRoute) {
      bool isExact = Uri.parse(match).pathSegments.length ==
          Uri.parse(path).pathSegments.length;
      if (route.exact && isExact) {
        _route = route;
        return;
      } else {
        _route = null;
        return;
      }
    } else if (route is FractalNestedRoute) {
      _route = route;
      return;
    }

    _route = null;
  }

  /// Updates the parent of this delegate.
  void _updateParent(FractalDelegate? parent) {
    if (_parent != null) {
      _parent!.removeListener(_updateParentPath);
    }
    _parent = parent;
    if (_parent != null) {
      _parent!.addListener(_updateParentPath);
    }
    _updateParentPath();
  }

  /// Updates the path based on the parent's trailing path.
  void _updateParentPath() {
    if (_parent == null) return;
    if (_parent!.trailing == _path) return;
    _path = _parent!.trailing ?? _root;
    _updateRoute(_path);
  }

  /// Pops this navigator.
  ///
  /// Depending on [popBehaviour], this will either go up to the root path or back to the previous path.
  void pop() {
    FractalPopBehavior behaviour =
        parent?.popBehaviour ?? popBehaviour ?? FractalPopBehavior.hierarchical;
    switch (behaviour) {
      case FractalPopBehavior.hierarchical:
        up();
      case FractalPopBehavior.chronological:
        back();
    }
  }

  /// Pops the current route (hierarchical).
  ///
  /// If the current route is not root, we change to the root route.
  /// If the current route is root or we have no root route, we call up on the parent router.
  /// If the parent router is null, we call [onPopRoot].
  /// If [onPopRoot] is null, nothing happens.
  ///
  /// Instead of directly calling this method, prefer using [pop].
  void up() {
    if (_routeIsRoot || !_hasRootRoute) {
      if (!isRoot) {
        _parent!.up();
      } else {
        _onPopRoot?.call();
      }
    } else {
      change('..');
    }
  }

  /// Returns to the previously visited path (chronological).
  /// This behaviour is similar to the back button in a browser.
  ///
  /// If the parent router is not null, we call back on it.
  /// If the parent router is null, we call [onPopRoot].
  /// If the [onPopRoot] is null, nothing happens.
  ///
  /// Instead of directly calling this method, prefer using [pop].
  void back() {
    if (!isRoot) {
      _parent!.back();
    } else {
      String? last;
      List<String> history = List.from(this.history);
      if (history.isNotEmpty) {
        history.removeLast(); // remove current path
      }
      if (history.isNotEmpty) {
        last = history.removeLast();
      }
      this.history = history;
      if (last != null) {
        change(last);
      } else {
        _onPopRoot?.call();
      }
    }
  }

  /// Used to update the properties of this delegate.
  /// If any of the values have changed, a rebuild is scheduled.
  ///
  /// Values passed to this function must be wrapped in
  /// a single value record to indicate that they are new values.
  ///
  /// e.g. `update(path: (path,))`.
  ///
  /// This is because it would otherwise be impossible to pass null values.
  ///
  /// This is generally used internally.
  /// Instead of directly calling this method, prefer using the properties of this class.
  void update({
    CopyValue<FractalDelegate?>? parent,
    CopyValue<String>? path,
    CopyValue<List<FractalRoute>>? routes,
    CopyValue<bool?>? alwaysRenderRoot,
    CopyValue<VoidCallback?>? onPopRoot,
    CopyValue<FractalRouteBuilder?>? errorBuilder,
    CopyValue<FractalPopBehavior?>? popBehaviour,
    CopyValue<List<String>>? history,
  }) {
    bool rebuild = false;
    if (parent != null && parent.$1 != _parent) {
      _updateParent(parent.$1);
      rebuild = true;
    }
    if (path != null && path.$1 != _path) {
      rebuild = _updatePath(path.$1) || rebuild;
    }
    if (routes != null && listEquals(routes.$1, _routes)) {
      _routes = routes.$1;
      rebuild = true;
    }
    if (alwaysRenderRoot != null && alwaysRenderRoot.$1 != _alwaysRenderRoot) {
      _alwaysRenderRoot = alwaysRenderRoot.$1;
      rebuild = true;
    }
    if (onPopRoot != null && onPopRoot.$1 != _onPopRoot) {
      _onPopRoot = onPopRoot.$1;
      rebuild = true;
    }
    if (errorBuilder != null && errorBuilder.$1 != _errorBuilder) {
      _errorBuilder = errorBuilder.$1;
      rebuild = true;
    }
    if (popBehaviour != null && popBehaviour.$1 != _popBehaviour) {
      _popBehaviour = popBehaviour.$1;
      rebuild = true;
    }
    if (history != null && !listEquals(history.$1, _history)) {
      _history = List.unmodifiable(history.$1);
      rebuild = true;
    }
    if (rebuild) {
      notifyListeners();
    }
  }

  Widget _buildRoute(BuildContext context, FractalRoute route) {
    return switch (route) {
      FractalWidgetRoute() => route.builder(context, this),
      FractalNestedRoute() => FractalRouter(
          routes: route.routes!,
        ),
      FractalRedirectRoute() => (() {
          assert(false, 'FractalDelegate tried to render a redirect route.');
          return (errorBuilder ?? _defaultErrorBuilder)(context, this);
        }()),
    };
  }

  @override
  @protected
  Future<void> setNewRoutePath(Uri configuration) {
    change(configuration.toString());
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    bool alwaysRenderRoot = this.alwaysRenderRoot ??
        // FractalRouterConfig.maybeOf(context)?.alwaysRenderRoot ??
        false;

    FractalRouteBuilder errorBuilder = this.errorBuilder ??
        // FractalRouterConfig.maybeOf(context)?.errorBuilder ??
        _defaultErrorBuilder;

    FractalRoute? rootRoute = routes.where((e) => e.path == _root).firstOrNull;

    bool canPopRoot = (!isRoot && parent!.canPop) || _onPopRoot != null;
    bool showRootRoute = alwaysRenderRoot && _hasRootRoute;

    return Navigator(
      key: navigatorKey,
      pages: [
        if (_routeIsRoot || showRootRoute)
          if (rootRoute != null)
            MaterialPage(
              key: const ValueKey(_root),
              child: AppBarDismissalProxy(
                enabled: canPopRoot,
                child: Builder(
                  builder: (context) => _buildRoute(context, rootRoute),
                ),
              ),
            ),
        if (!_routeIsRoot)
          MaterialPage(
            key: ValueKey(_route),
            child: AppBarDismissalProxy(
              enabled: !showRootRoute,
              child: Builder(
                builder: (context) {
                  if (_route != null) {
                    return _buildRoute(context, _route!);
                  }
                  return errorBuilder(context, this);
                },
              ),
            ),
          ),
      ],
      onPopPage: (route, result) {
        pop();
        return false;
      },
    );
  }
}

/// Defines the behaviour of the [FractalDelegate.pop] method.
///
/// - [hierarchical] pops the current location. If the current location is root, the pop is passed to the enclosing navigator.
/// - [chronological] returns to the previously visited location. If there is no previous location, nothing happens.
enum FractalPopBehavior {
  /// Pops the current location. If the current location is root, the pop is passed to the enclosing navigator.
  hierarchical,

  /// Returns to the previously visited location. If there is no previous location, nothing happens.
  chronological,
}

/// The explicit new value of a property.
typedef CopyValue<T extends Object?> = (T value,);
