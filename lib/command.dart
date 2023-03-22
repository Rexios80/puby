/// A command and it's properties
class Command {
  /// The command to run
  final List<String> args;

  /// Whether to run the command as is
  final bool raw;

  /// Whether to run the command in parallel
  final bool parallel;

  /// Whether to run the command silently
  final bool silent;

  /// If fvm support should be disabled
  final bool noFvm;

  /// Constructor
  Command(
    this.args, {
    this.raw = false,
    this.parallel = false,
    this.silent = false,
  }) : noFvm = args.remove('--no-fvm');
}
