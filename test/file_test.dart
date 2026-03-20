@Timeout(Duration(minutes: 30))
library;


import 'package:test/test.dart';
import 'package:maxi_framework/maxi_framework.dart';

void main() {
  test('Create file', () async {
    final file = FileReference(isLocal: true, name: 'Hi.txt', router: 'test/others/juajua');
    final fileOperator = file.buildOperator();

    await fileOperator.create(createFolderRoute: true).waitContentOrThrow();
  });
}
