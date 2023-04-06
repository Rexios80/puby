import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:puby/config.dart';
import 'package:puby/engine.dart';
import 'package:puby/pens.dart';

/// A dart project
class Project {
  /// The engine this project uses
  final Engine engine;

  /// The relative path to the project
  final String path;

  /// The puby config for this project
  final PubyConfig config;

  /// If this project is an example project
  final bool example;

  /// If this project is in a hidden folder
  final bool hidden;

  Project._({
    required this.engine,
    required this.path,
    required this.config,
    required this.example,
    required this.hidden,
  });

  /// Create a [Project] from a pubspec file
  static Project fromPubspec({
    required File pubspecFile,
    required List<String> fvmPaths,
  }) {
    final absolutePath = pubspecFile.parent.path;
    final path = p.relative(absolutePath);
    final config = PubyConfig.fromProjectPath(path);

    late final Pubspec? pubspec;
    try {
      pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
    } catch (e) {
      print(redPen('Error parsing pubspec: $path'));
      pubspec = null;
    }

    final Engine engine;
    if (fvmPaths.any(absolutePath.contains)) {
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

    return Project._(
      engine: engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
    );
  }

  /// Create a copy of this [Project] with the specified changes
  Project copyWith({Engine? engine}) {
    return Project._(
      engine: engine ?? this.engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
    );
  }
}
