import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/usage.dart';
import '../providers/usage_provider.dart';
import '../widgets/ui_kit.dart';

/// Shows OpenRouter usage accumulated during the current app session, plus the
/// account credit balance.
class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  static final _int = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    // Attempt to load the account balance when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageProvider.notifier).refreshCredits();
    });
  }

  String _money(double v, {int dp = 4}) => '\$${v.toStringAsFixed(dp)}';

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(usageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session usage'),
        actions: [
          IconButton(
            tooltip: 'Reset session',
            icon: const Icon(Icons.restart_alt),
            onPressed: usage.isEmpty
                ? null
                : () => ref.read(usageProvider.notifier).reset(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Headline KPIs.
          _CardGrid(
            cards: [
              StatCard(
                label: 'Input tokens',
                value: _int.format(usage.promptTokens),
              ),
              StatCard(
                label: 'Output tokens',
                value: _int.format(usage.completionTokens),
              ),
              StatCard(label: 'Cost', value: _money(usage.cost), unit: 'USD'),
              StatCard(label: 'Requests', value: '${usage.requests}'),
            ],
          ),
          const SizedBox(height: 16),
          _AccountPanel(money: _money),
          const SizedBox(height: 16),
          _ByModelPanel(usage: usage, money: _money, intFmt: _int),
          const SizedBox(height: 16),
          _UsageSummaryPanel(usage: usage, money: _money, intFmt: _int),
        ],
      ),
    );
  }
}

/// Lays out a set of cards 4-across on wide layouts and 2-across when narrow.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 720 ? 4 : 2;
        final width =
            (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _AccountPanel extends ConsumerWidget {
  const _AccountPanel({required this.money});

  final String Function(double, {int dp}) money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageProvider);
    final credits = usage.credits;

    Widget body;
    if (usage.creditsLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (usage.creditsError != null) {
      body = InfoBanner(
        title: 'Balance unavailable',
        message: usage.creditsError!,
        kind: BannerKind.warning,
      );
    } else if (credits != null) {
      body = _BalanceContent(credits: credits, money: money);
    } else {
      body = const Text('Tap refresh to load your account balance.');
    }

    return SectionPanel(
      title: 'Account balance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: usage.creditsLoading
                  ? null
                  : () => ref.read(usageProvider.notifier).refreshCredits(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The donut + Remaining/Used/Purchased breakdown, laid out side-by-side on
/// wide screens and stacked when narrow.
class _BalanceContent extends StatelessWidget {
  const _BalanceContent({required this.credits, required this.money});

  final CreditBalance credits;
  final String Function(double, {int dp}) money;

  @override
  Widget build(BuildContext context) {
    final fraction =
        credits.totalCredits <= 0 ? 0.0 : credits.remaining / credits.totalCredits;

    final donut = _BalanceDonut(
      fraction: fraction.clamp(0.0, 1.0),
      centerValue: money(credits.totalCredits, dp: 2),
      label: 'Total balance',
    );

    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabelValueRow(
          label: 'Remaining',
          value: money(credits.remaining, dp: 2),
          highlight: true,
        ),
        LabelValueRow(label: 'Used', value: money(credits.totalUsage, dp: 2)),
        LabelValueRow(
          label: 'Purchased',
          value: money(credits.totalCredits, dp: 2),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 420) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              donut,
              const SizedBox(width: 24),
              Expanded(child: rows),
            ],
          );
        }
        return Column(
          children: [
            Center(child: donut),
            const SizedBox(height: 16),
            rows,
          ],
        );
      },
    );
  }
}

/// A donut chart showing the remaining fraction of the account balance, with
/// the total shown in the centre.
class _BalanceDonut extends StatelessWidget {
  const _BalanceDonut({
    required this.fraction,
    required this.centerValue,
    required this.label,
  });

  final double fraction;
  final String centerValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 132,
      height: 132,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: fraction,
          foreground: theme.colorScheme.primary,
          background: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerValue,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.foreground,
    required this.background,
  });

  final double fraction;
  final Color foreground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = background;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = foreground;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.fraction != fraction ||
      old.foreground != foreground ||
      old.background != background;
}

class _ByModelPanel extends StatelessWidget {
  const _ByModelPanel({
    required this.usage,
    required this.money,
    required this.intFmt,
  });

