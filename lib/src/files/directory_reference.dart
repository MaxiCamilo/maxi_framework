import 'package:maxi_framework/maxi_framework.dart';

abstract interface class DirectoryReference {
  static const String prefixRouteLocal = '%appdata%';

  bool get isLocal;

  String get name;

  String get router;

  String get completeRoute;
}

extension DirectoryReferenceExtension on DirectoryReference {
  Result<FolderReference> obtainFolderLocation() {
    final slashSplit = router.split('/').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    if (slashSplit.isEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.invalidProperty,
        message: const FixedOration(message: 'The router is empty'),
      );
    }

    final newName = slashSplit.removeLast();
    String newRouter = slashSplit.join('/');

    if (!isLocal && router.first == '/' && newRouter.first != '/') {
      newRouter = '/$newRouter';
    }

    return FolderReference(isLocal: isLocal, name: newName, router: newRouter).asResultValue();
  }
}
