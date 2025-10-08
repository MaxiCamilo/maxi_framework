import 'dart:convert';

import 'package:maxi_framework/maxi_framework.dart';

class FileReference {
  final bool isLocal;

  final String name;

  final String router;

  const FileReference({required this.isLocal, required this.name, required this.router});

  FileOperator buildOperator() => ApplicationManager.singleton.buildFileOperator(this);
}

abstract interface class FileOperator {
  AsyncResult<bool> exists();
  AsyncResult<void> createFile();
  AsyncResult<String> copy({required FileReference destination});
  AsyncResult<void> delete();
  AsyncResult<int> obtainSize();
  AsyncResult<List<int>> read({int? maxSize});
  AsyncResult<List<int>> readPartially({required int from, required int amount, bool checkSize = true});
  AsyncResult<String> readText({Encoding? encoder, int? maxSize});
  AsyncResult<void> white({required List<int> content, bool secured = false});
  AsyncResult<void> writeText({required String content, Encoding? encoder, bool secured = false});
  
}
