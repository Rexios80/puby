import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> testCommand(
  List<String> arguments, {
  String workingDirectory = 'test_resources',
}) async {
  final levels = workingDirectory.split('/').length;
  final root = '../' * levels;
  final process = await Process.start(
    'dart',
    ['${root}bin/puby.dart', ...arguments],
    workingDirectory: workingDirectory,
  );

  process.stdout.map(Utf8Decoder().convert).listen(print);
  return ProcessResult(
    process.pid,
    await process.exitCode,
    null,
    null,
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
