import 'package:maxi_framework/maxi_framework.dart';

import 'factories/app_factory_dart.dart' if (dart.library.ui) 'factories/app_factory_flutter.dart' if (dart.library.html) 'factories/app_factory_web.dart';

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

  FileOperator buildFileOperator(FileReference file);
  FolderOperator buildFolderOperator(FolderReference folder);
}
