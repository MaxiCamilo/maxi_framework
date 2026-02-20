import 'package:maxi_framework/src/error_handling.dart';

abstract interface class NativeAppManager {
  FutureResult<String> getWorkingPath();

  FutureResult<void> defineWorkingPath(String path);
}
