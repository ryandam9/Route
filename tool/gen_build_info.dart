// Regenerates `lib/build_info.dart` from the current git checkout so the About
// screen can show the exact commit a build was made from ("the version").
//
// Run from the repo root:
//
//   dart run tool/gen_build_info.dart
//
// The generated values are also overridable at build time without regenerating,
// which is handy in CI:
//
//   flutter build linux \
//     --dart-define=GIT_COMMIT=$(git rev-parse --short HEAD) \
//     --dart-define=GIT_COMMIT_DATE=$(git log -1 --format=%cs) \
//     --dart-define=GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
import 'dart:io';

void main() {
  String git(List<String> args, {String fallback = 'unknown'}) {
    try {
      final r = Process.runSync('git', args);
      if (r.exitCode == 0) {
        final out = (r.stdout as String).trim();
        if (out.isNotEmpty) return out;
      }
    } catch (_) {/* git not available — fall through */}
    return fallback;
  }

  final commit = git(['rev-parse', '--short', 'HEAD']);
  final commitFull = git(['rev-parse', 'HEAD']);
  final commitDate = git(['log', '-1', '--format=%cs']);
  final branch = git(['rev-parse', '--abbrev-ref', 'HEAD']);

  // Semantic version from pubspec.yaml (the bit before any "+build").
  var version = '0.0.0';
  try {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere(
          (l) => l.startsWith('version:'),
          orElse: () => 'version: 0.0.0',
        );
    version = line.split(':').last.trim().split('+').first;
  } catch (_) {/* keep default */}

  final contents = '''
// GENERATED FILE — do not edit by hand.
//
// Regenerate with: dart run tool/gen_build_info.dart
//
// Values default to whatever the generator captured from git, but each can be
// overridden at build time with --dart-define (see tool/gen_build_info.dart).

/// Version and build metadata shown on the About screen.
class BuildInfo {
  const BuildInfo._();

  /// Semantic version from pubspec.yaml.
  static const String version = '$version';

  /// Short git commit the build was made from — used as the displayed version.
  static const String commit =
      String.fromEnvironment('GIT_COMMIT', defaultValue: '$commit');

  /// Full git commit hash.
  static const String commitFull =
      String.fromEnvironment('GIT_COMMIT_FULL', defaultValue: '$commitFull');

  /// ISO date (YYYY-MM-DD) of the commit.
  static const String commitDate =
      String.fromEnvironment('GIT_COMMIT_DATE', defaultValue: '$commitDate');

  /// Branch the build was made from.
  static const String branch =
      String.fromEnvironment('GIT_BRANCH', defaultValue: '$branch');

  /// Whether a real commit hash is available (vs an unknown/dev fallback).
  static bool get hasCommit => commit.isNotEmpty && commit != 'unknown';

  /// The version string to show to users — leads with the git commit.
  static String get displayVersion =>
      hasCommit ? 'v\$version · \$commit' : 'v\$version';
}
''';

  File('lib/build_info.dart').writeAsStringSync(contents);
  stdout.writeln('Wrote lib/build_info.dart  ($commit on $branch, $commitDate)');
}
