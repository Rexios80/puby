import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  test('link benchmark', () {
    final stopwatch = Stopwatch()..start();
    testCommand(
      ['link'],
      workingDirectory: 'test_resources_3',
      environment: {'PUB_CACHE': '.pub-cache'},
    );
  });
}
