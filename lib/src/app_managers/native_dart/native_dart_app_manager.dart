import 'dart:async';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/app_managers/logic/check_its_in_debug_mode.dart';
import 'package:maxi_framework/src/app_managers/logic/prepare_native_app_workspace.dart';
import 'package:maxi_framework/src/app_managers/native_dart/directories/native_file_operator.dart';
import 'package:maxi_framework/src/app_managers/native_dart/directories/native_folder_operator.dart';

class _NativeDartAppManagerConfig {
  final bool isDebug;
  final String workingPath;

  _NativeDartAppManagerConfig({required this.isDebug, required this.workingPath});
}

class NativeDartAppManager with DisposableMixin, AsynchronouslyInitializedMixin implements ApplicationManager, NativeAppManager, IsolatedReplicableApplicationManager {
  bool _isDebug = false;
  String _currentWorkingPath = '¿?';
  _NativeDartAppManagerConfig? _previousConfig;
  Channel<(dynamic, StackTrace), (dynamic, StackTrace)>? _exceptionChannel;

  final bool _isOriginalInstance;

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

  NativeDartAppManager({required bool isOriginalInstance}) : _isOriginalInstance = isOriginalInstance;

  factory NativeDartAppManager._withConfig(_NativeDartAppManagerConfig config) {
    final manager = NativeDartAppManager(isOriginalInstance: false);
    manager._previousConfig = config;
    manager._isDebug = config.isDebug;
    manager._currentWorkingPath = config.workingPath;
    return manager;
  }

  @override
  Future<Result<void>> performInitialize() async {
    if (!_isOriginalInstance) {
      return voidResult;
    }

    if (_previousConfig != null) {
      _isDebug = _previousConfig!.isDebug;
      _currentWorkingPath = _previousConfig!.workingPath;
      return voidResult;
    }

    final debugModeResult = await CheckItsInDebugMode().execute();
    if (debugModeResult.itsFailure) return debugModeResult.cast();
    _isDebug = debugModeResult.content;

    if (_currentWorkingPath == '¿?') {
      final prepareWorkspaceResult = await PrepareNativeAppWorkspace(isDebug: _isDebug).execute();
      if (prepareWorkspaceResult.itsFailure) return prepareWorkspaceResult.cast();
      _currentWorkingPath = prepareWorkspaceResult.content;
    }

    return voidResult;
  }

  @override
  FileOperator buildFileOperator(FileReference file) => NativeFileOperator(fileReference: file, appManager: this);

  @override
  FolderOperator buildFolderOperator(FolderReference folder) => NativeFolderOperator(folderReference: folder, appManager: this);

  @override
  FutureResult<void> defineWorkingPath(String path) {
    _currentWorkingPath = path;
    return initialize();
  }

  @override
  FutureResult<String> getWorkingPath() async {
    final initResult = await initialize();
    if (initResult.itsFailure) return initResult.cast();
    return ResultValue(content: _currentWorkingPath);
  }

  @override
  FutureResult<Functionality<ApplicationManager>> cloneToIsolate() async {
    final initResult = await initialize();
    if (initResult.itsFailure) return initResult.cast();
    return ResultValue(
      content: _CloneNativeDartAppManager(
        config: _NativeDartAppManagerConfig(isDebug: _isDebug, workingPath: _currentWorkingPath),
      ),
    );
  }

  @override
  Channel<(dynamic, StackTrace), (dynamic, StackTrace)> get exceptionChannel {
    if (_exceptionChannel == null) {
      final master = MasterChannel<(dynamic, StackTrace), (dynamic, StackTrace)>();
      _exceptionChannel = master;
      return master.buildConnector().exceptionIfFails(detail: 'Exception channel for NativeDartAppManager');
    }

    if (_exceptionChannel is MasterChannel<(dynamic, StackTrace), (dynamic, StackTrace)>) {
      return (_exceptionChannel as MasterChannel<(dynamic, StackTrace), (dynamic, StackTrace)>).buildConnector().exceptionIfFails(detail: 'Exception channel for NativeDartAppManager');
    }

    return _exceptionChannel!;
  }

  @override
  Result<void> changeExceptionChannel(Channel<(dynamic, StackTrace), (dynamic, StackTrace)> channel) {
    final itsDiscarded = failIfItsDiscarded();
    if (itsDiscarded.itsFailure) {
      return itsDiscarded.cast();
    }

    if (_exceptionChannel != null) {
      channel.reflectChannel(_exceptionChannel!);
    }
    _exceptionChannel = channel;
    return voidResult;
  }

  @override
  FutureResult<void> changeDebugState(bool isDebug) async {
    final initResult = await initialize();
    if (initResult.itsFailure) return initResult.cast();
    _isDebug = isDebug;
    return voidResult;
  }
}

class _CloneNativeDartAppManager with FunctionalityMixin<ApplicationManager> {
  final _NativeDartAppManagerConfig config;

  _CloneNativeDartAppManager({required this.config});

  @override
  FutureOr<Result<ApplicationManager>> runInternalFuncionality() => NativeDartAppManager._withConfig(config).asResultValue();
}
