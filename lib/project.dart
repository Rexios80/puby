import 'package:puby/config.dart';
import 'package:puby/engine.dart';

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

  /// If this project should be excluded from command execution
  final bool exclude;

  /// Create a [Project]
  Project({
    required this.engine,
    required this.path,
    required this.config,
    required this.example,
    required this.hidden,
    this.exclude = false,
  });

  /// Create a copy of this [Project] with the specified changes
  Project copyWith({Engine? engine, bool? exclude}) {
    return Project(
      engine: engine ?? this.engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
      exclude: exclude ?? this.exclude,
    );
  }
}
