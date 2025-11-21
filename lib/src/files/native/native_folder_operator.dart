import 'dart:developer';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/transformers.dart';

class NativeFolderOperator with AsynchronouslyInitializedMixin implements FolderOperator {
  @override
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
  Future<Result<FolderReference>> copy({required FolderReference destination}) => managedFunction((heart) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final isExists = await exists().connect();
    if (isExists.itsFailure) return isExists.cast();
    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.unacceptedState,
        message: FlexibleOration(message: 'Cannot copy folder %1, as it does not exist', textParts: [nativeRoute]),
      );
    }

    //final parentOperator = heart.joinDisposableObject(NativeFolderOperator(folderReference: parent.content));

    //final createdParent = await parentOperator.create().connect();
    //if (createdParent.itsFailure) return createdParent.cast();

    final newPatch = heart.joinDisposableObject(NativeFolderOperator(folderReference: destination));
    final createdPatch = await newPatch.create().connect();
    if (createdPatch.itsFailure) return createdPatch.cast();

    return managedFunction((heart) async {
      final dir = Directory(newPatch.nativeRoute);

      await for (final entity in dir.list(recursive: true, followLinks: true)) {
        if (heart.itWasDiscarded) {
          return  CancelationResult();
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
  Future<Result<void>> create() => managedFunction((heart) async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().connect();
    if (isExists.itsFailure) return isExists.cast();
    if (isExists.content) return voidResult;

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to create a folder in %1, the system returned error %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () async {
        final folder = Directory(nativeRoute);
        await folder.create(recursive: true);
      },
    );
  });

  @override
  Future<Result<void>> delete() => managedFunction((heart) async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().connect();
    if (isExists.itsFailure) return isExists.cast();
    if (!isExists.content) return voidResult;

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to delete a folder in %1, the system returned error %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () async {
        final folder = Directory(nativeRoute);
        await folder.delete(recursive: true);
      },
    );
  });

  @override
  Future<Result<bool>> exists() => managedFunction((heart) async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'An error occurred while checking the existence of folder %1, the system reported %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () {
        final folder = Directory(nativeRoute);
        return folder.exists();
      },
    );
  });

  @override
  Future<Result<bool>> itHasContent() => managedFunction((heart) async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().connect();
    if (isExists.itsFailure) return isExists.cast();

    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The folder %1 does not exist', textParts: [nativeRoute]),
      );
    }

    return volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to check if directory %1 was empty; system reported %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () async {
        await for (final _ in Directory(nativeRoute).list()) {
          return true;
        }
        return false;
      },
    );
  });

  @override
  Future<Result<int>> obtainSize() => managedFunction((heart) async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().connect();
    if (isExists.itsFailure) return isExists.cast();

    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The folder %1 does not exist', textParts: [nativeRoute]),
      );
    }

    int size = 0;
    await for (final entity in Directory(nativeRoute).list(recursive: true, followLinks: false)) {
      if (heart.itWasDiscarded) {
        return  CancelationResult();
      }
      if (entity is File) {
        size += await entity.length();
      }
    }
    return ResultValue(content: size);
  });

  @override
  Stream<FileReference> obtainFiles() async* {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) {
      throw initializationResult.error;
    }
    final heart = LifeCoordinator.tryGetZoneHeart;
    await for (final entity in Directory(nativeRoute).list(recursive: true, followLinks: true).whereType<File>()) {
      if (heart != null && heart.itWasDiscarded) {
        break;
      }
      yield FileReference.interpretRoute(route: entity.path, isLocal: false).content;
    }
  }

  @override
  Stream<FolderReference> obtainFolders() async* {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) {
      throw initializationResult.error;
    }
    final heart = LifeCoordinator.tryGetZoneHeart;
    await for (final entity in Directory(nativeRoute).list(recursive: true, followLinks: true).whereType<Directory>()) {
      if (heart != null && heart.itWasDiscarded) {
        break;
      }
      yield FolderReference.interpretRoute(route: entity.path, isLocal: false).content;
    }
  }
}
