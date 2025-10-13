import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/essential_singletons/application_managers/dart_application_manager/check_its_in_debug_mode.dart';

class DartApplicationManager with AsynchronouslyInitializedMixin implements ApplicationManager {
  final bool useWorkingPathInDebug;
  final bool? _isDefinedDebug;

  bool _isDebug = false;

  DartApplicationManager({this.useWorkingPathInDebug = true, bool? isDebug}) : _isDefinedDebug = isDebug;

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

    final routeResult = await NativeFileSingleton.defineRoute(getterRoute: DartLocalRouteDefiner(isDebug: _isDebug), omittedIfDefined: false);
    if (routeResult.itsFailure) return routeResult.cast();

    return voidResult;
  }

  @override
  FileOperator buildFileOperator(FileReference file) => NativeFileOperator(fileReference: file);

  @override
  FolderOperator buildFolderOperator(FolderReference folder) => NativeFolderOperator(folderReference: folder);
}
