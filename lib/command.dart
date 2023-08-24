import 'package:puby/engine.dart';

/// Build a command with the given engine args
typedef ArgsBuilder = List<String> Function(List<String> engineArgs);

/// A command and it's properties
class Command {
  /// Build this command's args with the given engine args
  ArgsBuilder builder;

  /// Whether to run the command in parallel
  final bool parallel;

  /// Whether to run the command silently
  final bool silent;

  bool _noFvm = false;

  /// If fvm support should be disabled
  bool get noFvm => _noFvm;

  /// Constructor
  Command(
    this.builder, {
    this.parallel = false,
    this.silent = false,
  });

  /// Add arguments to the command
  void add(List<String> args) {
    builder = (engineArgs) => builder(engineArgs) + args;
  }

  /// Generate the args used to run this command with the given [engine]
  List<String> build(Engine engine) {
    final args = builder(engine.args);
    _noFvm = _noFvm || args.remove('--no-fvm');
    return args;
  }
}
