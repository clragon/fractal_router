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
          paths: ['/books', '/books/1/comments', 'authors'],
        ),
      ),
      /*
       * Below is an example of an immediately defined nested route.
       */
      FractalRoute(
        path: '/books',
        builder: (context, router) => const AppPage(
          title: 'Books',
          paths: ['author', 'delete/forever'],
        ),
        routes: [
          FractalRoute(
            path: '/:bookId',
            builder: (context, router) => AppPage(
              title: 'Book ${router.params['bookId']}',
              paths: const ['comments'],
            ),
            routes: [
              FractalRoute(
                path: '/comments',
                builder: (context, router) => AppPage(
                  title: 'Comments for User ${router.params['bookId']}',
                ),
                routes: [
                  FractalRoute(
                    path: '/:commentId',
                    builder: (context, router) => AppPage(
                      title: 'Comment ${router.params['commentId']}',
                    ),
                  ),
                ],
              ),
            ],
          ),
          /*
           * Below is an example of a route that has multiple path parameters.
           */
          FractalRoute(
            path: '/delete/forever',
            builder: (context, router) => AppPage(
              title: 'Delete ${router.params['bookId']} forever?',
            ),
          ),
          /*
           * Below is an example of a route that redirects to another path.
           */
          FractalRedirectRoute(
            path: '/author',
            redirect: '/authors',
          ),
        ],
      ),
      /*
       * Below is an example of a separately defined nested route.
       * 
       * Note that the `exact` property is set to `false` to allow the nested
       * router to handle the rest of the path.
       */
      FractalRoute(
        path: '/authors',
        builder: (context, router) => const AuthorsPage(),
        exact: false,
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
              /*
               * The FractalParser connects your Router to the platform's
               * URL. This is useful if you wish to handle deeplinks or
               * browser URLs.
               * 
               * You usually only want one FractalParser in your app.
               */
              routeInformationParser: const FractalParser(),
              routerDelegate: _delegate,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthorsPage extends StatelessWidget {
  const AuthorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    /*
     * Below is an example of a nested router that is defined separately from
     * the parent router.
     * 
     * It will automatically connect to the parent router and handle the rest
     * of the path.
     * 
     * If there is no parent router, this router will have its own path.
     * You can also make any router independant by 
     * setting `withParent` to `false` (default is `true`).
     */
    return FractalRouter(
      withParent: true,
      routes: [
        FractalRoute(
          path: '/',
          builder: (context, router) => const AppPage(
            title: 'Authors',
            paths: ['1', '2'],
          ),
        ),
        FractalRoute(
          path: r'/:id(\d+)',
          builder: (context, router) {
            final id = router.params['id'];
            return AppPage(
              title: 'Author $id',
            );
          },
        ),
      ],
    );
  }
}
