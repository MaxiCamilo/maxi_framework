import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/language/controller/json/logic/load_json_file_language.dart';

class LoadJsonPrefix with FunctionalityMixin<List<ReferenceOration>> {
  final List<FolderReference> directories;
  final String prefix;
  final int maxFileSize;

  const LoadJsonPrefix({required this.directories, required this.prefix, this.maxFileSize = 21 * 1024 * 1024});

  @override
  FutureResult<List<ReferenceOration>> runInternalFuncionality() async {
    final texts = <ReferenceOration>[];
    final objetiveFile = '$prefix.json';

    for (final folder in directories.map((x) => x.buildOperator())) {
      final existsResult = await folder.exists();
      if (!existsResult.itsCorrect) {
        return existsResult.asResultValue();
      }
      if (!existsResult.content) {
        continue;
      }

      await for (final file in folder.obtainFiles()) {
        final nameFile = file.name;
        if (objetiveFile != nameFile) {
          continue;
        }

        final loadResult = await LoadJsonFileLanguage(file: file, maxFileSize: maxFileSize).execute();
        if (!loadResult.itsCorrect) {
          return loadResult.asResultValue();
        }
        texts.addAll(loadResult.content);
      }
    }

    return ResultValue(content: texts);
  }
}
