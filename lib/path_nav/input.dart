import 'package:flutter/material.dart';
import 'package:fractal_router/path_nav/path_nav.dart';
import 'package:fractal_router/path_nav/path_nav_config.dart';

class PathInput extends StatefulWidget {
  const PathInput({
    super.key,
    required this.builder,
    required this.path,
    required this.paths,
    required this.onChanged,
  });

  final String path;
  final ValueChanged<String> onChanged;
  final List<String> paths;
  final Widget Function(BuildContext context, String path) builder;

  @override
  State<PathInput> createState() => _PathInputState();
}

class _PathInputState extends State<PathInput> {
  late final TextEditingController controller =
      TextEditingController(text: widget.path);

  bool alwaysRenderRoot = false;
  PathNavigatorPopBehaviour popBehaviour =
      PathNavigatorPopBehaviour.hierarchical;

  @override
  void didUpdateWidget(covariant PathInput oldWidget) {
    if (oldWidget.path != widget.path) {
      controller.text = widget.path;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
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
                  onSubmitted: widget.onChanged,
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
                                setState(() {
                                  alwaysRenderRoot = !alwaysRenderRoot;
                                });
                              case #popBehaviour:
                                setState(() {
                                  popBehaviour = popBehaviour ==
                                          PathNavigatorPopBehaviour
                                              .chronological
                                      ? PathNavigatorPopBehaviour.hierarchical
                                      : PathNavigatorPopBehaviour.chronological;
                                });
                            }
                          },
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem(
                              value: #alwaysRenderRoot,
                              checked: alwaysRenderRoot,
                              child: const Text('Always Render Root'),
                            ),
                            CheckedPopupMenuItem(
                              value: #popBehaviour,
                              checked: popBehaviour ==
                                  PathNavigatorPopBehaviour.chronological,
                              child: const Text('Pop Chronologically'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_next),
                          onPressed: () => widget.onChanged(controller.text),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ActionChip(
                                label: Text(e),
                                onPressed: () => widget.onChanged(e),
                              ),
                            ),
                          )
                          .toList(),
                    )),
              ],
            ),
          ),
          Expanded(
            child: PathNavigatorConfig(
              alwaysRenderRoot: alwaysRenderRoot,
              popBehaviour: popBehaviour,
              child: widget.builder(context, widget.path),
            ),
          ),
        ],
      ),
    );
  }
}
