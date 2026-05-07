import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/language/generators/seart_oration_in_proyects.dart';
import 'package:test/test.dart';

class SearchOrationInProjectsProbe extends SearchOrationInProjects {
  const SearchOrationInProjectsProbe({required super.projectsAddresses});

  FutureResult<List<ReferenceOration>> run() => runInternalFuncionality();
}

void main() {
  test('SearchOrationInProjects extracts dart orations recursively', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('search_oration_in_projects_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final nestedDirectory = Directory('${tempDirectory.path}/lib/src/nested');
    await nestedDirectory.create(recursive: true);

    await File('${nestedDirectory.path}/messages.dart').writeAsString('''
const fixed = FixedOration(message: 'Hello', tokenID: 'hello.id');

final flexible = FlexibleOration(
  message: 'Line 1\\nLine 2',
  textParts: [1, 2],
);

final outer = FlexibleOration(
  message: 'Outer',
  textParts: [FixedOration(message: 'Inner', tokenID: 'inner.id')],
);

final skipped = FixedOration(message: dynamicMessage);
''');

    await File('${tempDirectory.path}/ignored.txt').writeAsString("const ignored = FixedOration(message: 'Ignored');");

    final result = await SearchOrationInProjectsProbe(projectsAddresses: [tempDirectory.path]).run();

    expect(result.itsCorrect, isTrue);

    final items = result.content;
    expect(items, hasLength(4));

    final hello = items.firstWhere((item) => item.message == 'Hello');
    expect(hello.tokenID, 'hello.id');
    expect(hello.translation, 'Hello');

    final multiline = items.firstWhere((item) => item.message == 'Line 1\nLine 2');
    expect(multiline.tokenID, Oration.buildAutomaticTokenID(typeKey: 'flexible', message: 'Line 1\nLine 2'));
    expect(multiline.translation, 'Line 1\nLine 2');

    final outer = items.firstWhere((item) => item.message == 'Outer');
    expect(outer.tokenID, Oration.buildAutomaticTokenID(typeKey: 'flexible', message: 'Outer'));

    final inner = items.firstWhere((item) => item.message == 'Inner');
    expect(inner.tokenID, 'inner.id');
    expect(inner.translation, 'Inner');
  });
}
