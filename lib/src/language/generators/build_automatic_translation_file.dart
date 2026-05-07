import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/language/chat/automatic_ollama_translation.dart';
import 'package:maxi_framework/src/language/generators/seart_oration_in_proyects.dart';

class BuilAutomaticTranslationFile with FunctionalityMixin<void> {
  final String url;
  final String language;
  final String model;

  final String fileName;
  final List<FolderReference> foldersToSearch;
  final FolderReference outputFolder;
  final String extraContext;

  const BuilAutomaticTranslationFile({
    this.url = 'http://localhost:11434',
    required this.language,
    this.model = 'gemma3:4b',
    required this.fileName,
    required this.foldersToSearch,
    required this.outputFolder,
    this.extraContext = '',
  });

  @override
  FutureResult<void> runInternalFuncionality() async {
    final pathResult = await foldersToSearch.map((x) => x.buildOperator()).resultFutureMap((x) => x.obtainCompleteRoute());
    if (pathResult.itsFailure) {
      return pathResult.cast();
    }

    final searchResult = await SearchOrationInProjects(projectsAddresses: pathResult.content).execute();
    if (searchResult.itsFailure) {
      return searchResult.cast();
    }

    if (searchResult.content.isEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: const FixedOration(message: 'No translations found'),
      );
    }

    final filteredOrations = <ReferenceOration>[];
    final usedTokenIds = <String>{};
    final usedMessages = <String>{};

    for (final item in searchResult.content) {
      final tokenId = item.tokenID.trim();
      if (tokenId.isNotEmpty) {
        if (usedTokenIds.add(tokenId)) {
          filteredOrations.add(item);
        }
        continue;
      }

      final message = item.message.trim();
      if (usedMessages.add(message)) {
        filteredOrations.add(item);
      }
    }

    int i = 0;

    final textsToTranslate = filteredOrations.splitByPart(25);
    for (final part in textsToTranslate) {
      final translationResult = await AutomaticOllamaTranslation(url: url, language: language, model: model, messages: part.map((x) => x.message).toList(), extraContext: extraContext).execute();
      if (translationResult.itsFailure) {
        return translationResult.cast();
      }

      i += part.length;
      log('Progress: $i/${filteredOrations.length}');

      for (final (original, translated) in translationResult.content) {
        final item = filteredOrations.firstWhere((x) => x.message == original);
        item.translation = translated;
      }
    }

    final fileContent = StringBuffer('[\n');

    for (final item in filteredOrations) {
      fileContent.writeln('\t${item.toJson()}${item != filteredOrations.last ? ',' : ''}');
    }

    fileContent.writeln(']');

    final outputFile = FileReference.fromFolder(folder: outputFolder, name: '$fileName.json');
    final writeResult = await outputFile.buildOperator().writeText(content: fileContent.toString());
    if (writeResult.itsFailure) {
      return writeResult.cast();
    }

    return voidResult;
  }
}
