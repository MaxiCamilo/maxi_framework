import 'dart:convert';

import 'package:maxi_framework/maxi_framework.dart';

class FileReference implements DirectoryReference {
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

  static Result<FileReference> interpretRoute({required String route, required bool isLocal}) {
    route = route.trim().replaceAll('\\', '/');

    if (route.startsWith(DirectoryReference.prefixRouteLocal)) {
      isLocal = false;
      final nativeRoute = NativeFileSingleton.localRoute;
      if (!nativeRoute.itsCorrect) {
        return nativeRoute.cast<FileReference>();
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
      content: FileReference(isLocal: isLocal, name: name, router: folders),
    );
  }

  String get nameWithoutExtension {
    if (!name.contains('.')) {
      return name;
    }

    final split = name.split('.');
    split.removeLast();
    if (split.length == 1) {
      return split.first;
    } else {
      return split.join('.');
    }
  }

  String get nameExtension {
    if (!name.contains('.')) {
      return '';
    }

    return name.split('.').last;
  }

  const FileReference({required this.isLocal, required this.name, required this.router});

  FileOperator buildOperator() => ApplicationManager.singleton.buildFileOperator(this);
}

abstract interface class FileOperator {
  AsyncResult<bool> exists();
  AsyncResult<void> create();
  AsyncResult<FileOperator> copy({required FolderReference destination});
  AsyncResult<void> delete();
  AsyncResult<int> obtainSize();
  AsyncResult<List<int>> read({int? maxSize});
  AsyncResult<List<int>> readPartially({required int from, required int amount, bool checkSize = true});
  AsyncResult<String> readText({Encoding? encoder, int? maxSize});
  AsyncResult<void> white({required List<int> content, bool secured = false});
  AsyncResult<void> writeText({required String content, Encoding? encoder, bool secured = false});
}
