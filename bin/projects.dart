import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:puby/command.dart';
import 'package:puby/config.dart';
import 'package:puby/engine.dart';
import 'package:io/ansi.dart';
import 'package:puby/project.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'commands.dart';

List<Project> findProjects({Directory? directory}) {
  directory ??= Directory.current;
  final pubspecEntities = directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((e) => e.path.endsWith('pubspec.yaml'));

  final fvmPaths = directory
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

    final Pubspec pubspec;
    final YamlMap pubspecYaml;
    try {
      final pubspecContent = pubspecEntity.readAsStringSync();
      pubspec = Pubspec.parse(pubspecContent);
      pubspecYaml = loadYaml(pubspecContent) as YamlMap;
    } catch (e) {
      print(red.wrap('Error parsing pubspec: $path'));
      continue;
    }

    final Engine engine;
    if (pubspec.dependencies['flutter'] != null) {
      engine = Engine.flutter;
    } else {
      engine = Engine.dart;
    }

    final example = path.split(Platform.pathSeparator).last == 'example';
    final hidden = path
        .split(Platform.pathSeparator)
        .any((e) => e.length > 1 && e.startsWith('.'));

    final Set<String> dependencies;

    final projectLockFile = File(p.join(absolutePath, 'pubspec.lock'));
    final workspaceRefParent = p.join(absolutePath, '.dart_tool', 'pub');
    final workspaceRefFile =
        File(p.join(workspaceRefParent, 'workspace_ref.json'));
    final pubspecDependencies = {
      ...pubspec.dependencies.keys,
      ...pubspec.devDependencies.keys,
    };

    Set<String> dependenciesFromLockFile(File file) {
      final lockFileContent = file.readAsStringSync();
      final packagesMap = loadYaml(lockFileContent)['packages'] as YamlMap;
      return packagesMap.keys.cast<String>().toSet();
    }

    if (projectLockFile.existsSync()) {
      dependencies = dependenciesFromLockFile(projectLockFile);
    } else if (workspaceRefFile.existsSync()) {
      final workspaceRefContent = workspaceRefFile.readAsStringSync();
      final json = jsonDecode(workspaceRefContent) as Map<String, dynamic>;
      final workspaceRoot = json['workspaceRoot'] as String;
      final workspaceLockFile =
          File(p.join(workspaceRefParent, workspaceRoot, 'pubspec.lock'));
      if (workspaceLockFile.existsSync()) {
        dependencies = dependenciesFromLockFile(workspaceLockFile);
      } else {
        dependencies = pubspecDependencies;
      }
    } else {
      dependencies = pubspecDependencies;
    }

    final fvm = fvmPaths.any(absolutePath.startsWith);

    final dependencyResolutionStrategy =
        pubspecYaml['resolution'] == 'workspace'
            ? DependencyResolutionStrategy.workspace
            : DependencyResolutionStrategy.standalone;

    final project = Project(
      engine: engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
      dependencies: dependencies,
      fvm: fvm,
      dependencyResolutionStrategy: dependencyResolutionStrategy,
    );

    projects.add(project);
  }

  return projects;
}

extension ProjectExtension on Project {
  Engine _resolveEngine(ProjectCommand command) {
    final commandEngine = command.engine;
    final isTestCoverageCommand = command.args.length >= 2 &&
        command.args[0] == 'test' &&
        command.args.contains('--coverage');

    final Engine newEngine;
    final String? message;
    if (commandEngine != null && engine != commandEngine) {
      newEngine = commandEngine;
      message =
          'Overriding engine to "${commandEngine.name}" for "${command.args.first}" command';
    } else if (isTestCoverageCommand && engine != Engine.flutter) {
      newEngine = Engine.flutter;
      message = 'Overriding engine to "flutter" for "test --coverage" command';
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
    final isPubGetInExample = example &&
        command.args.length >= 2 &&
        command.args[0] == 'pub' &&
        command.args[1] == 'get';

    final String? dartRunPackage;
    if (command.args.length >= 2 && command.args[0] == 'run') {
      dartRunPackage = command.args[1];
    } else {
      dartRunPackage = null;
    }

    final bool skip;
    final String? message;
    if (hidden) {
      // Skip hidden folders
      message = 'Skipping hidden project: $path';
      skip = true;
    } else if (path.startsWith('build/') || path.contains('/build/')) {
      message = 'Skipping project in build folder: $path';
      skip = true;
    } else if (isPubGetInExample) {
      // Skip pub get in example projects since it happens anyways
      message = 'Skipping example project: $path';
      skip = true;
    } else if (dartRunPackage != null &&
        !dependencies.contains(dartRunPackage)) {
      // Skip dart run commands if the project doesn't have the package
      message = 'Skipping project without $dartRunPackage dependency: $path';
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
    final Engine resolvedEngine;
    if (command is ProjectCommand) {
      resolvedEngine = _resolveEngine(command);
    } else {
      resolvedEngine = engine;
    }
    final exclude = _defaultExclude(command) || _explicitExclude(command);

    if (fvm && command.noFvm && !command.silent) {
      print(
        yellow.wrap('Project uses FVM, but FVM support is disabled: $path'),
      );
    }

    return copyWith(
      engine: resolvedEngine,
      exclude: exclude,
      fvm: fvm && !command.noFvm,
    );
  }

  Future<Version?> getFlutterVersionOverride(Command command) async {
    if (!fvm || command.noFvm) return null;

    try {
      // TODO: Do this a better way (https://github.com/leoafarias/fvm/issues/710)
      final process = await Process.start(
        'fvm',
        ['flutter', '--version', '--machine'],
        workingDirectory: path,
      );
      final stdout =
          await process.stdout.map(Utf8Decoder().convert).map((line) {
        if (Commands.shouldKill(this, command, line)) process.kill();
        return line;
      }).join('\n');

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
