import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart' show IterableNumberExtension;
import 'package:maxi_framework/maxi_framework.dart';

mixin HexadecimalUtilities {
  static const int uint32MaxValue = 4294967295;
  static const int uint16MaxValue = 32767;
  static const int uint8MaxValue = 255;

  static const _referencesTable = <int, String>{0: "0", 1: "1", 2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9", 10: "A", 11: "B", 12: "C", 13: "D", 14: "E", 15: "F"};

  static Result<List<int>> serialize32Bits(int numero) {
    if (numero > uint32MaxValue) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'It is not possible to convert the number value to a 32-bit binary, because it exceeds its maximum (%1)', textParts: [numero]),
      );
    }

    if (numero < 0) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'It is not possible to convert the number value to a 32-bit binary, because it is negative'),
      );
    }

    List<int> list = [];

    list.add((numero >> 24) & 0xFF);
    list.add((numero >> 16) & 0xFF);
    list.add((numero >> 8) & 0xFF);
    list.add((numero >> 0) & 0xFF);

    return list.asResultValue();
  }

  static Result<List<int>> serialize8Bits(int numero) {
    if (numero > uint8MaxValue) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'It is not possible to convert the number value to a 8-bit binary, because it exceeds its maximum (%1)', textParts: [numero]),
      );
    }

    if (numero < 0) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'It is not possible to convert the number value to a 8-bit binary, because it is negative'),
      );
    }

    return [(numero >> 0) & 0xFF].asResultValue();
  }

  static Result<List<int>> serialize16Bits(int numero) {
    if (numero > uint16MaxValue) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'It is not possible to convert the number value to a 16-bit binary, because it exceeds its maximum (%1)', textParts: [numero]),
      );
    }

    if (numero < 0) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'It is not possible to convert the number value to a 16-bit binary, because it is negative'),
      );
    }

    List<int> lista = [];

    lista.add((numero >> 8) & 0xFF);
    lista.add((numero >> 0) & 0xFF);

    return lista.asResultValue();
  }

  static Result<int> interpretNumber(List<int> bytes, {bool fromLowestToHighest = true}) {
    if (!fromLowestToHighest) {
      bytes = bytes.reversed.toList();
    }

    int numero = 0;
    int va = 0;
    for (int i = bytes.length - 1; i >= 0; i--) {
      final item = bytes[i];
      numero += item * pow(16, va).toInt();

      va += 2;
    }

    return numero.asResultValue();
  }

  static Result<String> passListNumbersToHex(List<int> numbers, [String separator = '']) => numbers.map((e) => e.toRadixString(16)).join(separator).asResultValue();

  static Result<String> generateDebugging(List<int> numbers) {
    final buffer = StringBuffer();
    buffer.write('-> Was: ${DateTime.now().toString()}\n');
    buffer.write('-> Size: ${numbers.length} bytes\n');
    buffer.write('       |  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16    123456789123456\n');
    buffer.write('       | ----------------------------------------------------------------------------------\n');
    int va = 0;

    for (int offset = 0; offset < numbers.length; offset += 16) {
      final end = min(offset + 16, numbers.length);
      final parte = numbers.sublist(offset, end);
      final offsetTextRaw = va.toString();
      final offsetText = offsetTextRaw.length > 6 ? offsetTextRaw.substring(0, 6) : offsetTextRaw.padRight(6, ' ');
      buffer.write('$offsetText | ');

      for (final item in parte) {
        final hexText = item.toRadixString(16).toUpperCase().padLeft(2, '0');
        buffer.write('$hexText  ');
      }

      for (int i = 16 - parte.length; i > 0; i--) {
        buffer.write('    ');
      }

      buffer.write('  ');

      for (final item in parte) {
        if (item < 32) {
          buffer.write('◌');
        } else {
          buffer.write(latin1.decode([item]));
        }
      }

      buffer.write('\n');
      va = va + 16;
    }

    buffer.write('--------------------------------------------------------------------------------------------\n\n');

    return buffer.toString().asResultValue();
  }

  static Result<void> addDebugging(String direccion, List<int> datos, [String? titulo]) {
    titulo ??= '';
    try {
      final archvio = File(direccion);

      if (titulo.isNotEmpty) {
        archvio.writeAsStringSync('$titulo\n', mode: FileMode.append);
      }

      final generatedData = generateDebugging(datos);
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

  static Result<bool> getBit({required int number, required int position}) {
    if (position > 7) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'A 1-byte number must be between 0 and 7.'),
      );
    }

    //Si es 7, con saber si es impar ya da el resultado
    if (position == 7) {
      return (number % 2 == 1).asResultValue();
    }

    final lista = <int>[];
    for (int i = 0; i <= position; i++) {
      final potencia = pow(2, 7 - i);
      final dio = lista.sum + potencia <= number;

      if (i == position) {
        return dio.asResultValue();
      } else if (dio) {
        lista.add(potencia.toInt());
      }
    }

    return NegativeResult.controller(
      code: ErrorCode.abnormalOperation,
      message: const FixedOration(message: 'This functionality should not be here'),
    );
  }

  static Result<List<bool>> convertByteToBinary(int numero) {
    if (numero < 0 || numero > uint8MaxValue) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'A 1-byte number must be between 0 and %1.', textParts: [uint8MaxValue]),
      );
    }

    final retorno = <bool>[];
    final lista = <int>[];

    for (int i = 0; i < 8; i++) {
      final potencia = pow(2, 7 - i);
      bool dio = lista.sum + potencia <= numero;

      retorno.add(dio);
      if (dio) {
        lista.add(potencia.toInt());
      }
    }

    return retorno.asResultValue();
  }

  static Result<int> generateByteFromBinary(List<bool> dato) {
    if (dato.length != 8) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'A 1-byte number must be 8 bites.'),
      );
    }

    int dio = 0;

    for (int i = 0; i < 8; i++) {
      if (dato[i]) {
        dio += pow(2, 7 - i).toInt();
      }
    }

    return dio.asResultValue();
  }

  static Result<int> changeBitFromByte({required int number, required int position, required bool value}) {
    if (position > 7) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'A 1-byte number must be between 0 and 7'),
      );
    }

    final serializadoResult = convertByteToBinary(number);
    if (serializadoResult.itsFailure) {
      return serializadoResult.cast<int>();
    }

    var serializado = serializadoResult.content;

    if (serializado[position] == value) {
      return number.asResultValue();
    }

    serializado[position] = value;

    return generateByteFromBinary(serializado);
  }

  static Result<int> passLiteralHexEquivalentNumeric(String numero) {
    if (numero.length > 2) {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'The number %1 has 2 digits'),
      );
    } else if (numero.length == 2) {
      for (final item in _referencesTable.entries) {
        int maximo = 0;
        if (item.value[0] == numero[0]) {
          maximo = item.key * 16;
          for (final otroItem in _referencesTable.entries) {
            if (otroItem.value[0] == numero[1]) {
              return (maximo + otroItem.key).asResultValue();
            }
          }
          return NegativeResult.controller(
            code: ErrorCode.wrongType,
            message: const FixedOration(message: 'The number %1 is not hexadecimal valid number'),
          );
        }
      }
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'The number %1 is not hexadecimal valid number'),
      );
    } else if (numero.length == 1) {
      for (final item in _referencesTable.entries) {
        if (item.value == numero) {
          return item.key.asResultValue();
        }
      }
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: const FixedOration(message: 'The number %1 is not hexadecimal valid number'),
      );
    } else {
      return 0.asResultValue();
    }
  }

  static Result<String> convertLiteralListHexToString(Iterable<int> data) {
    final buffer = StringBuffer();
    for (final item in data) {
      final raw = item.toRadixString(16);
      if (raw.length == 1) {
        buffer.write('0$raw');
      } else {
        buffer.write(raw);
      }
    }

    return buffer.toString().asResultValue();
  }
}
