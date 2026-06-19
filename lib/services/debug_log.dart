import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The category of a debug log entry; drives the colour/icon in the panel.
enum DebugKind { info, request, response, stream, usage, error }

/// A single timestamped entry in the debug log.
class DebugEntry {
  DebugEntry({
    required this.time,
    required this.kind,
    required this.title,
    this.detail,
  });

  final DateTime time;
  final DebugKind kind;
  final String title;

  /// Optional body — a response payload, request JSON, an SSE frame, etc.
  final String? detail;

  /// True when [detail] parses as JSON (so the panel can pretty-print it).
  bool get isJson {
    final d = detail;
    if (d == null) return false;
    final t = d.trimLeft();
    if (!t.startsWith('{') && !t.startsWith('[')) return false;
    try {
      jsonDecode(d);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [detail] pretty-printed when it is JSON, otherwise returned as-is.
  String? get prettyDetail {
    final d = detail;
    if (d == null) return null;
    if (!isJson) return d;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(d));
    } catch (_) {
      return d;
    }
  }
}

/// An in-memory, capped ring of debug events covering API requests, responses
/// and streaming. Wired into [OpenRouterService] and surfaced by the debug
/// panel so users can see what's happening while they wait for a response.
class DebugLog extends ChangeNotifier {
  DebugLog({this.capacity = 2000});

  final int capacity;
  final List<DebugEntry> _entries = [];
  bool _enabled = true;

  // Coalesce notifications so a burst of streaming frames doesn't rebuild the
  // panel hundreds of times per second.
  Timer? _throttle;
  bool _dirty = false;

  bool get enabled => _enabled;
  bool get isEmpty => _entries.isEmpty;
  int get length => _entries.length;

  /// Entries in chronological order (oldest first).
  List<DebugEntry> get entries => List.unmodifiable(_entries);

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  void add(DebugKind kind, String title, {String? detail}) {
    if (!_enabled) return;
    _entries.add(DebugEntry(
      time: DateTime.now(),
      kind: kind,
      title: title,
      detail: detail,
    ));
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
    _notifyThrottled();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  void _notifyThrottled() {
    if (_throttle != null) {
      _dirty = true;
      return;
    }
    notifyListeners();
    _throttle = Timer(const Duration(milliseconds: 120), () {
      _throttle = null;
      if (_dirty) {
        _dirty = false;
        _notifyThrottled();
      }
    });
  }

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }
}
