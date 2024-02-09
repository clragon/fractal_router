# fractal_router

Infinitely recursive router for Flutter.

We dream of a world where routing is independent, scoped and composable.
Lets dive.

## Quick Start

fractal_router is meant to be intuitive.
here is how you define your routes:

```dart
  FractalRoute(
    path: '/',
    builder: (context, router) => HomeScreen(),
  ),
  FractalRoute(
    path: '/books',
    builder: (context, router) => BooksScreen(),
    routes: [
      FractalRoute(
        path: '/:id',
        builder: (context, router) => BookScreen(router.params['id']),
      ),
    ]
  ),
```

here is how you navigate:

```dart
  // We are in /books
  FractalRouter.of(context).change('1');
  // navigates to /books/1
```

and here is how you go back:

```dart
  // We are in /books/1
  Navigator.of(context).pop();
  // navigates to /books
```
