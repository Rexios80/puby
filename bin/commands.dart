import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart';
import 'package:puby/command.dart';
import 'package:io/ansi.dart';
import 'package:puby/engine.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';

import 'link.dart';
import 'projects.dart';

abstract class Commands {
  static final clean =
      ProjectCommand(['clean'], parallel: true, engine: Engine.flutter);
  static final link = GlobalCommand(
    ['link'],
    (command, projects) =>
        linkDependencies(command: command, projects: projects),
  );
  static final pubGetOffline =
      ProjectCommand(['pub', 'get', '--offline'], parallel: true);

  static final convenience = <String, List<Command>>{
    'gen': [
      ProjectCommand(
        [
          'run',
          'build_runner',
          'build',
          '--delete-conflicting-outputs',
        ],
        engine: Engine.dart,
      ),
    ],
    'run': [
      ProjectCommand(['run'], engine: Engine.dart),
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

  /// Check if we should continue after this line is received
  static bool shouldKill(Project project, Command command, String line) {
    if (project.fvm) {
      final flutterVersionNotInstalledMatch =
          RegExp(r'Flutter SDK: SDK Version : (.+?) is not installed\.')
              .firstMatch(line);
      if (flutterVersionNotInstalledMatch != null) {
        // FVM will ask for input from the user, kill the process to avoid
        // hanging
        if (!command.silent) {
          print(
            red.wrap(
              'Run `fvm install ${flutterVersionNotInstalledMatch[1]}` first',
            ),
          );
        }
        return true;
      }
    }
    return false;
  }
}

extension ProjectCommandExtension on ProjectCommand {
  static const _decoder = Utf8Decoder();

  Future<int> runInProject(Project project) async {
    final stopwatch = Stopwatch()..start();

    final resolved = project.resolveWithCommand(this);
    if (resolved.exclude) return 0;

    final finalArgs = [
      if (!raw) ...resolved.prefixArgs,
      ...args,
    ];

    final argString = finalArgs.join(' ');
    final pathString =
        resolved.path == '.' ? 'current directory' : resolved.path;
    if (!silent) {
      print(green.wrap('Running "$argString" in $pathString...'));
    }

    final process = await Process.start(
      finalArgs.first,
      finalArgs.sublist(1),
      workingDirectory: resolved.path,
      runInShell: true,
    );

    // Piping directly to stdout and stderr can cause unexpected behavior
    var killed = false;
    final err = <String>[];
    final stdoutFuture = process.stdout
        .takeWhile((_) => !killed)
        .map(_decoder.convert)
        .listen((line) {
      if (!silent) {
        stdout.write(line);
      }
      if (!raw && Commands.shouldKill(resolved, this, line)) {
        killed = process.kill();
      }
    }).asFuture();
    final stderrFuture = process.stderr
        .takeWhile((_) => !killed)
        .map(_decoder.convert)
        .listen((line) {
      if (!silent) {
        stderr.write(red.wrap(line));
      }
      err.add(line);
    }).asFuture();

    final exitCode = await process.exitCode;

    if (!killed) {
      // If we do not wait for these streams to finish, output could end up
      // out of order
      // Do not wait if the process was killed since the streams won't output,
      // and these futures do not complete in some cases
      await Future.wait([stdoutFuture, stderrFuture]);
    }

    stopwatch.stop();

    // Skip error handling if the command was successful or this is a raw command
    if (raw || exitCode == ExitCode.success.code) {
      print(
        green.wrap(
          'Ran "$argString" in $pathString (${stopwatch.prettyPrint()})',
        ),
      );
    } else if (exitCode == ExitCode.usage.code) {
      // Do not attempt to run in other projects if the command is unknown
      print(red.wrap('Unknown command. Exiting...'));
      exit(exitCode);
    }

    return exitCode;
  }
}
