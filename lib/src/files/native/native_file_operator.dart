import 'dart:convert';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class NativeFileOperator with AsynchronouslyInitializedMixin implements FileOperator {
  final FileReference fileReference;

  String nativeRoute = '';

  NativeFileOperator({required this.fileReference});

  @override
  Future<Result<void>> performInitialize() async {
    nativeRoute = fileReference.completeRoute;
    final containPrefix = nativeRoute.contains(DirectoryReference.prefixRouteLocal);
    if (!fileReference.isLocal && !containPrefix) {
      return voidResult;
    }

    final localRoute = NativeFileSingleton.localRoute;
    if (!localRoute.itsCorrect) {
      return localRoute.cast();
    }

    if (fileReference.isLocal) {
      if (containPrefix) {
        log('[WARNING] The address has a prefix');
        nativeRoute.replaceAll(DirectoryReference.prefixRouteLocal, '');
      }
      nativeRoute = '${localRoute.content}/$nativeRoute';
    } else {
      nativeRoute.replaceAll(DirectoryReference.prefixRouteLocal, localRoute.content);
    }

    return voidResult;
  }

  @override
  AsyncResult<void> create() {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  AsyncResult<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  AsyncResult<bool> exists() {
    // TODO: implement exists
    throw UnimplementedError();
  }

  @override
  AsyncResult<int> obtainSize() {
    // TODO: implement obtainSize
    throw UnimplementedError();
  }

  @override
  AsyncResult<List<int>> read({int? maxSize}) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  AsyncResult<List<int>> readPartially({required int from, required int amount, bool checkSize = true}) {
    // TODO: implement readPartially
    throw UnimplementedError();
  }

  @override
  AsyncResult<String> readText({Encoding? encoder, int? maxSize}) {
    // TODO: implement readText
    throw UnimplementedError();
  }

  @override
  AsyncResult<void> white({required List<int> content, bool secured = false}) {
    // TODO: implement white
    throw UnimplementedError();
  }

  @override
  AsyncResult<void> writeText({required String content, Encoding? encoder, bool secured = false}) {
    // TODO: implement writeText
    throw UnimplementedError();
  }

  @override
  AsyncResult<FileOperator> copy({required FolderReference destination}) => quickAsyncResult(() async {
    final initializationResult = await initialize();
    final heart = ParentController.zoneHeart;
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final destinationOperator = NativeFolderOperator(folderReference: destination);
    final existsFolder = await heart.waitAsyncResult(destinationOperator.exists());

    if (!existsFolder.itsCorrect) return existsFolder.cast();

    final creatorResult = await heart.waitAsyncResult(destinationOperator.create());
    if (!creatorResult.itsCorrect) return creatorResult.cast();

    final newFile = NativeFileOperator(
      fileReference: FileReference(isLocal: fileReference.isLocal, name: fileReference.name, router: destination.completeRoute),
    );

    final existsFile = await heart.waitAsyncResult(newFile.exists());
    if (!existsFile.itsCorrect) return existsFile.cast();

    if (existsFile.content) {
    } else {
      
    }
  });
}
