import '../models/attachment.dart';

/// Maximum accepted size for an attached image (10 MB).
const int kMaxImageBytes = 10 * 1024 * 1024;

/// Maximum accepted size for attached audio (25 MB).
const int kMaxAudioBytes = 25 * 1024 * 1024;

/// Maximum accepted size for an attached document/PDF (20 MB).
const int kMaxFileBytes = 20 * 1024 * 1024;

/// The byte limit for a given attachment [kind].
int maxBytesFor(AttachmentKind kind) => switch (kind) {
      AttachmentKind.image => kMaxImageBytes,
      AttachmentKind.audio => kMaxAudioBytes,
      AttachmentKind.file => kMaxFileBytes,
    };

/// Returns a human-readable rejection message when [bytes] exceeds the limit
/// for [kind], or null when the attachment is within bounds.
///
/// Attachments are read fully into memory and stored base64 in SQLite, so an
/// up-front size check keeps memory use and database growth in check.
String? attachmentSizeError(AttachmentKind kind, int bytes) {
  final limit = maxBytesFor(kind);
  if (bytes <= limit) return null;
  final label = switch (kind) {
    AttachmentKind.image => 'Image',
    AttachmentKind.audio => 'Audio',
    AttachmentKind.file => 'Document',
  };
  return '$label is too large (${formatBytes(bytes)}). '
      'The limit is ${formatBytes(limit)}.';
}

/// Formats a byte count as a compact human-readable size (e.g. `9.4 MB`).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  double value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
}
