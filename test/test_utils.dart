import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> testCommand(
  List<String> arguments, {
  String workingDirectory = 'test_resources',
  Map<String, String> environment = const {},
}) {
  final levels = workingDirectory.split('/').length;
  final root = '../' * levels;
  return Process.run(
    'dart',
    ['${root}bin/puby.dart', ...arguments],
    workingDirectory: workingDirectory,
    environment: environment,
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
