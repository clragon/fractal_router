import 'package:flutter/material.dart';
import 'package:fractal_router/fractal_router.dart';
import 'package:fractal_router_example/input.dart';
import 'package:fractal_router_example/page.dart';

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final FractalDelegate _delegate = FractalDelegate(
    routes: [
      FractalRoute(
        path: '/',
        builder: (context, router) => const AppPage(
          title: 'Home',
          paths: ['/users', '/users/1/comments', 'settings'],
        ),
      ),
      FractalRoute(
        path: '/users',
        builder: (context, router) => const AppPage(
          title: 'Users',
          paths: ['1', '2'],
        ),
        routes: [
          FractalRoute(
            path: r'/:id(\d+)',
            builder: (context, router) {
              final id = router.params['id'];
              return AppPage(
                title: 'User $id',
                paths: const ['profile', 'comments'],
              );
            },
            routes: [
              FractalRoute(
                path: '/comments',
                builder: (context, router) => AppPage(
                  title: 'Comments for User ${router.params['id']}',
                ),
              ),
            ],
          ),
        ],
      ),
      FractalRoute(
        path: '/settings',
        builder: (context, router) => const AppPage(
          title: 'Settings',
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Column(
        children: [
          FractalInput(
            delegate: _delegate,
          ),
          Expanded(
            child: Router(
              routeInformationParser: const FractalParser(),
              routerDelegate: _delegate,
            ),
          ),
        ],
      ),
    );
  }
}
