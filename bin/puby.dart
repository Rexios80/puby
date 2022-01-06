import 'dart:io';

void main(List<String> arguments) {
  final engine = arguments.first;
  if (!['dart', 'flutter'].contains(engine)) {
    print('Usage: puby [dart|flutter] [options]');
    exit(1);
  }

  final args = ['pub', ...arguments.sublist(1)];
  final projectPaths = findProjectPaths();

  print('Running $engine ${args.join(' ')}');

  // Run the command in the project directories
  for (final path in projectPaths) {
    print('\nRunning in $path');
    final result = Process.runSync(engine, args, workingDirectory: path);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  print('\nDone!');
}

List<String> findProjectPaths() {
  return Directory.current
      .listSync(recursive: true)
      .where((entity) {
        return entity is File && entity.path.endsWith('pubspec.yaml');
      })
      .map((entity) => entity.parent.path)
      .toList();
}
