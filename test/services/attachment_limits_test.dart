import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/models/attachment.dart';
import 'package:wombat/services/attachment_limits.dart';

void main() {
  group('attachmentSizeError', () {
    test('accepts attachments within the per-kind limit', () {
      expect(attachmentSizeError(AttachmentKind.image, kMaxImageBytes), isNull);
      expect(attachmentSizeError(AttachmentKind.audio, 1024), isNull);
      expect(attachmentSizeError(AttachmentKind.file, 0), isNull);
    });

    test('rejects oversized images with a descriptive message', () {
      final msg = attachmentSizeError(AttachmentKind.image, kMaxImageBytes + 1);
      expect(msg, isNotNull);
      expect(msg, contains('Image'));
      expect(msg, contains('too large'));
    });

    test('uses the right limit for each kind', () {
      // Audio allows more than the image limit.
      expect(
        attachmentSizeError(AttachmentKind.audio, kMaxImageBytes + 1),
        isNull,
      );
      expect(
        attachmentSizeError(AttachmentKind.audio, kMaxAudioBytes + 1),
        isNotNull,
      );
      expect(
        attachmentSizeError(AttachmentKind.file, kMaxFileBytes + 1),
        isNotNull,
      );
    });
  });

  group('formatBytes', () {
    test('formats across units', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(10 * 1024 * 1024), '10 MB');
    });
  });
}
