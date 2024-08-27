import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:puby/command.dart';
import 'package:puby/config.dart';
import 'package:puby/engine.dart';
import 'package:io/ansi.dart';
import 'package:puby/project.dart';
import 'package:path/path.dart' as p;

List<Project> findProjects() {
  final pubspecEntities = Directory.current
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((e) => e.path.endsWith('pubspec.yaml'));

  final fvmPaths = Directory.current
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((e) => e.path.endsWith('.fvmrc'))
      .map((e) => e.parent.path)
      .toSet();

  final projects = <Project>[];
  for (final pubspecEntity in pubspecEntities) {
    final absolutePath = pubspecEntity.parent.path;
    final path = p.relative(absolutePath);
    final config = PubyConfig.fromProjectPath(path);

    late final Pubspec? pubspec;
    try {
      pubspec = Pubspec.parse(pubspecEntity.readAsStringSync());
    } catch (e) {
      print(yellow.wrap('Error parsing pubspec: $path'));
      pubspec = null;
    }

    final Engine engine;
    if (fvmPaths.any(absolutePath.startsWith)) {
      engine = Engine.fvm;
    } else if (pubspec?.dependencies['flutter'] != null) {
      engine = Engine.flutter;
    } else {
      engine = Engine.dart;
    }

    final example = path.split(Platform.pathSeparator).last == 'example';
    final hidden = path
        .split(Platform.pathSeparator)
        .any((e) => e.length > 1 && e.startsWith('.'));

    final project = Project(
      engine: engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
    );

    projects.add(project);
  }

  return projects;
}

extension ProjectExtension on Project {
  Engine _resolveEngine(Command command) {
    final isCleanCommand = command.args[0] == 'clean';
    final isTestCoverageCommand = command.args.length >= 2 &&
        command.args[0] == 'test' &&
        command.args[1] == '--coverage';

    final Engine newEngine;
    final String? message;
    if (isCleanCommand && !engine.isFlutter) {
      newEngine = Engine.flutter;
      message = 'Overriding engine to "flutter" for "clean" command';
    } else if (isTestCoverageCommand && !engine.isFlutter) {
      newEngine = Engine.flutter;
      message = 'Overriding engine to "flutter" for "test --coverage" command';
    } else if (engine == Engine.fvm && command.noFvm) {
      newEngine = Engine.flutter;
      message = 'Project uses FVM, but FVM support is disabled: $path';
    } else {
      newEngine = engine;
      message = null;
    }

    if (message != null && !command.silent) {
      print(yellow.wrap(message));
    }
    return newEngine;
  }

  bool _defaultExclude(Command command) {
    final isPubGetInFlutterExample = engine.isFlutter &&
        example &&
        command.args.length >= 2 &&
        command.args[0] == 'pub' &&
        command.args[1] == 'get';

    final bool skip;
    final String? message;
    if (hidden) {
      // Skip hidden folders
      message = 'Skipping hidden project: $path';
      skip = true;
    } else if (path.startsWith('build/') || path.contains('/build/')) {
      message = 'Skipping project in build folder: $path';
      skip = true;
    } else if (isPubGetInFlutterExample) {
      // Skip flutter pub get in example projects since flutter does it anyways
      message = 'Skipping flutter example project: $path';
      skip = true;
    } else {
      message = null;
      skip = false;
    }

    if (message != null && !command.silent) {
      print(yellow.wrap(message));
    }
    return skip;
  }

  bool _explicitExclude(Command command) {
    final argString = command.args.join(' ');

    final skip = config.excludes.any(argString.startsWith);
    if (skip && !command.silent) {
      print(yellow.wrap('Skipping project with exclusion: $path'));
    }

    return skip;
  }

  Project resolveWithCommand(Command command) {
    final resolvedEngine = _resolveEngine(command);
    final exclude = _defaultExclude(command) || _explicitExclude(command);
    return copyWith(engine: resolvedEngine, exclude: exclude);
  }

  Future<Version?> getFlutterVersionOverride(Command command) async {
    if (engine != Engine.fvm || command.noFvm) return null;

    try {
      final result = await Process.run(
        'fvm',
        ['flutter', '--version', '--machine', '--fvm-skip-input'],
        workingDirectory: path,
      );
      final stdout = result.stdout as String;
      final versionString =
          RegExp(r'"frameworkVersion": "(.+?)"').firstMatch(stdout)?.group(1);
      if (versionString == null) {
        throw 'Version string is null';
      }
      return Version.parse(versionString);
    } catch (e) {
      print(red.wrap('Unable to determine FVM Flutter version: $path'));
      return null;
    }
  }
}
