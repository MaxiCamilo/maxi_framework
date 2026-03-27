import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/app_managers/native_dart/directories/process_native_route.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/transformers.dart';

class NativeFolderOperator with DisposableMixin, AsynchronouslyInitializedMixin implements FolderOperator {
  @override
  final FolderReference folderReference;

  final NativeAppManager appManager;

  String nativeDirectRoute = '';
  String nativeLocationRoute = '';

  NativeFolderOperator({required this.folderReference, required this.appManager});

  @override
  Future<Result<void>> performInitialize() async {
    final processRouteResult = await ProcessNativeRoute(reference: folderReference, appManager: appManager).execute();
    if (processRouteResult.itsFailure) return processRouteResult.cast();

    nativeLocationRoute = processRouteResult.content.$1;
    nativeDirectRoute = processRouteResult.content.$2;

    if (nativeLocationRoute.last == '/') {
      nativeLocationRoute = nativeLocationRoute.substring(0, nativeLocationRoute.length - 1);
    }

    if (nativeDirectRoute.last == '/') {
      nativeDirectRoute = nativeDirectRoute.substring(0, nativeDirectRoute.length - 1);
    }

    return voidResult;
  }

  @override
  Future<Result<FolderReference>> copy({required FolderReference destination}) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final isExists = await exists().checkCancelation();

