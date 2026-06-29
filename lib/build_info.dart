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
  static const String version = '1.0.0';

  /// Short git commit the build was made from — used as the displayed version.
  static const String commit =
      String.fromEnvironment('GIT_COMMIT', defaultValue: '4ea483e');

  /// Full git commit hash.
  static const String commitFull =
      String.fromEnvironment('GIT_COMMIT_FULL', defaultValue: '4ea483e69e78e84706d9a8ad4346f41272e0678c');

  /// ISO date (YYYY-MM-DD) of the commit.
  static const String commitDate =
      String.fromEnvironment('GIT_COMMIT_DATE', defaultValue: '2026-06-29');

  /// Branch the build was made from.
  static const String branch =
      String.fromEnvironment('GIT_BRANCH', defaultValue: 'claude/neo-brutalism-redesign-jxat8q');

  /// Whether a real commit hash is available (vs an unknown/dev fallback).
  static bool get hasCommit => commit.isNotEmpty && commit != 'unknown';

  /// The version string to show to users — leads with the git commit.
  static String get displayVersion =>
      hasCommit ? 'v$version · $commit' : 'v$version';
}
