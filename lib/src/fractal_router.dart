import 'package:flutter/material.dart';
import 'package:fractal_router/src/fractal_delegate.dart';
import 'package:fractal_router/src/fractal_parser.dart';
import 'package:fractal_router/src/fractal_route.dart';

class FractalRouter extends StatefulWidget {
  const FractalRouter({
    super.key,
    required this.routes,
    this.withParent = true,
  });

  /// The routes that this router will manage.
  final List<FractalRoute> routes;

  /// Whether this router should connect to any available parent router.
  ///
  /// If this is false, this Router considers itself a root and
  /// have its own managed path url.
  final bool withParent;

  /// Returns the [FractalDelegate] of the nearest ancestor [FractalRouter].
  static FractalDelegate of(BuildContext context) {
    RouterDelegate? delegate = maybeOf(context);
    if (delegate == null) {
      throw FlutterError(
        'FractalRouter.of() called with a context'
        ' that does not contain a FractalRouter.',
      );
    }
    return delegate as FractalDelegate;
  }

  /// Returns the [FractalDelegate] of the nearest ancestor [FractalRouter]
  /// or null if there is no [FractalRouter] ancestor.
  static FractalDelegate? maybeOf(BuildContext context) {
    RouterDelegate delegate = Router.of(context).routerDelegate;
    if (delegate is FractalDelegate) return delegate;
    return null;
  }

  @override
  State<FractalRouter> createState() => _FractalRouterState();
}

class _FractalRouterState extends State<FractalRouter> {
  /// The parent router.
  FractalDelegate? _parent;

  /// The delegate of this router.
  // TODO: we can simplify the initialisation, but for testing we leave it like this.
  FractalDelegate? delegate;

  /// The parent route.
  ///
  /// This is used as a default for the [FractalDelegate.onPopRoot] method.
  ModalRoute? _parentRoute;

  /// How the router will handle pop being called when there are no more routes.
  ///
  /// In case no parent is used, this will be called instead.
  ///
  /// By calling this, we essentially make this router integrate
  /// seamlessly with any other Navigators that may or may
  /// not be fractal routers.
  VoidCallback? onPopRoot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.withParent) {
      _parent = FractalRouter.maybeOf(context);
    } else {
      _parent = null;
    }

    _parentRoute = ModalRoute.of(context);

    if (_parentRoute != null && _parentRoute!.canPop) {
      onPopRoot = _parentRoute!.navigator?.maybePop;
    } else {
      onPopRoot = null;
    }

    if (delegate == null) {
      delegate = FractalDelegate(
        routes: widget.routes,
        parent: _parent,
        onPopRoot: onPopRoot,
      );
      print(
          'Creating delegate ${delegate.hashCode} with parent ${_parent?.hashCode}');
    } else {
      delegate!.update(
        routes: (widget.routes,),
        parent: (_parent,),
        onPopRoot: (onPopRoot,),
      );
      print(
          'Updating delegate ${delegate.hashCode} with parent ${_parent?.hashCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Router(
      routeInformationParser: const FractalParser(),
      routerDelegate: delegate!,
    );
  }
}
