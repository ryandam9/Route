import 'package:flutter_test/flutter_test.dart';
import 'package:route/services/debug_log.dart';

void main() {
  test('records entries and reports emptiness', () {
    final log = DebugLog();
    expect(log.isEmpty, isTrue);

    log.add(DebugKind.request, 'POST /chat/completions');
    expect(log.isEmpty, isFalse);
    expect(log.length, 1);
    expect(log.entries.single.title, 'POST /chat/completions');
  });

  test('drops oldest entries past capacity', () {
    final log = DebugLog(capacity: 3);
    for (var i = 0; i < 5; i++) {
      log.add(DebugKind.stream, 'chunk $i');
    }
    expect(log.length, 3);
    expect(log.entries.first.title, 'chunk 2'); // 0 and 1 dropped
    expect(log.entries.last.title, 'chunk 4');
  });

  test('does not record while capture is disabled', () {
    final log = DebugLog()..enabled = false;
    log.add(DebugKind.info, 'ignored');
    expect(log.isEmpty, isTrue);
  });

  test('clear empties the log', () {
    final log = DebugLog()..add(DebugKind.info, 'x');
    log.clear();
    expect(log.isEmpty, isTrue);
  });

  group('DebugEntry JSON detection', () {
    DebugEntry entry(String? detail) => DebugEntry(
          time: DateTime(2026),
          kind: DebugKind.response,
          title: 't',
          detail: detail,
        );

    test('pretty-prints JSON detail', () {
      final e = entry('{"a":1,"b":[2,3]}');
      expect(e.isJson, isTrue);
      expect(e.prettyDetail, contains('\n')); // indented across lines
      expect(e.prettyDetail, contains('"a": 1'));
    });

    test('leaves non-JSON detail untouched', () {
      final e = entry('OPENROUTER PROCESSING');
      expect(e.isJson, isFalse);
      expect(e.prettyDetail, 'OPENROUTER PROCESSING');
    });

    test('null detail is null', () {
      expect(entry(null).prettyDetail, isNull);
      expect(entry(null).isJson, isFalse);
    });
  });
}
