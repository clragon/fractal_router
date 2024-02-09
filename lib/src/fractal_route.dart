import 'package:flutter/widgets.dart';
import 'package:fractal_router/fractal_router.dart';
import 'package:fractal_router/src/fractal_router.dart';

/// {@template fractal_router.FractalRoute}
/// A Route of a [FractalRouter].
///
/// [path] is the single segment path of this location.
/// e.g. "/home" or "/settings". It may also specify parameters like "/:name(regex)" where the regex is optional.
///
/// [builder] is the widget at this exact route.
/// If this is null, navigating directly to this route will result in a 404.
///
/// [routes] are the children of this route.
/// If this is not null, [builder] will be wrapped in a nested [FractalRouter].
///
/// [exact] determines whether this route needs to match the entire path.
/// If false, the router will assume that the trailing path will
/// be handled appropriately by the widget at this route.
/// If this Route has [routes], this only applies to the [builder] of this route.
/// {@endtemplate}
sealed class FractalRoute {
  /// {@macro fractal_router.FractalRoute}
  factory FractalRoute({
    required String path,
    required FractalRouteBuilder? builder,
    List<FractalRoute>? routes,
    bool exact = true,
  }) {
    if (routes != null) {
      return FractalNestedRoute(
        path: path,
        routes: [
          if (builder != null)
            FractalRoute(
              path: '/',
              builder: builder,
              exact: exact,
            ),
          ...routes,
        ],
      );
    } else {
      if (builder == null) {
        throw ArgumentError(
          'Invalid Route: $path.'
              ' Either a builder or routes must be specified.',
          'path',
        );
      }
      return FractalWidgetRoute(
        path: path,
        builder: builder,
        exact: exact,
      );
    }
  }

  /// The single segment path of this route.
  /// e.g. "/home" or "/settings".
  ///
  /// Additionally, the path segment can be specified to be a parameter.
  /// The syntax for this is "/:name(regex)". The regex is optional.
  String get path;
}

class FractalWidgetRoute implements FractalRoute {
  FractalWidgetRoute({
    required this.path,
    required this.builder,
    this.exact = true,
  });

  @override
  final String path;

  /// The widget displayed at this route.
  /// The [path] parameter is the rest of the path after the route's path.
  final FractalRouteBuilder builder;

  /// Whether this route needs to match the entire path.
  ///
  /// If false, the router will assume that the trailing path will
  /// be handled appropriately by the widget at this route.
  ///
  /// If true, the router will throw a 404 if the trailing path cannot be matched.
  final bool exact;

  @override
  String toString() => 'FractalWidgetRoute(path: $path, builder: $builder)';
}

class FractalNestedRoute implements FractalRoute {
  FractalNestedRoute({
    required this.path,
    required this.routes,
  });

  @override
  final String path;

  /// The nested routes of this route.
  ///
  /// When this route is matched, a [FractalRouter] with these routes will be inserted.
  final List<FractalRoute>? routes;

  @override
  String toString() => 'FractalNestedRoute(path: $path, routes: $routes)';
}

class FractalRedirectRoute implements FractalRoute {
  FractalRedirectRoute({
    required this.path,
    required this.redirect,
  });

  // TODO: add redirect builder that takes context and router so users can rewrite paths

  @override
  final String path;

  /// The path to redirect to.
  ///
  /// Note that this is used as a relative path of the router which owns this route.
  final String redirect;

  @override
  String toString() => 'FractalRedirectRoute(path: $path, redirect: $redirect)';
}

/// Builds the widget for a [FractalRoute].
///
/// [router] is the enclosing [FractalDelegate] of the route,
/// which can be used to navigate to other routes or access route parameters.
///
/// For example:
/// ```dart
/// final routeBuilder = (context, router) => UserPage(id: router.params['id']);
/// ```
typedef FractalRouteBuilder = Widget Function(
  BuildContext context,
  FractalDelegate router,
);
