import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/essential_singletons/application_managers/dart_application_manager/check_its_in_debug_mode.dart';

class DartApplicationManager with AsynchronouslyInitializedMixin implements ApplicationManager {
  final bool useWorkingPathInDebug;
  final bool? _isDefinedDebug;
  final String? predefinedWorkPath;

  bool _isDebug = false;

  DartApplicationManager({this.useWorkingPathInDebug = true, bool? isDebug, this.predefinedWorkPath}) : _isDefinedDebug = isDebug;

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isFlutter => false;

  @override
  bool get isFuchsia => Platform.isFuchsia;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  bool get isLinux => Platform.isLinux;

  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  bool get isWeb => false;

  @override
  bool get isWindows => Platform.isWindows;

  @override
  bool get isMovil => isAndroid || isIOS;

  @override
  bool get isDebug => isInitialized && _isDebug;

  @override
  bool get isDesktop => isWindows || isLinux || isMacOS;

  @override
  Future<Result<void>> performInitialize() async {
    if (_isDefinedDebug == null) {
      final isDebugResult = await const CheckItsInDebugMode().execute();
      if (isDebugResult.itsFailure) return isDebugResult.cast();
      _isDebug = isDebugResult.content;
    } else {
      _isDebug = _isDefinedDebug;
    }

    if (predefinedWorkPath == null) {
      final routeResult = await NativeFileSingleton.defineRouteByFunctionality(getterRoute: DartLocalRouteDefiner(isDebug: _isDebug), omittedIfDefined: false);
      if (routeResult.itsFailure) return routeResult.cast();
    } else {
      await NativeFileSingleton.defineRoute(route: predefinedWorkPath!);
    }

    return voidResult;
  }

  @override
  FileOperator buildFileOperator(FileReference file) => NativeFileOperator(fileReference: file);

  @override
  FolderOperator buildFolderOperator(FolderReference folder) => NativeFolderOperator(folderReference: folder);

  @override
  Result<ApplicationManager> cloneToIsolate() {
    if (!isInitialized) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'You must first initialize the application engine, in order to be cloned'),
      );
    }

    return ResultValue(
      content: DartApplicationManager(isDebug: _isDebug, predefinedWorkPath: NativeFileSingleton.localRoute.content, useWorkingPathInDebug: useWorkingPathInDebug),
    );
  }
}
