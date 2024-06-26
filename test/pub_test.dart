import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] pub get', () async {
    final result = await testCommand(['get']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);

    // project in build folder
    expectLine(stdout, [p.join('build_folder_test', 'build', 'web'), 'Skip']);

    // dart
    expectLine(stdout, ['dart_puby_test', 'dart pub get']);
    expectLine(stdout, [p.join('dart_puby_test', 'example'), 'dart pub get']);

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter pub get']);
    // Default exclusion
    expectLine(stdout, [p.join('flutter_puby_test', 'example'), 'Skip']);
    // Flutter pub get should run in the example project anyways
    expectLine(stdout, ['Resolving dependencies in ./example...']);

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter pub get']);
    // Default exclusion
    expectLine(stdout, [p.join('fvm_puby_test', 'example'), 'Skip']);
    // Flutter pub get should run in the example project anyways
    // Can't test this with fvm since the output is the same as flutter
    // expectLine(stdout, ['example', 'fvm flutter pub get']);
    expectLine(
      stdout,
      [p.join('fvm_puby_test', 'nested'), 'fvm flutter pub get'],
    );

    // invalid_pubspec
    expectLine(stdout, ['invalid_pubspec_test', 'Error parsing pubspec']);

    // transitive flutter
    // This one should fail
    // TODO: This isn't failing anymore for some reason. Remove this feature?
    expectLine(stdout, ['transitive_flutter_test', 'dart pub get']);

    // This one should succeed
    // expectLine(stdout, ['transitive_flutter_test', 'flutter pub get']);
  });
}
