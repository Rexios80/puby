import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:puby/config.dart';
import 'package:puby/engine.dart';

/// Intermediate data used during project resolution
class ProjectIntermediate {
  /// The absolute path to the project
  final String absolutePath;

  /// The relative path to the project
  final String path;

  /// The parsed pubspec
  final Pubspec pubspec;

  /// The dependency resolution strategy for this project
  final DependencyResolutionStrategy dependencyResolutionStrategy;

  /// Constructor
  const ProjectIntermediate({
    required this.absolutePath,
    required this.path,
    required this.pubspec,
    required this.dependencyResolutionStrategy,
  });
}

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

  /// All of dependencies for this project including transitive
  final Set<String> dependencies;

  /// If this project is configured with FVM
  final bool fvm;

  /// The dependency resolution strategy for this project
  final DependencyResolutionStrategy dependencyResolutionStrategy;

  /// The parent project's dependency resolution strategy
  final DependencyResolutionStrategy? parentDependencyResolutionStrategy;

  /// The arguments to prefix to any commands run in this project
  List<String> get prefixArgs => [
        if (fvm) 'fvm',
        engine.name,
      ];

  /// Create a [Project]
  Project({
    required this.engine,
    required this.path,
    required this.config,
    required this.example,
    required this.hidden,
    this.exclude = false,
    required this.dependencies,
    required this.fvm,
    required this.dependencyResolutionStrategy,
    this.parentDependencyResolutionStrategy,
  });

  /// Create a copy of this [Project] with the specified changes
  Project copyWith({Engine? engine, bool? exclude, bool? fvm}) {
    return Project(
      engine: engine ?? this.engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
      exclude: exclude ?? this.exclude,
      dependencies: dependencies,
      fvm: fvm ?? this.fvm,
      dependencyResolutionStrategy: dependencyResolutionStrategy,
      parentDependencyResolutionStrategy: parentDependencyResolutionStrategy,
    );
  }
}

/// Dependency resolution strategies
enum DependencyResolutionStrategy {
  /// Resolve this project as a standalone project
  standalone,

  /// Resolve this project with its workspace
  workspace;
}
