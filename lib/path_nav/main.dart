import 'package:flutter/material.dart';
import 'package:fractal_router/path_nav/input.dart';
import 'package:fractal_router/path_nav/path_nav.dart';
import 'package:fractal_router/path_nav/path_nav_location.dart';
import 'package:fractal_router/path_nav/timer.dart';

// void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      theme: ThemeData.from(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String path = '/';

  late final List<PathLocation> locations = [
    PathLocation(
      path: '/',
      builder: (context, path) => const AppPage(
        title: 'Home',
        paths: ['/users', '/posts'],
      ),
    ),
    PathBranchLocation(
      path: '/users',
      builder: (context, path) => AppPage(
        title: 'Users',
        paths: [
          1,
          4,
          10,
        ].map((e) => '/$e').toList(),
      ),
      children: [
        PathBranchLocation(
          path: r'/:id(\d+)',
          builder: (context, path) => AppPage(
            title: 'User ${PathNavigator.of(context).params['id']}',
            paths: const [
              '/posts',
              '/comments',
            ],
            children: [
              Text(PathNavigator.of(context).params.toString()),
            ],
          ),
          children: [
            PathLocation(
              path: '/posts',
              builder: (context, path) => AppPage(
                title:
                    'Posts for User ${PathNavigator.of(context).params['id']}',
              ),
            ),
            PathLocation(
              path: '/comments',
              builder: (context, path) => AppPage(
                title:
                    'Comments for User ${PathNavigator.of(context).params['id']}',
                children: [
                  Text('params: ${PathNavigator.of(context).params}'),
                  Text('query: ${PathNavigator.of(context).query}'),
                  Text('fragment: ${PathNavigator.of(context).fragment}'),
                  Text('child path: ${PathNavigator.of(context).childPath}'),
                  Text('segment: ${PathNavigator.of(context).segment}'),
                  Text('parent path: ${PathNavigator.of(context).parentPath}'),
                  Text('full path: ${PathNavigator.of(context).fullPath}'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    PathBranchLocation(
      path: '/posts',
      builder: (context, path) => AppPage(
        title: 'Posts',
        paths: [
          3,
          7,
          25,
        ].map((e) => '/$e').toList(),
      ),
      children: [
        PathLocation(
          path: r'/:id(\d+)',
          builder: (context, path) =>
              AppPage(title: 'Post ${PathNavigator.of(context).params['id']}'),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PathInput(
            path: path,
            onChanged: (path) => setState(() => this.path = path),
            paths: const [
              '/',
              '/users/1/posts',
              '/posts/27',
              'https://example.com/users/1/comments?sort=asc#comments',
            ],
            builder: (context, path) => PathNavigator(
              path: path,
              onChanged: (path) => setState(() => this.path = path),
              locations: locations,
            ),
          ),
        ),
      ],
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.paths,
    this.children,
  });

  final String? title;
  final List<String>? paths;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            const TimeAliveWidget(),
            const SizedBox(height: 32),
            if (paths != null)
              Wrap(
                spacing: 8,
                children: paths!
                    .map(
                      (e) => ActionChip(
                        onPressed: () => PathNavigator.of(context).change(e),
                        label: Text(e),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 32),
            if (children != null) ...children!,
          ],
        ),
      ),
    );
  }
}
