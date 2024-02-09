import 'package:flutter/material.dart';
import 'package:fractal_router/path_nav/path_nav.dart';

class PathNavigatorErrorPage extends StatelessWidget {
  /// The default error page for [PathNavigator].
  const PathNavigatorErrorPage({
    super.key,
    required this.path,
  });

  /// The path that could not be matched to a location.
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '404',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text('No location found for path: $path'),
          ],
        ),
      ),
    );
  }
}
