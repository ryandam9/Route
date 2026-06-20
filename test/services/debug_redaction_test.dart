import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/services/debug_redaction.dart';

void main() {
  group('redactForDebug', () {
    test('replaces binary/attachment-bearing keys with a marker', () {
      final redacted = redactForDebug({
        'type': 'image_url',
        'image_url': {'url': 'data:image/png;base64,AAAA'},
        'file': {'file_data': 'data:application/pdf;base64,BBBB'},
        'input_audio': {'data': 'CCCC', 'format': 'wav'},
      }) as Map;

      expect(redacted['image_url'], '[redacted large payload]');
      expect(redacted['file'], isA<Map>());
      expect((redacted['file'] as Map)['file_data'], '[redacted large payload]');
      expect(redacted['input_audio'], '[redacted large payload]');
      expect(redacted['type'], 'image_url'); // ordinary values untouched
    });

    test('truncates strings longer than the cap', () {
      final long = 'x' * (kDebugMaxStringLength + 500);
      final redacted = redactForDebug({'note': long}) as Map;
      final value = redacted['note'] as String;
      expect(value.length, lessThan(long.length));
      expect(value, contains('truncated'));
    });

    test('recurses through lists and preserves short strings', () {
      final redacted = redactForDebug({
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
      }) as Map;
      final messages = redacted['messages'] as List;
      expect((messages.first as Map)['content'], 'hi');
    });
  });

  group('redactBodyForDebug', () {
    test('returns null for null input', () {
      expect(redactBodyForDebug(null), isNull);
    });

    test('redacts a JSON body and keeps it valid JSON', () {
      final body = jsonEncode({
        'model': 'm',
        'image_url': {'url': 'data:image/png;base64,${'Z' * 4000}'},
      });
      final out = redactBodyForDebug(body)!;
      expect(out, isNot(contains('Z' * 4000)));
      // Still parseable JSON with the shape preserved.
      final decoded = jsonDecode(out) as Map<String, dynamic>;
      expect(decoded['model'], 'm');
      expect(decoded['image_url'], '[redacted large payload]');
    });

    test('truncates an over-long non-JSON body', () {
      final body = 'q' * (kDebugMaxStringLength + 100);
      final out = redactBodyForDebug(body)!;
      expect(out, contains('truncated'));
      expect(out.length, lessThan(body.length));
    });
  });
}
