import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> testCommand(List<String> arguments) {
  return Process.run(
    'dart',
    ['../bin/puby.dart', ...arguments],
    workingDirectory: 'test_resources',
  );
}

void expectLine(dynamic stdout, List<String> matchers) {
  final lines = (stdout as String).split('\n');
  expect(
    lines.any(
      (line) =>
          matchers.fold(true, (prev, next) => prev && line.contains(next)),
    ),
    isTrue,
  );
}
