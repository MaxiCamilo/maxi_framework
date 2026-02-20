import 'dart:async';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';

class CheckItsInDebugMode with FunctionalityMixin<bool> {
  const CheckItsInDebugMode();

  @override
  Future<Result<bool>> runFuncionality() async {
    return ResultValue(content: Platform.environment['PUB_ENVIRONMENT'] == 'vscode.dart-code');
  }
}
