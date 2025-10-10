import 'dart:developer';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:path/path.dart' as p;

class NativeFolderOperator with AsynchronouslyInitializedMixin implements FolderOperator {
  final FolderReference folderReference;

  String nativeRoute = '';

  NativeFolderOperator({required this.folderReference});

  @override
  Future<Result<void>> performInitialize() async {
    nativeRoute = folderReference.completeRoute;
    final containPrefix = nativeRoute.contains(DirectoryReference.prefixRouteLocal);
    if (!folderReference.isLocal && !containPrefix) {
      return voidResult;
    }

    final localRoute = NativeFileSingleton.localRoute;
    if (!localRoute.itsCorrect) {
      return localRoute.cast();
    }

    if (folderReference.isLocal) {
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
  Future<Result<FolderReference>> copy({required FolderReference destination}) => encapsulatedFunction((heart) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final isExists = await exists().connect();
    if (isExists.itsFailure) return isExists.cast();
    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.contextInvalidFunctionality,
        message: FlexibleOration(message: 'Cannot copy folder %1, as it does not exist', textParts: [nativeRoute]),
      );
    }

    //final parentOperator = heart.joinDisposableObject(NativeFolderOperator(folderReference: parent.content));

    //final createdParent = await parentOperator.create().connect();
    //if (createdParent.itsFailure) return createdParent.cast();

    final newPatch = heart.joinDisposableObject(NativeFolderOperator(folderReference: destination));
    final createdPatch = await newPatch.create().connect();
    if (createdPatch.itsFailure) return createdPatch.cast();

    return encapsulatedFunction((heart) async {
      final dir = Directory(newPatch.nativeRoute);

      await for (final entity in dir.list(recursive: true, followLinks: true)) {
        if (heart.itWasDiscarded) {
          return CancelationResult(cancelationStackTrace: StackTrace.current);
        }

        final relative = p.relative(entity.path, from: nativeRoute);
        final newPath = p.join(newPatch.nativeRoute, relative);

        if (entity is Directory) {
          final directoryCreated = await volatileFuture(
            error: (ex, st) => NegativeResult.controller(
              code: ErrorCode.externalFault,
              message: FlexibleOration(message: 'Could not copy folder %1 to %2, the system returned: %3', textParts: [entity.path, newPath, ex.toString()]),
            ),
            function: () => Directory(newPath).create(recursive: true),
          );
          if (directoryCreated.itsFailure) return directoryCreated.cast();
        } else if (entity is File) {
          final fileCreated = await volatileFuture(
            error: (ex, st) => NegativeResult.controller(
              code: ErrorCode.externalFault,
              message: FlexibleOration(message: 'Could not copy file %1 to %2, the system returned: %3', textParts: [entity.path, newPath, ex.toString()]),
            ),
            function: () async {
              final newFile = File(newPath);
              await newFile.parent.create(recursive: true);
              if (await newFile.exists()) {
                await newFile.delete();
              }
              await entity.copy(newFile.path);
            },
          );
          if (fileCreated.itsFailure) return fileCreated.cast();
        } else if (entity is Link) {
          final linkCreated = await volatileFuture(
            error: (ex, st) => NegativeResult.controller(
              code: ErrorCode.externalFault,
              message: FlexibleOration(message: 'Could not copy link %1 to %2, the system returned: %3', textParts: [entity.path, newPath, ex.toString()]),
            ),
            function: () async {
              final linkTarget = await entity.target();
              final newLink = Link(newPath);
              if (await newLink.exists()) {
                await newLink.delete();
              }
              await newLink.create(linkTarget, recursive: true);
            },
          );

          if (linkCreated.itsFailure) return linkCreated.cast();
        }
      }

      return ResultValue(content: destination);
    });
  });

  @override
  Future<Result<void>> create() {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> exists() {
    // TODO: implement exists
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> itHasContent() {
    // TODO: implement itHasContent
    throw UnimplementedError();
  }

  @override
  Stream<FileReference> obtainFiles() {
    // TODO: implement obtainFiles
    throw UnimplementedError();
  }

  @override
  Stream<FolderOperator> obtainFolders() {
    // TODO: implement obtainFolders
    throw UnimplementedError();
  }

  @override
  Future<Result<int>> obtainSize() {
    // TODO: implement obtainSize
    throw UnimplementedError();
  }
}
