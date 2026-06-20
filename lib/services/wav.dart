import 'dart:typed_data';

/// Wraps raw little-endian PCM samples in a canonical 44-byte-header WAV
/// container so they can be played back or sent as an `audio/wav` attachment.
///
/// [pcm] must be interleaved signed PCM at [bitsPerSample] (16 by default),
/// matching the [sampleRate] and [numChannels] used to capture it.
Uint8List pcmToWav(
  Uint8List pcm, {
  required int sampleRate,
  required int numChannels,
  int bitsPerSample = 16,
}) {
  final bytesPerSample = bitsPerSample ~/ 8;
  final byteRate = sampleRate * numChannels * bytesPerSample;
  final blockAlign = numChannels * bytesPerSample;
  final dataSize = pcm.length;

  final header = ByteData(44);
  void putAscii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  putAscii(0, 'RIFF');
  header.setUint32(4, 36 + dataSize, Endian.little); // overall size - 8
  putAscii(8, 'WAVE');
  putAscii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  header.setUint16(20, 1, Endian.little); // audio format = PCM
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  putAscii(36, 'data');
  header.setUint32(40, dataSize, Endian.little);

  final out = Uint8List(44 + dataSize);
  out.setRange(0, 44, header.buffer.asUint8List());
  out.setRange(44, 44 + dataSize, pcm);
  return out;
}
