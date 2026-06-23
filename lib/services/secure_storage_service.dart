import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown when the stored API key exists but cannot be read/decrypted right
/// now (e.g. the platform keystore is temporarily locked). This is distinct
/// from a `null` read, which means no key has ever been saved — so callers can
/// surface a "couldn't unlock, retry" state instead of silently re-prompting.
class SecureStorageReadException implements Exception {
  SecureStorageReadException(this.cause);

  final Object cause;

  @override
  String toString() => 'Failed to read from secure storage: $cause';
}

/// Stores the OpenRouter API key in the platform secure store
/// (Keystore on Android, libsecret on Linux, Keychain on macOS/iOS).
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? _defaultStorage();

  static const _apiKeyKey = 'openrouter_api_key';

  /// Number of read attempts before giving up. Keystore/Keychain reads can
  /// fail transiently (store still warming up after boot, momentary lock); a
  /// short retry recovers those instead of dropping the key.
  static const _maxReadAttempts = 3;

  final FlutterSecureStorage _storage;

  /// Builds the platform-tuned storage. These options matter:
  ///
  /// * Android `resetOnError: false` — by default the plugin *wipes* the stored
  ///   value when a decrypt error occurs and returns null, which permanently
  ///   loses the key on a transient hiccup. We'd rather the read throw and keep
  ///   the value on disk so a retry can recover it.
  /// * Apple `accessibility: first_unlock` — the default (`unlocked`) makes the
  ///   key unreadable whenever the device is locked (e.g. right after a reboot,
  ///   before the user has unlocked once), which looks like the key vanished.
  static FlutterSecureStorage _defaultStorage() => const FlutterSecureStorage(
        aOptions: AndroidOptions(resetOnError: false),
        iOptions:
            IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        mOptions:
            MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  /// Reads the saved API key. Returns `null` when no key is stored. Throws
  /// [SecureStorageReadException] if the key exists but the store can't be read
  /// after [_maxReadAttempts] attempts.
  Future<String?> readApiKey() async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxReadAttempts; attempt++) {
      try {
        return await _storage.read(key: _apiKeyKey);
      } catch (e) {
        lastError = e;
        if (attempt < _maxReadAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 120 * attempt));
        }
      }
    }
    throw SecureStorageReadException(lastError ?? 'unknown error');
  }

  Future<void> writeApiKey(String value) =>
      _storage.write(key: _apiKeyKey, value: value);

  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);
}
