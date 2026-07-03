import 'package:maxi_framework/maxi_framework.dart';

import 'factories/app_factory_dart.dart' if (dart.library.ui) 'package:maxi_flutter_framework/src/app_managers/app_factory_flutter.dart' if (dart.library.html) 'factories/app_factory_web.dart';

ApplicationManager? _kAppManagerSingleton;
ApplicationManager get appManager {
  _kAppManagerSingleton ??= buildAppManagerImpl();
  return _kAppManagerSingleton!;
}

Result<void> defineAppManager(ApplicationManager appManager) {
  if (_kAppManagerSingleton != null) {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'AppManager is already defined'),
    );
  }
  _kAppManagerSingleton = appManager;
  return voidResult;
}

FutureResult<void> initAppManager() async {
  final current = appManager;
  if (current is Initializable) {
    final initResult = (current as Initializable).initialize();
    if (initResult.itsFailure) {
      return initResult;
    }
  }

  if (current is AsynchronouslyInitialized) {
    final initResult = await (current as AsynchronouslyInitialized).initialize();
    if (initResult.itsFailure) {
      return initResult;
    }
  }

  return voidResult;
}

abstract interface class ApplicationManager {
  bool get isDebug;

  bool get isWeb;
  bool get isLinux;
  bool get isMacOS;
  bool get isWindows;
  bool get isAndroid;
  bool get isIOS;
  bool get isFuchsia;

  bool get isFlutter;

  bool get isDesktop;
  bool get isMovil;

  Channel<(dynamic, StackTrace), (dynamic, StackTrace)> get exceptionChannel;

  Result<void> changeExceptionChannel(Channel<(dynamic, StackTrace), (dynamic, StackTrace)> channel);
  FutureResult<void> changeDebugState(bool isDebug);

  FileOperator buildFileOperator(FileReference file);
  FolderOperator buildFolderOperator(FolderReference folder);
}
