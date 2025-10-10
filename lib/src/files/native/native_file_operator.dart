import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/extensions/result_extensions.dart';

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
  Future<Result<FileOperator>> copy({required FolderReference destination}) => encapsulatedFunction((heart) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final destinationOperator = heart.joinDisposableObject(NativeFolderOperator(folderReference: destination));

    final existsFolder = await destinationOperator.exists().connect();

    if (!existsFolder.itsCorrect) return existsFolder.cast();
    if (!existsFolder.content) {
      final createdFolder = await destinationOperator.create().connect();
      if (!createdFolder.itsCorrect) return createdFolder.cast();
      /*
      return NegativeResult.controller(
        code: ErrorCode.contextInvalidFunctionality,
        message: FlexibleOration(message: 'The file %1 could not be copied because it does not exist', textParts: [nativeRoute]),
      );*/
    }

    final creatorResult = await destinationOperator.create().connect();
    if (!creatorResult.itsCorrect) return creatorResult.cast();

    final newFile = NativeFileOperator(
      fileReference: FileReference(isLocal: fileReference.isLocal, name: fileReference.name, router: destination.completeRoute),
    );

    final existsFile = await newFile.exists().connect();
    if (!existsFile.itsCorrect) return existsFile.cast();

    if (existsFile.content) {
      final deleteFile = await newFile.delete().connect();
      if (!deleteFile.itsCorrect) return deleteFile.cast();
    }

    return await volatileFuture<FileOperator>(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'The file %1 could not be copied; the system returned an error: %2', textParts: [nativeRoute, ex.toString()]),
      ),

      function: () async {
        final instance = File(nativeRoute);
        await instance.copy(destinationOperator.nativeRoute);
        return newFile;
      },
    );
  });

  @override
  Future<Result<void>> create() async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    if (!await File(nativeRoute).exists()) {
      final creationFile = await volatileFuture(
        error: (ex, st) => NegativeResult.controller(
          code: ErrorCode.externalFault,
          message: FlexibleOration(message: 'Failed to create the file in %1, the system returned an error: %2', textParts: [nativeRoute, ex.toString()]),
        ),
        function: () => File(nativeRoute).create(),
      );
      if (!creationFile.itsCorrect) return creationFile.cast();
    }

    return voidResult;
  }

  @override
  Future<Result<void>> delete() async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final existsFile = await exists().connect();
    if (!existsFile.itsCorrect) return existsFile.cast();

    if (existsFile.content) {
      await volatileFuture(
        error: (ex, st) => NegativeResult.controller(
          code: ErrorCode.externalFault,
          message: FlexibleOration(message: 'Failed to delete the file in %1, the system returned an error: %2', textParts: [nativeRoute, ex.toString()]),
        ),
        function: () => File(nativeRoute).delete(),
      );
    }

    return voidResult;
  }

  @override
  Future<Result<bool>> exists() async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'An error occurred while checking if file %1 exists, the system returned: %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () => File(nativeRoute).exists(),
    );
  }

  @override
  Future<Result<int>> obtainSize() async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final existsFile = await exists().connect();
    if (!existsFile.itsCorrect) return existsFile.cast();

    if (!existsFile.content) {
      return ResultValue(content: 0);
    }

    return await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to get the file size for %1, the system returned an error: %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () => File(nativeRoute).length(),
    );
  }

  @override
  Future<Result<List<int>>> read({int? maxSize}) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final existsFile = await exists().connect();
    if (!existsFile.itsCorrect) return existsFile.cast();

    if (existsFile.content) {
      if (maxSize != null) {
        final actualSize = await obtainSize().connect();
        if (!actualSize.itsCorrect) return actualSize.cast();

        if (actualSize.content > maxSize) {
          return NegativeResult.controller(
            code: ErrorCode.contextInvalidFunctionality,
            message: FlexibleOration(
              message: 'The file located at %1 cannot be read because its size exceeds the allowed limit (%2 kb > %3 kb)',
              textParts: [nativeRoute, (actualSize.content ~/ 1024), (maxSize ~/ 1024)],
            ),
          );
        }
      }

      return volatileFuture(
        error: (ex, st) => NegativeResult.controller(
          code: ErrorCode.externalFault,
          message: FlexibleOration(message: 'Could not read the file at %1, the system returned the error: %2', textParts: [nativeRoute, ex.toString()]),
        ),
        function: () => File(nativeRoute).readAsBytes(),
      );
    } else {
      final createdFile = await create().connect();
      if (!createdFile.itsCorrect) return createdFile.cast();

      return ResultValue(content: Uint8List.fromList(const []));
    }
  }

  @override
  Future<Result<List<int>>> readPartially({required int from, required int amount}) async {
    if (amount == 0) {
      return ResultValue(content: Uint8List.fromList([]));
    }

    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final fileSize = await obtainSize().connect();
    if (fileSize.itsFailure) return fileSize.cast();

    if (fileSize.content == 0) {
      return ResultValue(content: Uint8List.fromList([]));
      /*
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The file located at %1 could not be read because it does not exist or empty', textParts: [nativeRoute]),
      );*/
    }

    if ((from + amount) >= fileSize.content) {
      amount = fileSize.content - from;
    }

    if (from >= fileSize.content || amount <= 0) {
      return ResultValue(content: Uint8List.fromList([]));
    }

    final createdLector = await volatileFuture<RandomAccessFile>(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Could not create a reader for file %1, the system returned %2', textParts: [nativeRoute, ex.toString()]),
      ),

      function: () => File(nativeRoute).open(mode: FileMode.read),
    );

    if (createdLector.itsFailure) return createdLector.cast();

    final positionResult = await volatileFuture(
      onError: () => createdLector.content.close(),
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Could not position the file reader %1, the system reported: %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () => createdLector.content.setPosition(from),
    );

    if (positionResult.itsFailure) return positionResult.cast();

    return volatileFuture<List<int>>(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Could not read part of file %1, the system reported: %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () => createdLector.content.read(amount),
      onDone: () => createdLector.content.close(),
    );
  }

  @override
  Future<Result<String>> readText({Encoding? encoder, int? maxSize}) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final existsFile = await exists().connect();
    if (!existsFile.itsCorrect) return existsFile.cast();

    if (existsFile.content) {
      if (maxSize != null) {
        final actualSize = await obtainSize().connect();
        if (!actualSize.itsCorrect) return actualSize.cast();

        if (actualSize.content > maxSize) {
          return NegativeResult.controller(
            code: ErrorCode.contextInvalidFunctionality,
            message: FlexibleOration(
              message: 'The file located at %1 cannot be read because its size exceeds the allowed limit (%2 kb > %3 kb)',
              textParts: [nativeRoute, (actualSize.content ~/ 1024), (maxSize ~/ 1024)],
            ),
          );
        }
      }

      return volatileFuture(
        error: (ex, st) => NegativeResult.controller(
          code: ErrorCode.externalFault,
          message: FlexibleOration(message: 'Could not read the file at %1, the system returned the error: %2', textParts: [nativeRoute, ex.toString()]),
        ),
        function: () => File(nativeRoute).readAsString(encoding: encoder ?? utf8),
      );
    } else {
      final createdFile = await create().connect();
      if (!createdFile.itsCorrect) return createdFile.cast();

      return ResultValue(content: '');
    }
  }

  @override
  Future<Result<void>> white({required List<int> content}) => encapsulatedFunction((heart) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final isExists = await exists();
    if (isExists.itsFailure) return isExists.cast();

    if (!isExists.content) {
      final folder = await FolderReference.fromFile(file: fileReference);
      if (folder.itsFailure) return folder.cast();

      final folderOperator = heart.joinDisposableObject(NativeFolderOperator(folderReference: folder.content));

      final createdFolder = await folderOperator.create();
      if (!createdFolder.itsCorrect) return createdFolder.cast();
    }

    final creationResult = await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to write the information to file %1, as a system error occurred in %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () => File(nativeRoute).writeAsBytes(content),
    );

    return creationResult.itsCorrect ? voidResult : creationResult.cast();
  });

  @override
  Future<Result<void>> writeText({required String content, Encoding? encoder}) => encapsulatedFunction((heart) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    final isExists = await exists();
    if (isExists.itsFailure) return isExists.cast();

    if (!isExists.content) {
      final folder = await FolderReference.fromFile(file: fileReference);
      if (folder.itsFailure) return folder.cast();

      final folderOperator = heart.joinDisposableObject(NativeFolderOperator(folderReference: folder.content));

      final createdFolder = await folderOperator.create();
      if (!createdFolder.itsCorrect) return createdFolder.cast();
    }

    final creationResult = await volatileFuture(
      error: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to write the information to file %1, as a system error occurred in %2', textParts: [nativeRoute, ex.toString()]),
      ),
      function: () => File(nativeRoute).writeAsString(content),
    );

    return creationResult.itsCorrect ? voidResult : creationResult.cast();
  });
}
