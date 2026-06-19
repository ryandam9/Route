import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_font.dart';
import '../services/secure_storage_service.dart';

/// Holds user settings: the API key, the default model for new chats, and the
/// app theme mode. The API key lives in secure storage; the rest in prefs.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(
    this._secureStorage,
    this._prefs, {
    Map<String, String>? environment,
  }) : _environment = environment ?? _desktopEnvironment() {
    _load();
  }

  final SecureStorageService _secureStorage;
  final SharedPreferences _prefs;

  /// Process environment variables, consulted on desktop to seed the API key.
  final Map<String, String> _environment;

  /// Environment variable read at startup (desktop) to seed the API key when
  /// none is stored on the device.
  static const apiKeyEnvVar = 'OPENROUTER_API_KEY';

  /// Environment variables are only meaningful on desktop platforms; on mobile
  /// there's nothing useful to read.
  static Map<String, String> _desktopEnvironment() {
    try {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        return Platform.environment;
      }
    } catch (_) {
      // Platform may be unavailable (e.g. web); fall through.
    }
    return const {};
  }

  static const _kDefaultModel = 'default_model';
  static const _kThemeMode = 'theme_mode';
  static const _kDownloadDir = 'download_dir';
  static const _kAnimateModelIndicator = 'animate_model_indicator';
  static const _kContinuousModelBorder = 'continuous_model_border';
  static const _kHeadingFont = 'font_heading';
  static const _kUserFont = 'font_user';
  static const _kModelFont = 'font_model';
  static const _kSettingsFont = 'font_settings';
  static const _kMonoFont = 'font_mono';
  static const _kUserFontScale = 'font_scale_user';
  static const _kModelFontScale = 'font_scale_model';
  static const _kFavoriteModels = 'favorite_models';

  /// Allowed text-size multipliers for chat messages.
  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.6;

  String? _apiKey;
  String _defaultModel = 'openai/gpt-4o-mini';
  ThemeMode _themeMode = ThemeMode.system;
  String? _downloadDir;
  bool _animateModelIndicator = false;
  bool _continuousModelBorder = false;
  // Roboto Condensed is the default app font (bundled asset).
  AppFont _headingFont = AppFont.robotoCondensed;
  AppFont _userFont = AppFont.robotoCondensed;
  AppFont _modelFont = AppFont.robotoCondensed;
  AppFont _settingsFont = AppFont.robotoCondensed;
  // JetBrains Mono is the default for code/JSON (debug panel).
  AppFont _monoFont = AppFont.jetBrainsMono;
  // Text-size multipliers for chat messages (1.0 == default size).
  double _userFontScale = 1.0;
  double _modelFontScale = 1.0;
  Set<String> _favoriteModels = {};
  bool _loading = true;
  bool _apiKeyFromEnv = false;

  bool get loading => _loading;
  String? get apiKey => _apiKey;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Whether the active API key was seeded from [apiKeyEnvVar] rather than saved
  /// on the device. Such a key lives only for this session — it's re-read from
  /// the environment on each launch and is never written to secure storage.
  bool get apiKeyFromEnvironment => _apiKeyFromEnv;

  /// Name of the environment variable consulted for the API key.
  String get apiKeyEnvVarName => apiKeyEnvVar;
  String get defaultModel => _defaultModel;
  ThemeMode get themeMode => _themeMode;

  /// Whether the model indicator in the chat header pulses while streaming.
  /// Off by default so it doesn't blink distractingly.
  bool get animateModelIndicator => _animateModelIndicator;

  /// Whether the gradient border around the selected model spins continuously.
  /// Off by default: the border animates once when a model is selected, then
  /// settles, so it doesn't distract while reading.
  bool get continuousModelBorder => _continuousModelBorder;

  /// Fonts for headings, user text, model output, and the settings screen.
  AppFont get headingFont => _headingFont;
  AppFont get userFont => _userFont;
  AppFont get modelFont => _modelFont;
  AppFont get settingsFont => _settingsFont;

  /// Monospace font for code/JSON in the debug panel.
  AppFont get monoFont => _monoFont;

  /// Text-size multipliers for your prompts and the model's replies. Lets
  /// people who want larger (or smaller) chat text adjust it independently.
  double get userFontScale => _userFontScale;
  double get modelFontScale => _modelFontScale;

  /// Model ids the user has bookmarked. Bookmarked models surface first in the
  /// model picker.
  Set<String> get favoriteModels => _favoriteModels;
  bool isFavoriteModel(String id) => _favoriteModels.contains(id);

  /// Default directory new downloads are written to (desktop). When null, a
  /// Save-As dialog is shown instead.
  String? get downloadDir => _downloadDir;

  Future<void> _load() async {
    try {
      _apiKey = await _secureStorage.readApiKey();
    } catch (_) {
      _apiKey = null;
    }
    // No key saved on the device? On desktop, fall back to the environment.
    if (!hasApiKey) _applyEnvFallback();
    _defaultModel = _prefs.getString(_kDefaultModel) ?? _defaultModel;
    _downloadDir = _prefs.getString(_kDownloadDir);
    _animateModelIndicator =
        _prefs.getBool(_kAnimateModelIndicator) ?? false;
    _continuousModelBorder =
        _prefs.getBool(_kContinuousModelBorder) ?? false;
    const def = AppFont.robotoCondensed; // default app font
    _headingFont = AppFontX.fromIndex(_prefs.getInt(_kHeadingFont) ?? def.index);
    _userFont = AppFontX.fromIndex(_prefs.getInt(_kUserFont) ?? def.index);
    _modelFont = AppFontX.fromIndex(_prefs.getInt(_kModelFont) ?? def.index);
    _settingsFont =
        AppFontX.fromIndex(_prefs.getInt(_kSettingsFont) ?? def.index);
    _monoFont = AppFontX.fromIndex(
        _prefs.getInt(_kMonoFont) ?? AppFont.jetBrainsMono.index);
    _userFontScale = _clampScale(_prefs.getDouble(_kUserFontScale) ?? 1.0);
    _modelFontScale = _clampScale(_prefs.getDouble(_kModelFontScale) ?? 1.0);
    _favoriteModels =
        (_prefs.getStringList(_kFavoriteModels) ?? const []).toSet();
    final themeIndex = _prefs.getInt(_kThemeMode);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> setDownloadDir(String? dir) async {
    _downloadDir = (dir != null && dir.isNotEmpty) ? dir : null;
    if (_downloadDir != null) {
      await _prefs.setString(_kDownloadDir, _downloadDir!);
    } else {
      await _prefs.remove(_kDownloadDir);
    }
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isNotEmpty) {
      // An explicitly entered key is stored on the device and overrides any
      // environment value.
      _apiKey = trimmed;
      _apiKeyFromEnv = false;
      await _secureStorage.writeApiKey(trimmed);
    } else {
      // Saving an empty key clears the stored one; fall back to the env value.
      await _secureStorage.deleteApiKey();
      _apiKey = null;
      _apiKeyFromEnv = false;
      _applyEnvFallback();
    }
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await _secureStorage.deleteApiKey();
    _apiKey = null;
    _apiKeyFromEnv = false;
    // Reverting a stored key exposes the environment value again, if present.
    _applyEnvFallback();
    notifyListeners();
  }

  /// Seeds [_apiKey] from the environment when nothing is stored on the device.
  void _applyEnvFallback() {
    final envKey = _environment[apiKeyEnvVar]?.trim();
    if (envKey != null && envKey.isNotEmpty) {
      _apiKey = envKey;
      _apiKeyFromEnv = true;
    }
  }

  Future<void> setDefaultModel(String model) async {
    _defaultModel = model;
    await _prefs.setString(_kDefaultModel, model);
    notifyListeners();
  }

  Future<void> setAnimateModelIndicator(bool value) async {
    _animateModelIndicator = value;
    await _prefs.setBool(_kAnimateModelIndicator, value);
    notifyListeners();
  }

  Future<void> setContinuousModelBorder(bool value) async {
    _continuousModelBorder = value;
    await _prefs.setBool(_kContinuousModelBorder, value);
    notifyListeners();
  }

  Future<void> setHeadingFont(AppFont f) async {
    _headingFont = f;
    await _prefs.setInt(_kHeadingFont, f.index);
    notifyListeners();
  }

  Future<void> setUserFont(AppFont f) async {
    _userFont = f;
    await _prefs.setInt(_kUserFont, f.index);
    notifyListeners();
  }

  Future<void> setModelFont(AppFont f) async {
    _modelFont = f;
    await _prefs.setInt(_kModelFont, f.index);
    notifyListeners();
  }

  Future<void> setSettingsFont(AppFont f) async {
    _settingsFont = f;
    await _prefs.setInt(_kSettingsFont, f.index);
    notifyListeners();
  }

  Future<void> setMonoFont(AppFont f) async {
    _monoFont = f;
    await _prefs.setInt(_kMonoFont, f.index);
    notifyListeners();
  }

  Future<void> setUserFontScale(double scale) async {
    _userFontScale = _clampScale(scale);
    await _prefs.setDouble(_kUserFontScale, _userFontScale);
    notifyListeners();
  }

  Future<void> setModelFontScale(double scale) async {
    _modelFontScale = _clampScale(scale);
    await _prefs.setDouble(_kModelFontScale, _modelFontScale);
    notifyListeners();
  }

  double _clampScale(double v) => v.clamp(minFontScale, maxFontScale);

  Future<void> toggleFavoriteModel(String id) async {
    // Copy so listeners that captured the old set see a distinct value.
    final next = Set<String>.from(_favoriteModels);
    if (!next.remove(id)) next.add(id);
    _favoriteModels = next;
    await _prefs.setStringList(_kFavoriteModels, next.toList());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }
}
