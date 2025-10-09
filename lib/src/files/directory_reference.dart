abstract interface class DirectoryReference {
  static const String prefixRouteLocal = '%appdata%';

  bool get isLocal;

  String get name;

  String get router;

  String get completeRoute;
}
