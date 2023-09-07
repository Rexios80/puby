import 'package:puby/engine.dart';

/// Build a command with the given engine args
typedef ArgsBuilder = List<String> Function(List<String> engineArgs);

/// A command and it's properties
class Command {
  /// Build this command's args with the given engine args
  final List<ArgsBuilder> builders;

  /// Whether to run the command in parallel
  final bool parallel;

  /// Whether to run the command silently
  final bool silent;

  bool _noFvm = false;

  /// If fvm support should be disabled
  bool get noFvm => _noFvm;

  /// Constructor
  Command(
    ArgsBuilder builder, {
    this.parallel = false,
    this.silent = false,
  }) : builders = [builder];

  /// Add arguments to the command
  void addArgs(ArgsBuilder other) => builders.add(other);

  /// Generate the args used to run this command with the given [engine]
  List<String> build(Engine engine) {
    final args = [
      for (final builder in builders) ...builder(engine.args),
    ];
    // args.remove must be first or else this statement can get short circited
    // and not actually remove the arg
    _noFvm = args.remove('--no-fvm') || _noFvm;
    return args;
  }
}
