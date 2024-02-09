import 'package:fractal_router/src/fractal_route.dart';

/// Asserts valid [FractalRoute] paths.
///
/// A valid path must start with a forward slash and cannot contain a forward slash anywhere except at the beginning.
/// This is equivalent to a single segment path.
///
/// Example of valid paths: "/home" or "/settings".
void assertValidPath(String path) {
  if (!path.startsWith('/')) {
    throw ArgumentError(
      'Invalid Route: $path.'
          ' Path must start with a forward slash.',
      'path',
    );
  }

  if (path.substring(1).contains('/')) {
    throw ArgumentError(
      'Invalid Route: $path.'
          ' Path cannot contain a forward slash anywhere except at the beginning.',
      'path',
    );
  }
}

/// Asserts valid [FractalRoute] routes.
///
/// A valid route configuration must not contain duplicate paths.
/// A valid route path must start with a forward slash and cannot contain a forward slash anywhere except at the beginning.
///
/// Example of a valid route configuration:
/// ```dart
/// final routes = [
///   FractalRoute(
///     path: '/',
///     builder: (context, path) => HomePage(),
///   ),
///   FractalRoute(
///     path: '/users',
///     builder: (context, path) => UsersList(),
///     routes: [
///       FractalRoute(
///         path: '/:id(\d+)',
///         builder: (context, path) => User(id: FractalRouter.of(context).params['id']),
///       ),
///     ],
///   ),
/// ];
/// ```
void assertValidRoutes(List<FractalRoute> routes) {
  final paths = <String>{};
  for (final route in routes) {
    if (paths.contains(route.path)) {
      throw ArgumentError(
        'Invalid Route: ${route.path}.'
            ' Duplicate path found.',
        'routes',
      );
    }
    paths.add(route.path);
  }
}
