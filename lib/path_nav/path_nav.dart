import 'package:flutter/material.dart';
import 'package:fractal_router/path_nav/dismissal.dart';
import 'package:fractal_router/path_nav/path_nav_config.dart';
import 'package:fractal_router/path_nav/path_nav_error.dart';
import 'package:fractal_router/path_nav/path_nav_location.dart';
import 'package:fractal_router/src/uris.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

class PathNavigator extends StatefulWidget {
  /// A navigator that renders a [PathLocation] based on the first segment of [path].
  const PathNavigator({
    super.key,
    required this.path,
    required this.locations,
    this.onChanged,
    this.errorBuilder,
    this.alwaysRenderRoot,
    this.popBehaviour,
  });

  /// {@template path_navigator_path}
  /// The path passed to this navigator.
  /// The first segment of the path is used to determine the Location to navigate to.
  /// {@endtemplate}
  final String path;

  /// {@template path_navigator_on_changed}
  /// Called when [path] changes.
  ///
  /// This happens when Navigator.pop is called.
  ///
  /// If null, [PathNavigator] will look for its nearest ancestor [PathNavigator] and use its [onChanged] callback.
  /// If no ancestor [PathNavigator] has an [onChanged] callback, an Error will be thrown.
  /// {@endtemplate}
  final ValueChanged<String>? onChanged;

  /// The locations of this navigator.
  ///
  /// The first segment of [path] is matched against the [PathLocation.path] of each location.
  /// An empty path is matched against the root location.
  final List<PathLocation> locations;

  /// {@template path_navigator_always_render_root}
  /// If true, the root location will be rendered below the current location.
  /// This can be used to render the full tree of a path and makes sure the State of upper routes is preserved.
  /// {@endtemplate}
  ///
  /// If a [PathNavigatorConfig] is in scope, its value will be used as the default. Otherwise, defaults to false.
  final bool? alwaysRenderRoot;

  /// {@template path_navigator_error_builder}
  /// Called when [path] cannot be matched to a location.
  /// {@endtemplate}
  ///
  /// If a [PathNavigatorConfig] is in scope, its value will be used as the default. Otherwise, defaults to [PathNavigatorErrorPage].
  final PathLocationBuilder? errorBuilder;

  /// {@template path_navigator_pop_behaviour}
  /// Defines how pop operations are handled.
  ///
  /// Hierarchical navigators will pop their current location and then their parent location.
  /// Chronological navigators will return to the previously visited location.
  ///
  /// While it is possible to mix hierarchical and chronological navigators, it is not recommended.
  /// {@endtemplate}
  ///
  /// If a [PathNavigatorConfig] is in scope, its value will be used as the default. Otherwise, defaults to [PathNavigatorPopBehaviour.hierarchical].
  final PathNavigatorPopBehaviour? popBehaviour;

  /// Returns the nearest [PathNavigatorState] ancestor.
  static PathNavigatorState of(BuildContext context) => maybeOf(context)!;

  /// Returns the nearest [PathNavigatorState] ancestor or null if there is none.
  static PathNavigatorState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<PathNavigatorState>();

  /// Returns the nearest [PathNavigatorState] ancestor that is a root.
  ///
  /// {@macro path_navigator_is_root}
  static PathNavigatorState rootOf(BuildContext context) =>
      maybeRootOf(context)!;

  /// Returns the nearest [PathNavigatorState] ancestor that is a root or null if there is none.
  ///
  /// {@macro path_navigator_is_root}
  static PathNavigatorState? maybeRootOf(BuildContext context) {
    PathNavigatorState? state =
        context.findAncestorStateOfType<PathNavigatorState>();
    while (state != null && !state.isRoot) {
      context = state.context;
      state = context.findAncestorStateOfType<PathNavigatorState>();
    }
    return state;
  }

  @override
  State<PathNavigator> createState() => PathNavigatorState();
}

class PathNavigatorState extends State<PathNavigator> {
  /// The parent navigator.
  PathNavigatorState? _parent;

  /// The parent route.
  ModalRoute? _parentRoute;

  /// Whether the enclosing route can be popped.
  bool get _canPop => _parentRoute?.canPop ?? false;

  /// The parsed uri of [path].
  Uri get _uri {
    String path = widget.path;
    if (path.isEmpty) {
      path = _root;
    }
    try {
      Uri uri = Uri.parse(path);
      uri = uri.replace(
        // This removes trailing slashes. This is necessary for the query and fragment logic to work.
        pathSegments: uri.pathSegments.where((e) => e.isNotEmpty),
      );
      return uri;
    } on FormatException {
      // TODO: handle this appropriately
      rethrow;
    }
  }

