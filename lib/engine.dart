/// The engine the code uses
enum Engine {
  /// Dart
  dart,

  /// Flutter
  flutter,

  /// FVM
  fvm;

  /// If the engine uses flutter directly or transitively
  bool get isFlutter => this == Engine.flutter || this == Engine.fvm;

  /// The prefix arguments to run commands with
  List<String> get prefixArgs {
    switch (this) {
      case Engine.dart:
      case Engine.flutter:
        return [];
      case Engine.fvm:
        return ['flutter'];
    }
  }
}