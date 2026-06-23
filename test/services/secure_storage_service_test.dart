import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/services/secure_storage_service.dart';

/// A test platform that throws on the first [failures] read calls (simulating a
/// momentarily-locked keystore) before behaving like normal in-memory storage.
class _FlakyPlatform extends TestFlutterSecureStoragePlatform {
  _FlakyPlatform({required this.failures, Map<String, String>? data})
      : super(data ?? <String, String>{});

  int failures;
  int reads = 0;

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    reads++;
    if (failures > 0) {
      failures--;
      throw Exception('keystore temporarily locked');
    }
    return super.read(key: key, options: options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns the stored key on a clean read', () async {
    final platform = _FlakyPlatform(
      failures: 0,
      data: {'openrouter_api_key': 'sk-or-stored'},
    );
    FlutterSecureStoragePlatform.instance = platform;
    final service = SecureStorageService();

    expect(await service.readApiKey(), 'sk-or-stored');
    expect(platform.reads, 1);
  });

  test('recovers a transiently-unreadable key by retrying', () async {
    // Fails twice, succeeds on the third attempt — the key is NOT lost.
    final platform = _FlakyPlatform(
      failures: 2,
      data: {'openrouter_api_key': 'sk-or-stored'},
    );
    FlutterSecureStoragePlatform.instance = platform;
    final service = SecureStorageService();

    expect(await service.readApiKey(), 'sk-or-stored');
    expect(platform.reads, 3);
  });

  test('throws SecureStorageReadException when reads keep failing', () async {
    final platform = _FlakyPlatform(
      failures: 99,
      data: {'openrouter_api_key': 'sk-or-stored'},
    );
    FlutterSecureStoragePlatform.instance = platform;
    final service = SecureStorageService();

    await expectLater(
      service.readApiKey(),
      throwsA(isA<SecureStorageReadException>()),
    );
    // It gave up after the retry budget rather than hammering forever.
    expect(platform.reads, 3);
  });

  test('returns null (not an error) when no key has ever been stored',
      () async {
    final platform = _FlakyPlatform(failures: 0);
    FlutterSecureStoragePlatform.instance = platform;
    final service = SecureStorageService();

    expect(await service.readApiKey(), isNull);
  });
}
