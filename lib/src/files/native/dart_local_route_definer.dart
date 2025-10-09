import 'dart:async';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';

class DartLocalRouteDefiner with FunctionalityMixin<String> {
  final bool useWorkingPathInDebug;
  final bool isDebug;

  const DartLocalRouteDefiner({required this.isDebug, this.useWorkingPathInDebug = true});

  @override
  Future<Result<String>> runFuncionality() async {
    late String route;

    if (useWorkingPathInDebug && isDebug) {
      route = isDebug ? '${Directory.current.path}/debug' : Directory.current.path;
      route = route.replaceAll('\\', '/');
      final direc = Directory(route);
      if (isDebug && !await direc.exists()) {
        await direc.create();
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
