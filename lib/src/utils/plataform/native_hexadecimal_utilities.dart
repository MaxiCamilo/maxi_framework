import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';

extension NativeHexadecimalUtilities on HexadecimalUtilities {
  static Result<void> addDebugging(String direccion, List<int> datos, [String? titulo]) {
    titulo ??= '';
    try {
      final archvio = File(direccion);

      if (titulo.isNotEmpty) {
        archvio.writeAsStringSync('$titulo\n', mode: FileMode.append);
      }

      final generatedData = HexadecimalUtilities.generateDebugging(datos);
      if (generatedData.itsFailure) {
        return generatedData.cast<void>();
      }

      archvio.writeAsStringSync(generatedData.content, flush: true, mode: FileMode.append);
      return voidResult;
    } catch (ex) {
      return NegativeResult.controller(
        code: ErrorCode.exception,
        message: FlexibleOration(message: 'Error writing debug file: %1', textParts: [ex]),
      );
    }
  }
}
