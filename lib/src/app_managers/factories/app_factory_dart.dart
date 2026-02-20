import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/app_managers/native_dart/native_dart_app_manager.dart';

ApplicationManager buildAppManagerImpl() {
  return NativeDartAppManager();
}
