import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/calculator_models.dart';

class CostBreakdownChart extends StatelessWidget {
  const CostBreakdownChart({super.key, required this.details});

  final CostDetails details;

  @override
  Widget build(BuildContext context) {
    final slices = <_Slice>[
      _Slice('Filamento', details.filament, AppTheme.info),
      _Slice('Energia', details.energy, const Color(0xFF06B6D4)),
      _Slice('Depreciação', details.depreciation, AppTheme.warning),
      _Slice('Extras', details.extras, AppTheme.textMuted),
      _Slice('Risco', details.risk, AppTheme.danger),
      _Slice('Lucro', details.profit, AppTheme.success),
    ].where((s) => s.value > 0).toList();

    if (slices.isEmpty) return const SizedBox.shrink();

    final total = slices.fold(0.0, (sum, s) => sum + s.value);

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: slices
                    .map(
                      (s) => PieChartSectionData(
                        value: s.value,
                        title: '${(s.value / total * 100).toStringAsFixed(0)}%',
                        color: s.color,
                        radius: 48,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slice {
  const _Slice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class PriceHistoryChart extends StatelessWidget {
  const PriceHistoryChart({super.key, required this.prices, required this.labels});

  final List<double> prices;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (prices.length < 2) {
      return const Center(
        child: Text(
          'Histórico insuficiente para gráfico',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.05;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppTheme.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < prices.length; i++) FlSpot(i.toDouble(), prices[i]),
              ],
              isCurved: true,
              color: AppTheme.accent,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.accent.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
