import 'package:maxi_framework/maxi_framework.dart';

abstract interface class IsolatedReplicableApplicationManager {
  FutureResult<Functionality<ApplicationManager>> cloneToIsolate();
}
