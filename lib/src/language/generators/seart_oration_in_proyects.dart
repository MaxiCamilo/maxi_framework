import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';

class SearchOrationInProjects with FunctionalityMixin<List<ReferenceOration>> {
  final List<String> projectsAddresses;

  const SearchOrationInProjects({required this.projectsAddresses});

  @override
  FutureResult<List<ReferenceOration>> runInternalFuncionality() async {
    return volatileFuture(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'An error occurred while searching orations in the provided projects'),
      ),
      function: () async {
        final results = <ReferenceOration>[];

        for (final projectAddress in projectsAddresses) {
          final directory = Directory(projectAddress);
          if (!await directory.exists()) {
            throw FileSystemException('The project directory does not exist', projectAddress);
          }

          await for (final entity in directory.list(recursive: true, followLinks: false)) {
            if (entity is! File) {
              continue;
            }

            final file = entity;
            if (!file.path.endsWith('.dart')) {
              continue;
            }

            final content = await file.readAsString();
            results.addAll(_extractReferenceOrations(content));
          }
        }

        return results;
      },
    );
  }

  static const List<String> _orationConstructors = ['FixedOration(', 'FlexibleOration('];

  List<ReferenceOration> _extractReferenceOrations(String source) {
    final results = <ReferenceOration>[];
    int cursor = 0;

    while (cursor < source.length) {
      final match = _findNextConstructor(source, cursor);
      if (match == null) {
        break;
      }

      final (constructorIndex, openParenthesisIndex) = match;
      final closeParenthesisIndex = _findMatchingParenthesis(source, openParenthesisIndex);
      if (closeParenthesisIndex == null) {
        cursor = constructorIndex + 1;
        continue;
      }

      final arguments = source.substring(openParenthesisIndex + 1, closeParenthesisIndex);
      final message = _extractNamedStringArgument(arguments, 'message');
      if (message != null) {
        final constructorName = source.substring(constructorIndex, openParenthesisIndex);
        final tokenID = _extractNamedStringArgument(arguments, 'tokenID') ?? _buildAutomaticTokenID(constructorName: constructorName, message: message);
        results.add(
          ReferenceOration()
            ..message = message
            ..translation = message
            ..tokenID = tokenID,
        );
      }

      cursor = constructorIndex + 1;
    }

    return results;
  }

  String _buildAutomaticTokenID({required String constructorName, required String message}) {
    final typeKey = constructorName == 'FlexibleOration' ? 'f' : 't';
    return Oration.buildAutomaticTokenID(typeKey: typeKey, message: message);
  }

  (int, int)? _findNextConstructor(String source, int start) {
    int? constructorIndex;
    int? openParenthesisIndex;

    for (final constructor in _orationConstructors) {
      final index = source.indexOf(constructor, start);
      if (index == -1) {
        continue;
      }

      if (constructorIndex == null || index < constructorIndex) {
        constructorIndex = index;
        openParenthesisIndex = index + constructor.length - 1;
      }
    }

    if (constructorIndex == null || openParenthesisIndex == null) {
      return null;
    }

    return (constructorIndex, openParenthesisIndex);
  }

  int? _findMatchingParenthesis(String source, int openParenthesisIndex) {
    int depth = 0;

    for (int i = openParenthesisIndex; i < source.length; i++) {
      final stringEnd = _skipStringLiteral(source, i);
      if (stringEnd != null) {
        i = stringEnd;
        continue;
      }

      final character = source[i];
      if (character == '(') {
        depth++;
      } else if (character == ')') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }

    return null;
  }

  String? _extractNamedStringArgument(String arguments, String name) {
    int cursor = 0;

    while (cursor < arguments.length) {
      while (cursor < arguments.length && _isIgnoredArgumentCharacter(arguments[cursor])) {
        cursor++;
      }

      if (cursor >= arguments.length) {
        break;
      }

      final nameStart = cursor;
      while (cursor < arguments.length && _isIdentifierCharacter(arguments[cursor])) {
        cursor++;
      }

      if (nameStart == cursor) {
        final end = _findArgumentEnd(arguments, cursor);
        cursor = end == null ? arguments.length : end + 1;
        continue;
      }

      final parameterName = arguments.substring(nameStart, cursor);
      while (cursor < arguments.length && arguments[cursor].trim().isEmpty) {
        cursor++;
      }

      if (cursor >= arguments.length || arguments[cursor] != ':') {
        final end = _findArgumentEnd(arguments, cursor);
        cursor = end == null ? arguments.length : end + 1;
        continue;
      }

      cursor++;
      while (cursor < arguments.length && arguments[cursor].trim().isEmpty) {
        cursor++;
      }

      final valueStart = cursor;
      final valueEnd = _findArgumentEnd(arguments, valueStart) ?? arguments.length;

      if (parameterName == name) {
        return _parseStringLiteral(arguments.substring(valueStart, valueEnd).trim());
      }

      cursor = valueEnd + 1;
    }

    return null;
  }

  int? _findArgumentEnd(String source, int start) {
    int parenthesisDepth = 0;
    int bracketDepth = 0;
    int braceDepth = 0;

    for (int i = start; i < source.length; i++) {
      final stringEnd = _skipStringLiteral(source, i);
      if (stringEnd != null) {
        i = stringEnd;
        continue;
      }

      final character = source[i];
      if (character == ',' && parenthesisDepth == 0 && bracketDepth == 0 && braceDepth == 0) {
        return i;
      }

      if (character == '(') {
        parenthesisDepth++;
      } else if (character == ')') {
        if (parenthesisDepth == 0) {
          return i;
        }
        parenthesisDepth--;
      } else if (character == '[') {
        bracketDepth++;
      } else if (character == ']') {
        bracketDepth--;
      } else if (character == '{') {
        braceDepth++;
      } else if (character == '}') {
        braceDepth--;
      }
    }

    return null;
  }

  int? _skipStringLiteral(String source, int start) {
    int quoteIndex = start;
    bool isRaw = false;

    if (start + 1 < source.length && (source[start] == 'r' || source[start] == 'R') && _isQuote(source[start + 1])) {
      isRaw = true;
      quoteIndex = start + 1;
    } else if (!_isQuote(source[start])) {
      return null;
    }

    final quoteCharacter = source[quoteIndex];
    final isTriple = quoteIndex + 2 < source.length && source[quoteIndex + 1] == quoteCharacter && source[quoteIndex + 2] == quoteCharacter;
    final step = isTriple ? 3 : 1;
    int cursor = quoteIndex + step;

    while (cursor < source.length) {
      if (!isRaw && source[cursor] == r'\') {
        cursor += 2;
        continue;
      }

      if (isTriple) {
        if (cursor + 2 < source.length && source[cursor] == quoteCharacter && source[cursor + 1] == quoteCharacter && source[cursor + 2] == quoteCharacter) {
          return cursor + 2;
        }
      } else if (source[cursor] == quoteCharacter) {
        return cursor;
      }

      cursor++;
    }

    return source.length - 1;
  }

  String? _parseStringLiteral(String value) {
    if (value.isEmpty) {
      return null;
    }

    int quoteIndex = 0;
    bool isRaw = false;

    if (value.length >= 2 && (value[0] == 'r' || value[0] == 'R') && _isQuote(value[1])) {
      isRaw = true;
      quoteIndex = 1;
    } else if (!_isQuote(value[0])) {
      return null;
    }

    final quoteCharacter = value[quoteIndex];
    final isTriple = quoteIndex + 2 < value.length && value[quoteIndex + 1] == quoteCharacter && value[quoteIndex + 2] == quoteCharacter;
    final prefixLength = quoteIndex + (isTriple ? 3 : 1);
    final suffixLength = isTriple ? 3 : 1;
    if (value.length < prefixLength + suffixLength) {
      return null;
    }

    final content = value.substring(prefixLength, value.length - suffixLength);
    if (isRaw) {
      return content;
    }

    return _decodeEscapes(content);
  }

  String _decodeEscapes(String value) {
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      final character = value[i];
      if (character != r'\' || i + 1 >= value.length) {
        buffer.write(character);
        continue;
      }

      final next = value[++i];
      switch (next) {
        case 'n':
          buffer.write('\n');
          break;
        case 'r':
          buffer.write('\r');
          break;
        case 't':
          buffer.write('\t');
          break;
        case '\\':
          buffer.write('\\');
          break;
        case '\'':
          buffer.write('\'');
          break;
        case '"':
          buffer.write('"');
          break;
        default:
          buffer
            ..write('\\')
            ..write(next);
          break;
      }
    }

    return buffer.toString();
  }

  bool _isIdentifierCharacter(String value) {
    final codeUnit = value.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || (codeUnit >= 97 && codeUnit <= 122) || (codeUnit >= 48 && codeUnit <= 57) || value == '_';
  }

  bool _isIgnoredArgumentCharacter(String value) => value.trim().isEmpty || value == ',';

  bool _isQuote(String value) => value == '\'' || value == '"';
}
