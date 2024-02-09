import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Parses [RouteInformation] from a [RouteInformationProvider] to a [Uri],
/// which is understood by [FractalDelegate].
class FractalParser extends RouteInformationParser<Uri> {
  const FractalParser();

  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture(routeInformation.uri);

  @override
  RouteInformation? restoreRouteInformation(Uri configuration) =>
      RouteInformation(uri: configuration);
}