    if (isExists.itsFailure) return isExists.cast();
    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.unacceptedState,
        message: FlexibleOration(message: 'Cannot copy folder %1, as it does not exist', textParts: [nativeDirectRoute]),
      );
    }

    //final parentOperator = heart.joinDisposableObject(NativeFolderOperator(folderReference: parent.content));

    //final createdParent = await parentOperator.create().connect();
    //if (createdParent.itsFailure) return createdParent.cast();
    return usingHeart((heart) async {
      final newPatch = heart.lifecycleScope.joinDisposableObject(NativeFolderOperator(folderReference: destination, appManager: appManager));
      final createdPatch = await newPatch.create().checkCancelation();
      if (createdPatch.itsFailure) return createdPatch.cast();

      final dir = Directory(newPatch.nativeDirectRoute);

      await for (final entity in dir.list(recursive: true, followLinks: true)) {
        if (heart.itWasDiscarded) {
          final cancel = CancelationResult<FolderReference>();
          (appManager as ApplicationManager).exceptionChannel.sendItem((cancel, StackTrace.current));
          return cancel;
        }

        final relative = p.relative(entity.path, from: nativeDirectRoute);
        final newPath = p.join(newPatch.nativeDirectRoute, relative);

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
  }

  FutureResult<bool> existFolderLocation() async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    if (folderReference.router.isEmpty) {
      return true.asResultValue();
    }

    final mainFolderOperatorResult = folderReference.obtainFolderLocation();
    if (mainFolderOperatorResult.itsFailure) return mainFolderOperatorResult.cast();
    final mainFolderOperator = mainFolderOperatorResult.content;

    if (mainFolderOperator.router.isEmpty) {
      return true.asResultValue();
    }

    return mainFolderOperator.buildOperator().exists().checkCancelation();
  }

  FutureResult<void> _createFolderLocation() async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final routes = <FolderReference>[];
    FolderReference current = folderReference;

    do {
      if (current.router.isEmpty) {
        break;
      }
      final parentResult = current.obtainFolderLocation();
      if (parentResult.itsFailure) return parentResult.cast();
      current = parentResult.content;

      final existFolder = await current.buildOperator().exists().checkCancelation();
      if (existFolder.itsFailure) return existFolder.cast();
      if (existFolder.content) {
        break;
      }

      routes.add(current);
    } while (true);

    for (int i = routes.length - 1; i >= 0; i--) {
      final createResult = await routes[i].buildOperator().create(createFolderRoute: false).checkCancelation();
      if (createResult.itsFailure) return createResult.cast();
    }

    return voidResult;
  }

  @override
  Future<Result<void>> create({bool createFolderRoute = false}) async {
    final initializationResult = await initialize().checkCancelation();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final existFolderLocationResult = await existFolderLocation().checkCancelation();
    if (existFolderLocationResult.itsFailure) return existFolderLocationResult.cast();

    if (!existFolderLocationResult.content) {
      if (createFolderRoute) {
        final createFolderResult = await _createFolderLocation();
        if (createFolderResult.itsFailure) return createFolderResult.cast();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.nonExistent,
          message: FlexibleOration(message: 'The folder location %1 does not exist. So the folder %2 cannot be created', textParts: [nativeLocationRoute, nativeDirectRoute]),
        );
      }
    }

    final isExists = await exists().checkCancelation();
    if (isExists.itsFailure) return isExists.cast();
    if (isExists.content) return voidResult;

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to create a folder in %1, the system returned error %2', textParts: [nativeDirectRoute, ex.toString()]),
      ),
      function: () async {
        final folder = Directory(nativeDirectRoute);
        await folder.create(recursive: true);
      },
    );
  }

  @override
  Future<Result<void>> delete() async {
    final initializationResult = await initialize().checkCancelation();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().checkCancelation();
    if (isExists.itsFailure) return isExists.cast();
    if (!isExists.content) return voidResult;

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to delete a folder in %1, the system returned error %2', textParts: [nativeDirectRoute, ex.toString()]),
      ),
      function: () async {
        final folder = Directory(nativeDirectRoute);
        await folder.delete(recursive: true);
      },
    ).checkCancelation();
  }

  @override
  Future<Result<bool>> exists() async {
    final initializationResult = await initialize().checkCancelation();

    if (initializationResult.itsFailure) return initializationResult.cast();

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'An error occurred while checking the existence of folder %1, the system reported %2', textParts: [nativeDirectRoute, ex.toString()]),
      ),
      function: () {
        final folder = Directory(nativeDirectRoute);
        return folder.exists();
      },
    );
  }

  @override
  Future<Result<bool>> itHasContent() async {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().checkCancelation();
    if (isExists.itsFailure) return isExists.cast();

    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The folder %1 does not exist', textParts: [nativeDirectRoute]),
      );
    }

    return volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to check if directory %1 was empty; system reported %2', textParts: [nativeDirectRoute, ex.toString()]),
      ),
      function: () async {
        await for (final _ in Directory(nativeDirectRoute).list()) {
          return true;
        }
        return false;
      },
    );
  }

  @override
  Future<Result<int>> obtainSize() async {
    final initializationResult = await initialize().checkCancelation();
    if (initializationResult.itsFailure) return initializationResult.cast();

    final isExists = await exists().checkCancelation();
    if (isExists.itsFailure) return isExists.cast();

    if (!isExists.content) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The folder %1 does not exist', textParts: [nativeDirectRoute]),
      );
    }

    return usingHeart((heart) async {
      int size = 0;
      await for (final entity in Directory(nativeDirectRoute).list(recursive: true, followLinks: false)) {
        if (heart.itWasDiscarded) {
          return CancelationResult();
        }
        if (entity is File) {
          size += await entity.length();
        }
      }
      return ResultValue(content: size);
    });
  }

  @override
  Stream<FileReference> obtainFiles() async* {
    final initializationResult = await initialize();
    if (initializationResult.itsFailure) {
      throw initializationResult.error;
    }
    final heart = LifeCoordinator.tryGetZoneHeart;
    await for (final entity in Directory(nativeDirectRoute).list(recursive: true, followLinks: true).whereType<File>()) {
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
    await for (final entity in Directory(nativeDirectRoute).list(recursive: true, followLinks: true).whereType<Directory>()) {
      if (heart != null && heart.itWasDiscarded) {
        break;
      }
      yield FolderReference.interpretRoute(route: entity.path, isLocal: false).content;
    }
  }

  @override
  FutureResult<String> obtainCompleteRoute() async {
    final initResult = await initialize();
    if (initResult.itsFailure) return initResult.cast();
    return ResultValue(content: nativeDirectRoute);
  }
}
