import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> testCommand(String executable, List<String> arguments) {
  return Process.run(executable, arguments, workingDirectory: 'test_resources');
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
