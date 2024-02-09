import 'package:flutter/material.dart';
import 'package:fractal_router/src/fractal_router.dart';

class FractalRouterErrorPage extends StatelessWidget {
  /// The default error page for [FractalRouter].
  const FractalRouterErrorPage({
    super.key,
    required this.path,
  });

  /// The path that could not be matched to a route.
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
            Text('There is nothing at $path'),
          ],
        ),
      ),
    );
  }
}
