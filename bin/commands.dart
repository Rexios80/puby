import 'dart:convert';
import 'dart:io';

import 'package:puby/command.dart';
import 'package:puby/engine.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';

import 'link.dart';
import 'projects.dart';

abstract class Commands {
  static final clean = ProjectCommand(['clean'], parallel: true);
  static final link = GlobalCommand(
    ['link'],
    (command, projects) =>
        linkDependencies(command: command, projects: projects),
  );
  static final pubGetOffline =
      ProjectCommand(['pub', 'get', '--offline'], parallel: true);

  static final convenience = <String, List<Command>>{
    'gen': [
      ProjectCommand([
        'pub',
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]),
    ],
    'test': [
      ProjectCommand(['test']),
    ],
    'clean': [
      clean,
    ],
    'mup': [
      ProjectCommand(['pub', 'upgrade', '--major-versions']),
    ],
    'reset': [
      clean,
      ProjectCommand(['pub', 'get']),
    ],
    'link': [
      link,
      pubGetOffline,
    ],
    'relink': [
      clean,
      link,
      pubGetOffline,
    ],
  };
}

extension ProjectCommandExtension on ProjectCommand {
  static const _decoder = Utf8Decoder();

  Future<int> runInProject(Project project) async {
    final stopwatch = Stopwatch()..start();

    final resolved = project.resolveWithCommand(this);
    if (resolved.exclude) return 0;

    final finalArgs = [
      if (!raw) ...resolved.engine.prefixArgs,
      ...args,
      if (!raw) ...resolved.engine.suffixArgs,
    ];

    final argString = finalArgs.join(' ');
    final pathString =
        resolved.path == '.' ? 'current directory' : resolved.path;
    if (!silent) {
      print(greenPen('Running "$argString" in $pathString...'));
    }

    final process = await Process.start(
      finalArgs.first,
      finalArgs.sublist(1),
      workingDirectory: resolved.path,
      runInShell: true,
    );

    // Piping directly to stdout and stderr can cause unexpected behavior
    final err = <String>[];
    final stdoutFuture = process.stdout.map(_decoder.convert).listen((line) {
      if (!silent) {
        stdout.write(line);
      }
    }).asFuture();
    final stderrFuture = process.stderr.map(_decoder.convert).listen((line) {
      if (!silent) {
        stderr.write(redPen(line));
      }
      err.add(line);
    }).asFuture();

    final processExitCode = await process.exitCode;

    // If we do not wait for these streams to finish, output could end up
    // out of order
    await Future.wait([stdoutFuture, stderrFuture]);

    stopwatch.stop();
    // Skip error handling if the command was successful or this is a raw command
    if (raw || processExitCode == 0) {
      print(
        greenPen(
          'Ran "$argString" in $pathString (${stopwatch.prettyPrint()})',
        ),
      );

      return processExitCode;
    }

    if (err.any(
      (e) => e.contains(
        'Flutter users should run `flutter pub get` instead of `dart pub get`.',
      ),
    )) {
      // If a project doesn't explicitly depend on flutter, it is not possible
      // to know if it's dependencies require flutter. So retry if that's the
      // reason for failure.
      print(yellowPen('Retrying with "flutter" engine'));
      return runInProject(resolved.copyWith(engine: Engine.flutter));
    }

    final unknownSubcommandMatch =
        RegExp(r'Could not find a subcommand named "(.+?)" for ".+? pub"\.')
            .firstMatch(err.join('\n'));
    if (unknownSubcommandMatch != null) {
      // Do not attempt to run in other projects if the command is unknown
      print(redPen('Unknown command: ${unknownSubcommandMatch[1]}'));
      exit(1);
    }

    return processExitCode;
  }
}
