import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

final _decoder = Utf8Decoder();

Future<ProcessResult> testCommand(
  List<String> arguments, {
  String workingDirectory = 'test_resources',
  bool debug = false,
}) async {
  final levels = workingDirectory.split('/').length;
  final root = '../' * levels;
  final process = await Process.start(
    'dart',
    ['${root}bin/puby.dart', ...arguments],
    workingDirectory: workingDirectory,
  );

  String handleLine(dynamic line) {
    final decoded = _decoder.convert(line);
    if (debug) print(decoded);
    return decoded;
  }

  final stdout = process.stdout.map(handleLine).join('\n');
  final stderr = process.stderr.map(handleLine).join('\n');

  final exitCode = await process.exitCode;
  return ProcessResult(0, exitCode, await stdout, await stderr);
}

void expectLine(dynamic stdout, List<String> matchers, {bool matches = true}) {
  final lines = (stdout as String).split('\n');
  expect(
    lines.any(
      (line) =>
          matchers.fold(true, (prev, next) => prev && line.contains(next)),
    ),
    matches,
  );
}
