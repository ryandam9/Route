import 'dart:convert';

/// Maximum length of a string kept verbatim in a debug payload; longer strings
/// are truncated with a marker. Keeps the in-memory debug log light and avoids
/// retaining large base64 blobs (images/audio/PDFs) in their entirety.
const int kDebugMaxStringLength = 2000;

/// JSON keys whose values are replaced wholesale, regardless of length. These
/// carry large and/or sensitive binary payloads (base64 attachments, data
/// URIs) that should never be retained verbatim in the debug log.
const Set<String> _redactedKeyFragments = {
  'data',
  'file_data',
  'image_url',
  'input_audio',
  'b64_json',
};

const String _redactedMarker = '[redacted large payload]';

/// Recursively redacts a decoded JSON value for safe display in the debug
/// panel:
///
/// * Map values whose key looks like a binary/attachment field
///   (e.g. `data`, `file_data`, `image_url`) are replaced with a marker.
/// * Strings longer than [kDebugMaxStringLength] are truncated.
/// * Lists and maps are processed recursively.
///
/// The shape of the data is preserved so the redacted body still reads as the
/// original request — only the heavy/sensitive leaves are removed.
Object? redactForDebug(Object? value) {
  if (value is Map) {
    return value.map((key, val) {
      final k = key.toString().toLowerCase();
      if (_redactedKeyFragments.any(k.contains)) {
        return MapEntry(key, _redactedMarker);
      }
      return MapEntry(key, redactForDebug(val));
    });
  }
  if (value is List) {
    return value.map(redactForDebug).toList();
  }
  if (value is String && value.length > kDebugMaxStringLength) {
    return '${value.substring(0, kDebugMaxStringLength)}… [truncated '
        '${value.length - kDebugMaxStringLength} chars]';
  }
  return value;
}

/// Redacts a JSON-encoded body string for the debug log. Parses [body], applies
/// [redactForDebug], and re-encodes it. Non-JSON bodies are truncated to
/// [kDebugMaxStringLength]. Returns null when [body] is null.
String? redactBodyForDebug(String? body) {
  if (body == null) return null;
  try {
    final decoded = jsonDecode(body);
    return jsonEncode(redactForDebug(decoded));
  } catch (_) {
    // Not JSON — fall back to a plain length cap.
    if (body.length > kDebugMaxStringLength) {
      return '${body.substring(0, kDebugMaxStringLength)}… [truncated '
          '${body.length - kDebugMaxStringLength} chars]';
    }
    return body;
  }
}