  /// The path segment that corresponds to this navigator.
  String get segment {
    if (_uri.pathSegments.isNotEmpty) {
      return '/${_uri.pathSegments.first}';
    }
    return _root;
  }

  /// The path below the segment of this navigator.
  String get childPath =>
      _uri.tail.replace(pathSegments: _uri.pathSegments.skip(1)).toString();

  /// The path above the segment of this navigator.
  String get parentPath {
    if (_parent != null && !isRoot) {
      return Uri.parse(_parent!.parentPath)
          .withChild(Uri.parse(_parent!.segment))
          .toString();
    }
    return _uri.head.toString();
  }

  /// The full path passed through this navigator tree.
  /// Includes both upstream and downstream paths.
  String get fullPath => Uri.parse(parentPath)
      .withChild(Uri.parse(segment))
      .withChild(Uri.parse(childPath))
      .toString();

  /// The parameters in the path of this navigator and its ancestors up to the root.
  /// Parameters are defined in the path of locations by prefixing a path segment with a colon.
  ///
  /// For example, the path `/:id` defines a parameter `id`.
  /// Regex can be used to further define the parameter, e.g. `/:id(\d+)`.
  ///
  /// {@macro path_navigator_is_root}
  Map<String, String> get params {
    Map<String, String> params = {};
    if (_parent != null) {
      params.addAll(_parent!.params);
    }
    if (_location != null) {
      List<String> parameters = [];
      RegExp regex = pathToRegExp(_location!.path, parameters: parameters);
      Match match = regex.firstMatch(segment)!;
      params.addAll(extract(parameters, match));
    }
    return params;
  }

  /// The query parameters of the path of this navigator.
  ///
  /// This only returns query parameters if this navigator handles the segment
  /// of the path which is followed by the query parameters (the last segment).
  Map<String, String> get query {
    if (_uri.pathSegments.length <= 1) {
      return _uri.queryParameters;
    }
    return {};
  }

  /// The fragment of the path of this navigator.
  ///
  /// This only returns the fragment if this navigator handles the segment
  /// of the path which is followed by the fragment (the last segment).
  String get fragment {
    if (_uri.pathSegments.length <= 1) {
      return _uri.fragment;
    }
    return '';
  }

  /// Whether this navigator is a root navigator.
  ///
  /// {@template path_navigator_is_root}
  /// Whether a path navigator is a root is defined by whether it has an [onChanged] callback.
  /// {@endtemplate}
  bool get isRoot => widget.onChanged != null;

  /// Changes the path of this navigator.
  ///
  /// If [onChanged] is null, the callback will be passed upwards to the nearest ancestor [PathNavigator].
  void change(String path) => _change(path);

  /// Changes the path below the segment of this navigator.
  ///
  /// Can be used to recursively change the path of upper navigators.
  /// If [onChanged] is null, the callback will be passed upwards to the nearest ancestor [PathNavigator].
  void changeBelow(String path) => _change(path, replaceCurrent: false);

  /// Changes the path of this navigator.
  ///
  /// If [replaceCurrent] is false, the current path segment will be preserved.
  ///
  /// If this navigator has an onChanged method, it will be called.
  /// Otherwise, the callback will be passed upwards to the nearest ancestor [PathNavigator].
  ///
  /// The callback is also passed upwards if this navigator is not a root navigator.
  /// {@macro path_navigator_is_root}
  void _change(String path, {bool replaceCurrent = true}) {
    String result = _modifyPath(path, replaceCurrent: replaceCurrent);
    if (widget.onChanged != null) {
      widget.onChanged!(result);
      if (!isRoot && _parent != null) {
        _parent!.changeBelow(result);
      }
    } else {
      if (_parent != null) {
        _parent!.changeBelow(result);
      } else {
        throw FlutterError.fromParts([
          ErrorSummary('PathNavigator has no onChanged callback'),
          ErrorDescription(
            'PathNavigator.onChanged is null and no ancestor PathNavigator was found.'
            '\nPlease make sure to specify onChanged on your root PathNavigator.',
          ),
        ]);
      }
    }
  }

