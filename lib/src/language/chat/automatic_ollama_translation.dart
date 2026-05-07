import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';

class AutomaticOllamaTranslation with FunctionalityMixin<List<(String, String)>> {
  final String url;
  final String language;
  final String model;
  final String extraContext;
  final List<String> messages;

  const AutomaticOllamaTranslation({this.url = 'http://localhost:11434', required this.language, this.model = 'gemma3:4b', required this.messages, required this.extraContext});

  @override
  FutureResult<List<(String, String)>> runInternalFuncionality() async {
    final result = <(String, String)>[];

    for (final text in messages) {
      final client = HttpClient();
      final uri = Uri.parse('$url/api/generate');

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'model': model,
          'prompt':
              'Translate to $language. The translation has to be as clear and precise as possible, so analyze the resulting translation carefully.\n\nAvoid translating texts that start with % followed by a number (e.g. %1, %2, %3).\n\n${extraContext.isEmpty ? '' : 'Additional Context: $extraContext\n\n.'} Return ONLY the translated text. This is the text you must translate: "$text"',
          'stream': false,
          'options': {'temperature': 0.1},
        }),
      );

      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        return NegativeResult.controller(
          code: ErrorCode.externalFault,
          message: FlexibleOration(message: 'Failed to get translation from Ollama API for text: %1. Status code: %2. Response: %3', textParts: [text, response.statusCode.toString(), errorBody]),
        ).asResultValue();
      }
      final json = jsonDecode(body) as Map<String, dynamic>;

      log('$text -> ${json['response']}');

      result.add((text, (json['response'] as String).trim()));
    }

    return result.asResultValue();
  }
}
