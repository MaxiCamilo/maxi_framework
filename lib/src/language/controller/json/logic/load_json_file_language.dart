import 'dart:convert';

import 'package:maxi_framework/maxi_framework.dart';

class LoadJsonFileLanguage with FunctionalityMixin<List<ReferenceOration>> {
  final FileReference file;
  final int maxFileSize;

  const LoadJsonFileLanguage({required this.file, required this.maxFileSize});

  @override
  FutureResult<List<ReferenceOration>> runInternalFuncionality() async {
    final fileOperator = file.buildOperator();

    final existsResult = await fileOperator.exists();
    if (!existsResult.itsCorrect) {
      return existsResult.asResultValue();
    }
    if (!existsResult.content) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The language JSON file does not exist at: %1', textParts: [file.completeRoute]),
      );
    }

    final readResult = await fileOperator.readText(maxSize: maxFileSize);
    if (!readResult.itsCorrect) {
      return readResult.asResultValue();
    }

    final rawResult = tryFunction(FlexibleOration(message: 'Failed to parse language JSON file at: %1', textParts: [file.completeRoute]), () => json.decode(readResult.content));

    if (!rawResult.itsCorrect) {
      return rawResult.asResultValue();
    }

    final convertResult = tryFunction(
      FlexibleOration(message: 'The file %1 does not have a valid format; it must be a list composed of JSON objects', textParts: [file.completeRoute]),
      () => (rawResult.content as List).map((e) => e as Map<String, dynamic>).toList(),
    );

    if (!convertResult.itsCorrect) {
      return convertResult.asResultValue();
    }

    return tryFunction(FlexibleOration(message: 'Failed to convert language JSON file at: %1', textParts: [file.completeRoute]), () => convertResult.content.map((e) => ReferenceOration.fromMap(e)).toList());
  }
}
