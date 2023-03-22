/// Pretty print stopwatch time
extension PrettyTime on Stopwatch {
  /// Pretty print stopwatch time
  String prettyPrint() {
    final elapsed = elapsedMilliseconds;
    final String time;
    if (elapsed > 1000) {
      time = '${(elapsed / 1000).toStringAsFixed(1)}s';
    } else {
      time = '${elapsed}ms';
    }
    return time;
  }
}
