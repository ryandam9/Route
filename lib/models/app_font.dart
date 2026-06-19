/// Curated, already-bundled font families the user can pick from. No extra
/// assets are downloaded: `Roboto` ships with Flutter and the others are
/// bundled by the `auris` package.
enum AppFont { system, rajdhani, exoTwo, techMono }

extension AppFontX on AppFont {
  /// The registered font-family name to apply.
  String get family => switch (this) {
        AppFont.system => 'Roboto',
        AppFont.rajdhani => 'Rajdhani',
        AppFont.exoTwo => 'ExoTwo',
        AppFont.techMono => 'ShareTechMono',
      };

  /// Human-readable label for the picker.
  String get label => switch (this) {
        AppFont.system => 'System (Roboto)',
        AppFont.rajdhani => 'Rajdhani',
        AppFont.exoTwo => 'Exo 2',
        AppFont.techMono => 'Share Tech Mono',
      };

  static AppFont fromIndex(int? index) {
    if (index == null || index < 0 || index >= AppFont.values.length) {
      return AppFont.system;
    }
    return AppFont.values[index];
  }
}
