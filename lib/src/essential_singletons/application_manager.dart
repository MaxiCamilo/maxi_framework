import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ApplicationManager {
  static ApplicationManager? _singleton;

  static ApplicationManager get singleton {
    if (_singleton == null) {
      throw ControlledFailure(
        errorCode: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The first application operator must enter'),
      );
    }

    return _singleton!;
  }

  static Future<void> defineSingleton(ApplicationManager appManager) async {
    if (_singleton != null) {
      if (_singleton is Disposable) {
        (_singleton as Disposable).dispose();
      }
      _singleton = null;
    }

    if (appManager is Initializable) {
      final result = (appManager as Initializable).initialize();
      if (!result.itsCorrect) {
        throw result.error;
      }
    }

    if (appManager is AsynchronouslyInitialized) {
      final result = await (appManager as AsynchronouslyInitialized).initialize();
      if (!result.itsCorrect) {
        throw result.error;
      }
    }

    _singleton = appManager;
  }

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
}
