import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/usage.dart';
import '../providers/usage_provider.dart';
import '../widgets/ui_kit.dart';

/// Shows OpenRouter usage accumulated during the current app session, plus the
/// account credit balance — with Syncfusion charts for the balance and the
/// per-model breakdowns.
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
    final hasModels = usage.byModel.isNotEmpty;

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
          if (hasModels) ...[
            _CostByModelPanel(usage: usage, money: _money),
            const SizedBox(height: 16),
            _TokensByModelPanel(usage: usage),
            const SizedBox(height: 16),
            _TokenSharePanel(usage: usage),
            const SizedBox(height: 16),
          ],
          _ByModelPanel(usage: usage, money: _money, intFmt: _int),
          const SizedBox(height: 16),
          _UsageSummaryPanel(usage: usage, money: _money, intFmt: _int),
        ],
      ),
    );
  }
}

/// A palette for per-model series, derived from the theme.
List<Color> _palette(ColorScheme s) => [
      s.primary,
      s.tertiary,
      s.secondary,
      s.primaryContainer,
      s.error,
      s.tertiaryContainer,
    ];

/// Short model label for chart axes: the part after the vendor slash.
String _shortModel(String id) => id.contains('/') ? id.split('/').last : id;

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

/// The balance doughnut chart + Remaining/Used/Purchased breakdown, side by
/// side on wide screens and stacked when narrow.
class _BalanceContent extends StatelessWidget {
  const _BalanceContent({required this.credits, required this.money});

  final CreditBalance credits;
  final String Function(double, {int dp}) money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final donut = SizedBox(
      width: 150,
      height: 150,
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        annotations: [
          CircularChartAnnotation(
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(money(credits.totalCredits, dp: 2),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('Balance',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
        series: <DoughnutSeries<_Slice, String>>[
          DoughnutSeries<_Slice, String>(
            dataSource: [
              _Slice('Remaining', credits.remaining, theme.colorScheme.primary),
              _Slice('Used', credits.totalUsage,
                  theme.colorScheme.surfaceContainerHighest),
            ],
            xValueMapper: (d, _) => d.label,
            yValueMapper: (d, _) => d.value,
            pointColorMapper: (d, _) => d.color,
            innerRadius: '72%',
            animationDuration: 0,
          ),
        ],
      ),
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

/// Bar chart of cost per model.
class _CostByModelPanel extends StatelessWidget {
  const _CostByModelPanel({required this.usage, required this.money});

  final UsageState usage;
  final String Function(double, {int dp}) money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = usage.byModel;
    return SectionPanel(
      title: 'Cost by model',
      child: SizedBox(
        height: 60.0 + models.length * 44,
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          palette: _palette(theme.colorScheme),
          primaryXAxis: _categoryAxis(theme),
          primaryYAxis: NumericAxis(
            numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
            labelStyle: _axisLabelStyle(theme),
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(width: 0),
          ),
          series: <CartesianSeries<ModelUsage, String>>[
            BarSeries<ModelUsage, String>(
              dataSource: models,
              xValueMapper: (m, _) => _shortModel(m.modelId),
              yValueMapper: (m, _) => m.cost,
              pointColorMapper: (m, i) =>
                  _palette(theme.colorScheme)[i % 6],
              dataLabelMapper: (m, _) => money(m.cost),
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle: _axisLabelStyle(theme),
              ),
              animationDuration: 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stacked column chart of input vs output tokens per model.
class _TokensByModelPanel extends StatelessWidget {
  const _TokensByModelPanel({required this.usage});

  final UsageState usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = usage.byModel;
    return SectionPanel(
      title: 'Tokens by model',
      child: SizedBox(
        height: 260,
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          legend: Legend(
            isVisible: true,
            position: LegendPosition.top,
            textStyle: _axisLabelStyle(theme),
          ),
          primaryXAxis: _categoryAxis(theme),
          primaryYAxis: NumericAxis(
            numberFormat: NumberFormat.compact(),
            labelStyle: _axisLabelStyle(theme),
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(width: 0),
          ),
          series: <StackedColumnSeries<ModelUsage, String>>[
            StackedColumnSeries<ModelUsage, String>(
              name: 'Input',
              dataSource: models,
              xValueMapper: (m, _) => _shortModel(m.modelId),
              yValueMapper: (m, _) => m.promptTokens,
              color: theme.colorScheme.primary,
              animationDuration: 0,
            ),
            StackedColumnSeries<ModelUsage, String>(
              name: 'Output',
              dataSource: models,
              xValueMapper: (m, _) => _shortModel(m.modelId),
              yValueMapper: (m, _) => m.completionTokens,
              color: theme.colorScheme.tertiary,
              animationDuration: 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pie chart of each model's share of total tokens.
class _TokenSharePanel extends StatelessWidget {
  const _TokenSharePanel({required this.usage});

  final UsageState usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = usage.byModel;
    return SectionPanel(
      title: 'Token share',
      child: SizedBox(
        height: 260,
        child: SfCircularChart(
          margin: EdgeInsets.zero,
          palette: _palette(theme.colorScheme),
          legend: Legend(
            isVisible: true,
            position: LegendPosition.bottom,
            overflowMode: LegendItemOverflowMode.wrap,
            textStyle: _axisLabelStyle(theme),
          ),
          series: <PieSeries<ModelUsage, String>>[
            PieSeries<ModelUsage, String>(
              dataSource: models,
              xValueMapper: (m, _) => _shortModel(m.modelId),
              yValueMapper: (m, _) => m.totalTokens,
              dataLabelMapper: (m, _) =>
                  '${(m.totalTokens / _totalTokens(models) * 100).toStringAsFixed(0)}%',
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelPosition: ChartDataLabelPosition.outside,
                textStyle: _axisLabelStyle(theme),
                connectorLineSettings:
                    const ConnectorLineSettings(type: ConnectorType.curve),
              ),
              animationDuration: 0,
            ),
          ],
        ),
      ),
    );
  }

  int _totalTokens(List<ModelUsage> models) {
    final total = models.fold<int>(0, (sum, m) => sum + m.totalTokens);
    return total == 0 ? 1 : total;
  }
}

CategoryAxis _categoryAxis(ThemeData theme) => CategoryAxis(
      labelStyle: _axisLabelStyle(theme),
      labelIntersectAction: AxisLabelIntersectAction.wrap,
      majorGridLines: const MajorGridLines(width: 0),
      axisLine: AxisLine(width: 0.5, color: theme.colorScheme.outlineVariant),
      majorTickLines: const MajorTickLines(width: 0),
    );

TextStyle _axisLabelStyle(ThemeData theme) => TextStyle(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 11,
    );

/// Slice datum for the balance doughnut.
class _Slice {
  _Slice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
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
