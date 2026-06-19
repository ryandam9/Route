import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/debug_log.dart';

/// A live debug panel showing API requests, responses and streaming frames
/// with second-precision timestamps. JSON payloads are pretty-printed.
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<DebugLog>();
    final entries = log.entries.reversed.toList(); // newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
        actions: [
          Row(
            children: [
              const Text('Capture'),
              Switch(
                value: log.enabled,
                onChanged: (v) => context.read<DebugLog>().enabled = v,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy all',
            onPressed: log.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _asText(log)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debug log copied')),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: log.isEmpty ? null : context.read<DebugLog>().clear,
          ),
        ],
      ),
      body: entries.isEmpty
          ? const _EmptyDebug()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
            ),
    );
  }

  String _asText(DebugLog log) {
    final fmt = DateFormat('HH:mm:ss.SSS');
    return log.entries
        .map((e) => '[${fmt.format(e.time)}] ${e.kind.name.toUpperCase()} '
            '${e.title}${e.detail != null ? '\n${e.prettyDetail}' : ''}')
        .join('\n\n');
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final DebugEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (color, icon) = _styleFor(entry.kind, scheme);
    final time = DateFormat('HH:mm:ss.SSS').format(entry.time);

    final titleRow = Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(time,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(entry.title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );

    final detail = entry.prettyDetail;
    if (detail == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _boxDecoration(scheme, color),
        child: titleRow,
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Material(
        color: scheme.surfaceContainerHighest,
        child: Theme(
          // Strip the divider lines ExpansionTile draws by default.
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: titleRow,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: SelectableText(
                    detail,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration(ColorScheme scheme, Color accent) =>
      BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      );

  (Color, IconData) _styleFor(DebugKind kind, ColorScheme scheme) =>
      switch (kind) {
        DebugKind.request => (scheme.primary, Icons.north_east),
        DebugKind.response => (const Color(0xFF2E9E5B), Icons.south_west),
        DebugKind.stream => (const Color(0xFF1E88E5), Icons.bolt),
        DebugKind.usage => (const Color(0xFFE08A00), Icons.toll),
        DebugKind.error => (scheme.error, Icons.error_outline),
        DebugKind.info => (scheme.outline, Icons.info_outline),
      };
}

class _EmptyDebug extends StatelessWidget {
  const _EmptyDebug();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bug_report_outlined,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No activity yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Send a message or load models — API requests, responses and '
              'streaming frames will show up here with timestamps.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
