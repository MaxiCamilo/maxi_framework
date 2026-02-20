import 'dart:async';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';

class PrepareNativeAppWorkspace with FunctionalityMixin<String> {
  final bool useWorkingPathInDebug;
  final bool isDebug;

  PrepareNativeAppWorkspace({required this.isDebug, this.useWorkingPathInDebug = true});

  @override
  Future<Result<String>> runFuncionality() async {
    late String route;

    if (useWorkingPathInDebug && isDebug) {
      route = isDebug ? '${Directory.current.path}/debug' : Directory.current.path;
      route = route.replaceAll('\\', '/');
      final direc = Directory(route);
      if (isDebug && !await direc.exists()) {
        final debugFolderResult = await volatileFuture(
          error: (err, st) => ExceptionResult(
            exception: err,
            stackTrace: st,
            message: const FixedOration(message: 'Failed to create debug folder'),
          ),
          function: () => direc.create(),
        );
        if (debugFolderResult.itsFailure) return debugFolderResult.cast();
      }
      return ResultValue(content: route.replaceAll('\\', '/'));
    } else if (useWorkingPathInDebug) {
      route = Directory.current.path;
      return ResultValue(content: route.replaceAll('\\', '/'));
    } else {
      return ResultValue(content: Platform.resolvedExecutable.replaceAll('\\', '/'));
    }
  }
}
