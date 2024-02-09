import 'package:flutter/widgets.dart';
import 'package:fractal_router/path_nav/path_nav.dart';

/// Builds the widget for a [PathLocation].
///
/// [path] is the remaining path after the location's path has been matched.
typedef PathLocationBuilder = Widget Function(
  BuildContext context,
  String path,
);

/// Asserts valid [PathLocation] paths.
///
/// A valid path must start with a forward slash and cannot contain a forward slash anywhere except at the beginning.
/// This is equivalent to a single segment path.
///
/// Example of valid paths: "/home" or "/settings".
String _assertValidPath(String path) {
  if (!path.startsWith('/')) {
    throw ArgumentError(
      'Invalid Location: $path.'
          ' Path must start with a forward slash.',
      'path',
    );
  }

  if (path.substring(1).contains('/')) {
    throw ArgumentError(
      'Invalid Location: $path.'
          ' Path cannot contain a forward slash anywhere except at the beginning.',
      'path',
    );
  }

  return path;
}

class PathLocation {
  /// A location of a [PathNavigator].
  ///
  /// {@macro path_location_path}
  PathLocation({
    required String path,
    required this.builder,
  }) : path = _assertValidPath(path);

  /// {@template path_location_path}
  /// Path is the single segment path of this location.
  /// e.g. "/home" or "/settings".
  ///
  /// Additionally, the path segment can be specified to be a parameter.
  /// The syntax for this is "/:name(regex)". The regex is optional.
  /// {@endtemplate}
  final String path;

  /// The widget at this location.
  ///
  /// The [path] parameter is the rest of the path after the location's path.
  final PathLocationBuilder builder;
}

class PathBranchLocation implements PathLocation {
  /// A branching location of a [PathNavigator].
  ///
  /// Inserts another [PathNavigator] at this location.
  /// [builder] is a shortcut for creating a child root route.
  ///
  /// {@macro path_location_path}
  PathBranchLocation({
    required String path,
    required List<PathLocation> children,
    PathLocationBuilder? builder,
  })  : path = _assertValidPath(path),
        children = children = [
          if (builder != null) PathLocation(path: '/', builder: builder),
          ...children,
        ],
        builder = ((context, path) => PathNavigator(
              path: path,
              locations: children,
            ));

  @override
  final String path;

  @override
  final PathLocationBuilder builder;

  /// The children of this branch location.
  final List<PathLocation> children;
}
