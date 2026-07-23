import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import 'package:puby/command.dart';
import 'package:puby/text.dart';
import 'package:puby/time.dart';

/// The maximum number of file paths to pass to `dart format` at once to
/// avoid exceeding OS argument length limits
const _batchSize = 500;

bool _shouldSkipDirectory(String name) =>
    name == 'build' || name.startsWith('.');

/// Recursively collect all `.dart` file paths under [directory], skipping
/// `build` folders and hidden directories (e.g. `.dart_tool`, `.git`)
List<String> _collectDartFiles(Directory directory) {
  final files = <String>[];

  void walk(Directory dir) {
    List<FileSystemEntity> entities;
    try {
      entities = dir.listSync(followLinks: false);
    } catch (_) {
      return;
    }

    for (final entity in entities) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (_shouldSkipDirectory(name)) continue;
        walk(entity);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        files.add(p.relative(entity.path));
      }
    }
  }

  walk(directory);
  return files;
}

/// Run `dart format` in the current directory, excluding any files inside
/// `build` (or other tool-generated) folders
Future<int> runFormat(GlobalCommand command) async {
  final stopwatch = Stopwatch()..start();

  final files = _collectDartFiles(Directory.current);
  if (files.isEmpty) {
    print(yellow.wrap('No dart files found to format'));
    return 0;
  }

  // `command.args` includes the leading `format` token itself (from
  // registration in `Commands.convenience`), so it is skipped here to avoid
  // passing it to `dart format` twice
  final userArgs = command.args.skip(1).toList();

  final fileLabel = pluralize('file', files.length);
  print(
    green.wrap(
      'Running "dart format${userArgs.isEmpty ? '' : ' ${userArgs.join(' ')}'}"'
      ' on ${files.length} $fileLabel...',
    ),
  );

  var exitCode = 0;
  for (var i = 0; i < files.length; i += _batchSize) {
    final batch = files.sublist(
      i,
      i + _batchSize > files.length ? files.length : i + _batchSize,
    );

    final finalArgs = ['format', ...userArgs, ...batch];
    final process = await Process.start(
      'dart',
      finalArgs,
      workingDirectory: '.',
      runInShell: true,
    );

    const decoder = Utf8Decoder();
    final stdoutFuture =
        process.stdout.map(decoder.convert).listen(stdout.write).asFuture();
    final stderrFuture = process.stderr
        .map(decoder.convert)
        .listen((line) => stderr.write(red.wrap(line)))
        .asFuture();

    final batchExitCode = await process.exitCode;
    await Future.wait([stdoutFuture, stderrFuture]);

    exitCode |= batchExitCode;
  }

  stopwatch.stop();
  if (exitCode == 0) {
    print(
      green.wrap(
        'Ran "dart format" on ${files.length} $fileLabel '
        '(${stopwatch.prettyPrint()})',
      ),
    );
  } else {
    print(
      red.wrap('"dart format" failed (${stopwatch.prettyPrint()})'),
    );
  }

  return exitCode;
}
