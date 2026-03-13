import 'package:maxi_framework/maxi_framework.dart';

class ProcessNativeRoute with FunctionalityMixin<(String, String)> {
  final DirectoryReference reference;
  final NativeAppManager appManager;

  const ProcessNativeRoute({required this.reference, required this.appManager});

  @override
  FutureResult<(String, String)> runInternalFuncionality() async {
    late String nativeLocationRoute;
    late String nativeDirectRoute;

    if (reference.isLocal) {
      final workingPathResult = await appManager.getWorkingPath();
      if (workingPathResult.itsFailure) return workingPathResult.cast();

      if (reference.router.isEmpty) {
        nativeLocationRoute = workingPathResult.content.replaceAll('\\', '/');
      } else {
        nativeLocationRoute = '${workingPathResult.content}/${reference.router}'.replaceAll('\\', '/');
      }
      nativeLocationRoute = nativeLocationRoute.replaceAll(DirectoryReference.prefixRouteLocal, '');
      nativeDirectRoute = '$nativeLocationRoute/${reference.name}'.replaceAll('\\', '/');
    } else {
      if (reference.router.trim().contains(DirectoryReference.prefixRouteLocal)) {
        final workingPathResult = await appManager.getWorkingPath();
        if (workingPathResult.itsFailure) return workingPathResult.cast();

        nativeLocationRoute = reference.router.replaceAll(DirectoryReference.prefixRouteLocal, workingPathResult.content).replaceAll('\\', '/');
      } else if (reference.router.trim().isEmpty) {
        final workingPathResult = await appManager.getWorkingPath();
        if (workingPathResult.itsFailure) return workingPathResult.cast();

        nativeLocationRoute = workingPathResult.content.replaceAll('\\', '/');
      } else {
        nativeLocationRoute = reference.router.replaceAll('\\', '/');
      }
      nativeDirectRoute = '$nativeLocationRoute/${reference.name}'.replaceAll('\\', '/');
    }
    return ResultValue(content: (nativeLocationRoute, nativeDirectRoute));
  }
}
