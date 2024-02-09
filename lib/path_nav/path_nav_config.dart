import 'package:flutter/material.dart';
import 'package:fractal_router/path_nav/path_nav.dart';
import 'package:fractal_router/path_nav/path_nav_location.dart';

class PathNavigatorConfig extends InheritedWidget {
  /// Configures default values for all [PathNavigator] widgets below in the tree.
  const PathNavigatorConfig({
    super.key,
    this.alwaysRenderRoot,
    this.errorBuilder,
    this.popBehaviour,
    required super.child,
  });

  /// {@macro path_navigator_always_render_root}
  /// Defaults to false.
  final bool? alwaysRenderRoot;

  /// {@macro path_navigator_error_builder}
  final PathLocationBuilder? errorBuilder;

  /// {@macro path_navigator_pop_behaviour}
  final PathNavigatorPopBehaviour? popBehaviour;

  /// Returns the nearest [PathNavigatorConfig].
  static PathNavigatorConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PathNavigatorConfig>()!;

  /// Returns the nearest [PathNavigatorConfig], if any.
  static PathNavigatorConfig? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PathNavigatorConfig>();

  @override
  bool updateShouldNotify(PathNavigatorConfig oldWidget) =>
      alwaysRenderRoot != oldWidget.alwaysRenderRoot;
}
