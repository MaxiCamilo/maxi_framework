import 'package:maxi_framework/maxi_framework.dart';

class NativeFolderOperator implements FolderOperator {
  final FolderReference folderReference;

  const NativeFolderOperator({required this.folderReference});

  @override
  AsyncResult<FolderReference> copy({required FolderReference destination}) {
    // TODO: implement copy
    throw UnimplementedError();
  }

  @override
  AsyncResult<void> create() {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  AsyncResult<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  AsyncResult<bool> exists() {
    // TODO: implement exists
    throw UnimplementedError();
  }

  @override
  AsyncResult<bool> itHasContent() {
    // TODO: implement itHasContent
    throw UnimplementedError();
  }

  @override
  Stream<FileReference> obtainFiles() {
    // TODO: implement obtainFiles
    throw UnimplementedError();
  }

  @override
  Stream<FolderOperator> obtainFolders() {
    // TODO: implement obtainFolders
    throw UnimplementedError();
  }

  @override
  AsyncResult<int> obtainSize() {
    // TODO: implement obtainSize
    throw UnimplementedError();
  }
}
