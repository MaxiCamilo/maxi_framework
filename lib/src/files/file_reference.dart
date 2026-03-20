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
    if (isLocal) {
      if (router == DirectoryReference.prefixRouteLocal) {
        return '$router/$name';
      } else {
        return router.isNotEmpty ? '${DirectoryReference.prefixRouteLocal}/$router/$name' : '${DirectoryReference.prefixRouteLocal}/$name';
      }
    } else {
      return router.isNotEmpty ? '$router/$name' : name;
    }
  }

  factory FileReference.fromFolder({required FolderReference folder, required String name}) {
    late String route;
    if (folder.isLocal) {
      route = folder.completeRoute.replaceAll(DirectoryReference.prefixRouteLocal, '').trim();
      if (route.first == '/') {
        route = route.substring(1);
      }
    } else {
      route = folder.completeRoute;
    }

    return FileReference(isLocal: folder.isLocal, router: route, name: name);
  }

  static Result<FileReference> interpretRoute({required String route, required bool isLocal}) {
    route = route.trim().replaceAll('\\', '/');

    if (!isLocal && route.startsWith(DirectoryReference.prefixRouteLocal)) {
      isLocal = true;
      route = route.replaceFirst(DirectoryReference.prefixRouteLocal, '').trim();
    }

    if (isLocal && route.first == '/') {
      route = route.substring(1).trim();
    }

    String folders = '';
    late final String name;

    final parts = route.split('/').map((x) => x.trim()).toList();

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

  FileOperator buildOperator() => appManager.buildFileOperator(this);

  
}

abstract interface class FileOperator {
  FileReference get fileReference;

  Future<Result<bool>> exists();
  Future<Result<void>> create({bool createFolderRoute = false});
  Future<Result<FileOperator>> copy({required FolderReference destination});
  Future<Result<void>> delete();
  Future<Result<int>> obtainSize();
  Future<Result<List<int>>> read({int? maxSize});
  Future<Result<List<int>>> readPartially({required int from, required int amount});
  Future<Result<String>> readText({Encoding? encoder, int? maxSize});
  Future<Result<void>> write({required List<int> content});
  Future<Result<void>> writeText({required String content, Encoding? encoder});

  FutureResult<String> obtainCompleteRoute();
}
