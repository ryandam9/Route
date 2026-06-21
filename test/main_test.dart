import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/main.dart';

void main() {
  group('isSvgRenderNoise', () {
    test('matches flutter_svg unhandled-element warnings', () {
      expect(
        isSvgRenderNoise('unhandled element <filter/>; Picture key: Svg loader'),
        isTrue,
      );
      expect(
        isSvgRenderNoise('unhandled element <div/>; Picture key: Svg loader'),
        isTrue,
      );
    });

    test('leaves other log lines alone', () {
      expect(isSvgRenderNoise('some unrelated log'), isFalse);
      expect(isSvgRenderNoise('unhandled element <filter/>'), isFalse);
      expect(isSvgRenderNoise('Exception: Svg loader failed'), isFalse);
    });
  });
}
