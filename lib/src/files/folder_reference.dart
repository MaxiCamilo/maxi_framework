import 'package:maxi_framework/maxi_framework.dart';

class FolderReference implements DirectoryReference {
  @override
  final bool isLocal;
  @override
  final String name;
  @override
  final String router;

  @override
  String get completeRoute {
    return '$router/$name';
  }

  const FolderReference({required this.isLocal, required this.name, required this.router});

  static Result<FolderReference> interpretRoute({required String route, required bool isLocal}) {
    route = route.trim().replaceAll('\\', '/');

    if (route.startsWith(DirectoryReference.prefixRouteLocal)) {
      isLocal = false;
      final nativeRoute = NativeFileSingleton.localRoute;
      if (!nativeRoute.itsCorrect) {
        return nativeRoute.cast<FolderReference>();
      }
      route.replaceAll(DirectoryReference.prefixRouteLocal, nativeRoute.content);
    }

    String folders = '';
    late final String name;

    final parts = route.split('/');

    if (parts.isEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.invalidValue,
        message: FixedOration(message: 'The specified address is empty'),
      );
    } else if (parts.length == 1) {
      name = parts.first;
      folders = '';
    } else {
      name = parts.last;
      final foldersList = <String>[];
      for (int i = 0; i < parts.length - 1; i++) {
        foldersList.add(parts[i]);
      }
      folders = foldersList.join('/');
    }

    return ResultValue(
      content: FolderReference(isLocal: isLocal, name: name, router: folders),
    );
  }
}

abstract interface class FolderOperator {
  AsyncResult<bool> exists();
  AsyncResult<void> create();
  AsyncResult<FolderReference> copy({required FolderReference destination});
  AsyncResult<void> delete();
  AsyncResult<bool> itHasContent();
  AsyncResult<int> obtainSize();
  Stream<FileReference> obtainFiles();
  Stream<FolderOperator> obtainFolders();
}
