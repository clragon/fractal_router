import 'package:path_to_regexp/path_to_regexp.dart';

extension UriPathPartsExtension on Uri {
  /// Returns a URI with only a host, scheme, port and userInfo.
  Uri get head => Uri(
        scheme: scheme.isNotEmpty ? scheme : null,
        host: host.isNotEmpty ? host : null,
        port: port != 0 ? port : null,
        userInfo: userInfo.isNotEmpty ? userInfo : null,
      );

  /// Returns a URI with only a query and fragment.
  Uri get tail => Uri(
        query: query.isNotEmpty ? query : null,
        fragment: fragment.isNotEmpty ? fragment : null,
      );

  /// Combines a parent and child URI into a single URI.
  ///
  /// Uses scheme, port, userInfo, host from [parent]
  /// and query, fragment from [child].
  static Uri assemble(Uri parent, Uri child) {
    Uri combined = parent.head.replace(
      pathSegments: [
        ...parent.pathSegments,
        ...child.pathSegments,
      ],
    ).resolveUri(child.tail);
    return combined.formatted();
  }

  /// Returns a well-formed URI.
  ///
  /// Removes trailing slashes.
  Uri formatted() {
    String result = path;
    if (result.length > 1 && result.split('').last == '/') {
      result = result.substring(0, result.length - 1);
    }
    return replace(path: result);
  }

  /// Returns a URI with a leading slash.
  Uri asRoot() {
    if (!path.startsWith('/')) {
      return replace(path: '/$path');
    }
    return this;
  }

  /// Combines this URI with a child URI.
  /// Inherits scheme, port, userInfo, host from this URI
  /// and query, fragment from [child].
  Uri withChild(Uri child) => assemble(this, child);

  /// Combines this URI with a parent URI.
  /// Inherits scheme, port, userInfo, host from [parent]
  /// and query, fragment from this URI.
  Uri withParent(Uri parent) => assemble(parent, this);
}

/// Helps matching a URI path to a list of paths.
class UriPathNode {
  /// Creates a root node with a list of children.
  factory UriPathNode.from(Iterable<String> paths) {
    return UriPathNode('')..insertAll(paths);
  }

  /// Creates an empty node.
  UriPathNode(this.value, [this.parent]) : children = {};

  /// The value of the node.
  /// This is a segment of the path.
  final String value;

  /// The parent node of this node.
  /// This is null for the root node.
  final UriPathNode? parent;

  /// The children of this node.
  /// This represents all the possible next segments of the path.
  final Map<String, UriPathNode> children;

  /// Inserts a path below this node.
  void insert(String path) {
    List<String> segments = path.split('/');

    UriPathNode node = this;
    for (final segment in segments) {
      if (segment.isNotEmpty) {
        node.children.putIfAbsent(segment, () => UriPathNode(segment, node));
        node = node.children[segment]!;
      }
    }
  }

  /// Inserts a list of paths below this node.
  void insertAll(Iterable<String> paths) {
    for (final path in paths) {
      insert(path);
    }
  }

  /// Matches a path below this node.
  ///
  /// Returns the best match. This is the deepest node that
  /// matches the path at least partially.
  ///
  /// Example:
  ///
  /// ```dart
  /// final node = UriPathNode.from(['/a', '/a/b', '/a/c']);
  /// node.match('/a/b/c'); // returns '/a/b'
  /// ```
  ///
  /// Node paths may also contain regular expressions in
  /// the usual path to regexp format. e.g. `/a/:b(\d+)`.
  UriPathNode? match(String path) {
    print('Matching $path');
    List<String> segments = Uri.parse(path).pathSegments;
    UriPathNode node = this;
    UriPathNode? bestMatch;

    for (final segment in segments) {
      if (segment.isNotEmpty) {
        bool match = false;
        for (final MapEntry(:key, :value) in node.children.entries) {
          RegExp regex = pathToRegExp(key);
          print('Matching $segment with $key (${regex.pattern})');
          if (regex.hasMatch(segment)) {
            print('Matched $segment with $key. continuing with $value');
            node = value;
            bestMatch = node;
            match = true;
            break;
          }
        }
        print('Matched $segment: $match');
        if (!match) break;
      }
    }

    return bestMatch;
  }

  /// Removes a path below this node.
  void remove(String path) {
    UriPathNode? node;
    List<String> segments = Uri.parse(path).pathSegments;
    for (final segment in segments) {
      if (segment.isNotEmpty) {
        node = children[segment];
        if (node == null) break;
      }
    }
    if (node != null) {
      node.parent!.children.remove(node.value);
    }
  }

  /// Removes a list of paths below this node.
  void removeAll(List<String> paths) {
    for (final path in paths) {
      remove(path);
    }
  }

  /// Returns the full path of this node.
  String getFullPath() {
    final segments = <String>[];
    UriPathNode? node = this;
    while (node?.parent != null) {
      segments.add(node!.value);
      node = node.parent;
    }
    return segments.reversed.join('/');
  }

  @override
  String toString() => 'UriPathNode(${getFullPath()}, ${children.keys})';
}
