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

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _update();
  }

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enabled) {
        if (_entry != null) return;
        _disposed = false;
        _entry = LocalHistoryEntry(
          onRemove: () {
            assert(
              _disposed,
              'AppBarDismissalProxy lost its local history entry through a pop action.',
            );
            _entry = null;
          },
        );
        _modalRoute.addLocalHistoryEntry(_entry!);
      } else {
        if (_entry == null) return;
        _disposed = true;
        _modalRoute.removeLocalHistoryEntry(_entry!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppBarDismissalProxy oldWidget) {
    if (widget.enabled != oldWidget.enabled) {
      _update();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _disposed = true;
    if (_entry != null) {
      _modalRoute.removeLocalHistoryEntry(_entry!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