  final UsageState usage;
  final String Function(double, {int dp}) money;
  final NumberFormat intFmt;

  @override
  Widget build(BuildContext context) {
    final models = usage.byModel;
    final totalCost = usage.cost;

    return SectionPanel(
      title: 'By model',
      child: models.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No usage recorded yet this session.'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                return Column(
                  children: [
                    if (wide) const _ByModelHeader(),
                    for (final m in models)
                      wide
                          ? _ByModelRow(
                              model: m,
                              totalCost: totalCost,
                              money: money,
                              intFmt: intFmt,
                            )
                          : _ByModelCard(
                              model: m,
                              totalCost: totalCost,
                              money: money,
                              intFmt: intFmt,
                            ),
                  ],
                );
              },
            ),
    );
  }
}

class _ByModelHeader extends StatelessWidget {
  const _ByModelHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget h(String t, int flex, {TextAlign align = TextAlign.left}) => Expanded(
          flex: flex,
          child: Text(
            t.toUpperCase(),
            textAlign: align,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          h('Model', 4),
          h('Input', 2, align: TextAlign.right),
          h('Output', 2, align: TextAlign.right),
          h('Req', 1, align: TextAlign.right),
          h('Cost', 2, align: TextAlign.right),
          h('% of total cost', 3, align: TextAlign.right),
        ],
      ),
    );
  }
}

class _ByModelRow extends StatelessWidget {
  const _ByModelRow({
    required this.model,
    required this.totalCost,
    required this.money,
    required this.intFmt,
  });

  final ModelUsage model;
  final double totalCost;
  final String Function(double, {int dp}) money;
  final NumberFormat intFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final share = totalCost <= 0 ? 0.0 : (model.cost / totalCost).clamp(0.0, 1.0);
    Widget cell(String t, int flex, {TextAlign align = TextAlign.right}) =>
        Expanded(
          flex: flex,
          child: Text(
            t,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              model.modelId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          cell(intFmt.format(model.promptTokens), 2),
          cell(intFmt.format(model.completionTokens), 2),
          cell('${model.requests}', 1),
          cell(money(model.cost), 2),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: share, minHeight: 6),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(share * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacked per-model card used on narrow layouts where a table would overflow.
class _ByModelCard extends StatelessWidget {
  const _ByModelCard({
    required this.model,
    required this.totalCost,
    required this.money,
    required this.intFmt,
  });

  final ModelUsage model;
  final double totalCost;
  final String Function(double, {int dp}) money;
  final NumberFormat intFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final share = totalCost <= 0 ? 0.0 : (model.cost / totalCost).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.modelId,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip('${model.requests}×',
                    color: theme.colorScheme.outline),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('COST', style: theme.textTheme.labelSmall),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${money(model.cost)}  ·  ${(share * 100).toStringAsFixed(1)}% of total',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: share, minHeight: 6),
            ),
            LabelValueRow(
              label: 'Tokens',
              value: '${intFmt.format(model.promptTokens)} in  ·  '
                  '${intFmt.format(model.completionTokens)} out',
            ),
          ],
        ),
      ),
    );
  }
}

/// A recap of the session: total cost/tokens, average cost per request, total
/// requests.
class _UsageSummaryPanel extends StatelessWidget {
  const _UsageSummaryPanel({
    required this.usage,
    required this.money,
    required this.intFmt,
  });

  final UsageState usage;
  final String Function(double, {int dp}) money;
  final NumberFormat intFmt;

  @override
  Widget build(BuildContext context) {
    final avg = usage.requests == 0 ? 0.0 : usage.cost / usage.requests;
    return SectionPanel(
      title: 'Usage summary',
      child: _CardGrid(
        cards: [
          _SummaryTile(
            icon: Icons.payments_outlined,
            label: 'Total cost',
            value: money(usage.cost),
          ),
          _SummaryTile(
            icon: Icons.toll_outlined,
            label: 'Total tokens',
            value: intFmt.format(usage.totalTokens),
          ),
          _SummaryTile(
            icon: Icons.trending_up,
            label: 'Avg cost / request',
            value: money(avg),
          ),
          _SummaryTile(
            icon: Icons.swap_horiz,
            label: 'Total requests',
            value: '${usage.requests}',
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