  /// Modifies the path of this navigator.
  /// This function makes sure the path is well-formed and preserves other URL parts.
  ///
  /// If [replaceCurrent] is false, the current path segment will be preserved.
  String _modifyPath(String path, {bool replaceCurrent = true}) {
    Uri uri = Uri.parse(widget.path).head;
    uri = uri.replace(
      pathSegments: [
        // This is okay because we know segment always starts with a slash.
        if (!replaceCurrent) segment.substring(1),
      ],
    );
    return uri.withChild(Uri.parse(path)).toString();
  }

  /// The history of paths that were visited.
  final List<String> _history = [];

  /// Pops this navigator.
  ///
  /// Depending on [popBehaviour], this will either go up to the root path or back to the previous path.
  void pop() {
    PathNavigatorPopBehaviour behaviour = widget.popBehaviour ??
        PathNavigatorConfig.of(context).popBehaviour ??
        PathNavigatorPopBehaviour.hierarchical;
    switch (behaviour) {
      case PathNavigatorPopBehaviour.hierarchical:
        up();
      case PathNavigatorPopBehaviour.chronological:
        back();
    }
  }

  /// Pops the current location (hierarchical).
  ///
  /// If the current location is not root, the root location will be shown.
  /// If the current location is root, the pop is passed to the enclosing navigator.
  ///
  /// Instead of directly calling this method, prefer using [pop].
  void up() {
    if (!_hasRoot || _atRoot) {
      if (_canPop && _parentRoute!.isCurrent) {
        _parentRoute!.navigator!.pop();
      }
    } else {
      change(_root);
    }
  }

  /// Returns to the previously visited path (chronological).
  ///
  /// This behaviour is similar to the back button in a browser.
  ///
  /// Instead of directly calling this method, prefer using [pop].
  void back() {
    // TODO: going back somehow leaks previous host into new path
    String? last;
    if (_history.length > 1) {
      _history.removeLast(); // remove current path
      last = _history.removeLast();
    }
    if (isRoot) {
      if (last != null) {
        change(last);
      } // TODO: else, pop surrounding navigator?
    } else {
      _parent!.back();
    }
  }

  /// The root location path.
  static const String _root = '/';

  /// The current location.
  PathLocation? _location;

  /// Whether this navigator has a root location.
  bool get _hasRoot => widget.locations.any((e) => e.path == _root);

  /// Whether our current location is the root location.
  bool get _atRoot => _location?.path == _root;

  /// Finds the location that matches [segment].
  PathLocation? _findLocation(String segment) {
    for (PathLocation location in widget.locations) {
      if (pathToRegExp(location.path).hasMatch(segment)) {
        return location;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _history.add(widget.path);
    _location = _findLocation(segment);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = PathNavigator.maybeOf(context);
    _parentRoute = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(covariant PathNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _history.add(widget.path);
      _location = _findLocation(segment);
    }
  }

  /// The default error page builder.
  Widget _defaultErrorBuilder(BuildContext context, String path) =>
      PathNavigatorErrorPage(path: path);

  @override
  Widget build(BuildContext context) {
    bool alwaysRenderRoot = widget.alwaysRenderRoot ??
        PathNavigatorConfig.maybeOf(context)?.alwaysRenderRoot ??
        false;

    PathLocationBuilder errorBuilder = widget.errorBuilder ??
        PathNavigatorConfig.maybeOf(context)?.errorBuilder ??
        _defaultErrorBuilder;

    return Navigator(
      pages: [
        if (_atRoot || alwaysRenderRoot && _hasRoot)
          MaterialPage(
            key: const ValueKey(_root),
            child: AppBarDismissalProxy(
              enabled: _canPop,
              child: Builder(
                builder: (context) =>
                    widget.locations.firstWhere((e) => e.path == _root).builder(
                          context,
                          _root,
                        ),
              ),
            ),
          ),
        if (!_atRoot)
          MaterialPage(
            key: ValueKey('${_location?.path}'),
            child: AppBarDismissalProxy(
              enabled: !alwaysRenderRoot || !_hasRoot && _canPop,
              child: Builder(
                builder: (context) {
                  if (_location != null) {
                    return _location!.builder(context, childPath);
                  }
                  return errorBuilder(context, segment);
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

/// Defines the behaviour of the [PathNavigator.pop] method.
///
/// - [hierarchical] pops the current location. If the current location is root, the pop is passed to the enclosing navigator.
/// - [chronological] returns to the previously visited location. If there is no previous location, nothing happens.
enum PathNavigatorPopBehaviour {
  /// Pops the current location. If the current location is root, the pop is passed to the enclosing navigator.
  hierarchical,

  /// Returns to the previously visited location. If there is no previous location, nothing happens.
  chronological,
}
