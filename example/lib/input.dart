import 'package:flutter/material.dart';
import 'package:fractal_router/fractal_router.dart';

class FractalInput extends StatefulWidget {
  const FractalInput({
    super.key,
    this.paths = const [],
    required this.delegate,
  });

  final List<String> paths;
  final FractalDelegate delegate;

  @override
  State<FractalInput> createState() => _FractalInputState();
}

class _FractalInputState extends State<FractalInput> {
  late final TextEditingController controller =
      TextEditingController(text: widget.delegate.path);

  String? previousPath;

  @override
  void initState() {
    super.initState();
    widget.delegate.addListener(onUpdate);
  }

  void onUpdate() {
    setState(() {});
    if (widget.delegate.path != previousPath) {
      controller.text = widget.delegate.path;
      previousPath = widget.delegate.path;
    }
  }

  @override
  void didUpdateWidget(covariant FractalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    widget.delegate.removeListener(onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  onSubmitted: (value) => widget.delegate.path = value,
                  decoration: InputDecoration(
                    labelText: 'Path',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton(
                          icon: const Icon(Icons.tune),
                          onSelected: (value) {
                            switch (value) {
                              case #alwaysRenderRoot:
                                widget.delegate.alwaysRenderRoot =
                                    !(widget.delegate.alwaysRenderRoot ??
                                        false);
                              case #popBehaviour:
                                widget.delegate.popBehaviour =
                                    widget.delegate.popBehaviour ==
                                            FractalPopBehavior.chronological
                                        ? FractalPopBehavior.hierarchical
                                        : FractalPopBehavior.chronological;
                            }
                          },
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem(
                              value: #alwaysRenderRoot,
                              checked:
                                  widget.delegate.alwaysRenderRoot ?? false,
                              child: const Text('Always Render Root'),
                            ),
                            CheckedPopupMenuItem(
                              value: #popBehaviour,
                              checked: widget.delegate.popBehaviour ==
                                  FractalPopBehavior.chronological,
                              child: const Text('Pop Chronologically'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_next),
                          onPressed: () =>
                              widget.delegate.path = controller.text,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: Row(
                    children: widget.paths
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(e),
                              onPressed: () => widget.delegate.path = e,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
