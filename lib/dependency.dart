import 'package:equatable/equatable.dart';

/// Represents a locked pub dependency in a pubspec.lock file
class LockedDependency extends Equatable {
  /// The name of the dependency
  final String name;

  /// The version of the dependency
  final String version;

  /// The url of the dependency
  final String url;

  /// Constructor
  LockedDependency({
    required this.name,
    required this.version,
    required this.url,
  });

  /// From json
  static LockedDependency? fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String;
    final description = json['description'];
    if (description is! Map) return null;
    final name = description['name'] as String?;
    if (name == null) return null;
    final version = json['version'] as String;
    final url = (description['url'] as String).replaceAll('https://', '');

    if (source == 'hosted') {
      return LockedDependency(name: name, version: version, url: url);
    } else if (source == 'git') {
      return LockedGitDependency(
        name: name,
        version: version,
        url: url,
        path: json['description']['path'] as String,
        resolvedRef: json['description']['resolved-ref'] as String,
      );
    } else {
      return null;
    }
  }

  @override
  List<Object?> get props => [name, version, url];
}

/// A locked dependency from git
class LockedGitDependency extends LockedDependency {
  /// The path of the dependency
  final String path;

  /// The resolved ref of the dependency
  final String resolvedRef;

  /// Constructor
  LockedGitDependency({
    required super.name,
    required super.version,
    required super.url,
    required this.path,
    required this.resolvedRef,
  });

  @override
  List<Object?> get props => [...super.props, path, resolvedRef];
}

/// Dependencies available in the pub cache
class AvailableDependencies {
  /// Hosted dependencies
  final Map<String, String> hosted;

  /// Git dependencies
  final Map<String, String> git;

  /// Constructor
  AvailableDependencies({
    required this.hosted,
    required this.git,
  });
}
