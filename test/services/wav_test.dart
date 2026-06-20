import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/services/wav.dart';

void main() {
  int u16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);
  int u32(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);
  String ascii(Uint8List b, int o, int n) =>
      String.fromCharCodes(b.sublist(o, o + n));

  test('wraps PCM in a valid 44-byte WAV header', () {
    final pcm = Uint8List.fromList(List<int>.generate(100, (i) => i % 256));
    final wav = pcmToWav(pcm, sampleRate: 16000, numChannels: 1);

    expect(wav.length, 44 + 100);
    expect(ascii(wav, 0, 4), 'RIFF');
    expect(u32(wav, 4), 36 + 100); // chunk size = total - 8
    expect(ascii(wav, 8, 4), 'WAVE');
    expect(ascii(wav, 12, 4), 'fmt ');
    expect(u32(wav, 16), 16); // PCM fmt chunk size
    expect(u16(wav, 20), 1); // audio format = PCM
    expect(u16(wav, 22), 1); // channels
    expect(u32(wav, 24), 16000); // sample rate
    expect(u32(wav, 28), 16000 * 1 * 2); // byte rate
    expect(u16(wav, 32), 2); // block align
    expect(u16(wav, 34), 16); // bits per sample
    expect(ascii(wav, 36, 4), 'data');
    expect(u32(wav, 40), 100); // data size
    expect(wav.sublist(44), pcm); // payload preserved verbatim
  });

  test('byte rate and block align scale with channels', () {
    final wav = pcmToWav(Uint8List(0), sampleRate: 44100, numChannels: 2);
    expect(u16(wav, 22), 2); // channels
    expect(u32(wav, 28), 44100 * 2 * 2); // byte rate
    expect(u16(wav, 32), 4); // block align
    expect(u32(wav, 40), 0); // empty payload
  });
}
