/// A command and it's properties
class Command {
  /// The command to run
  final List<String> args;

  /// Whether to run the command as is
  final bool raw;

  /// Whether to run the command in parallel
  final bool parallel;

  /// Constructor
  const Command(
    this.args, {
    this.raw = false,
    this.parallel = false,
  });
}
