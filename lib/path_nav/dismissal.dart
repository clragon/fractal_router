import 'package:flutter/material.dart';

class AppBarDismissalProxy extends StatefulWidget {
  /// Tricks the enclosed Route into thinking it can be popped.
  ///
  /// This is necessary to escape nested navigators.
  /// The enclosing navigator has to appropriately handle the pop.
  const AppBarDismissalProxy({
    super.key,
    this.enabled = true,
    required this.child,
  });

  /// Whether the enclosed Route can be popped.
  final bool enabled;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<AppBarDismissalProxy> createState() => _AppBarDismissalProxyState();
}

class _AppBarDismissalProxyState extends State<AppBarDismissalProxy> {
  LocalHistoryEntry? _entry;

  late final ModalRoute<dynamic> _modalRoute = ModalRoute.of<dynamic>(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enabled) {
        _entry = LocalHistoryEntry();
        _modalRoute.addLocalHistoryEntry(_entry!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppBarDismissalProxy oldWidget) {
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _entry = LocalHistoryEntry();
          _modalRoute.addLocalHistoryEntry(_entry!);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _modalRoute.removeLocalHistoryEntry(_entry!);
          _entry = null;
        });
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (_entry != null) {
      _modalRoute.removeLocalHistoryEntry(_entry!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
