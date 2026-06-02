import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/calculator_models.dart';
import '../providers/calculator_provider.dart';
import 'common_widgets.dart';
import 'cost_breakdown_chart.dart';

class ResultsSection extends StatelessWidget {
  const ResultsSection({super.key, this.bare = false});

  final bool bare;

  @override
  Widget build(BuildContext context) {
    return Selector<CalculatorProvider, CalculationResult?>(
      selector: (_, p) => p.results,
      builder: (context, results, _) {
        if (results == null) {
          if (bare) {
            return Text(
              'Calcule os custos para ver o resumo.',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          return const SizedBox.shrink();
        }

        final provider = context.read<CalculatorProvider>();
        final currency = provider.currency;
        final details = results.details;

        final metrics = MetricsPanel(
          premium: bare,
          metrics: [
            MetricCell(
              label: 'Custo produção',
              value: CurrencyFormatter.format(results.totalCost, currency),
              icon: AppIcons.layers,
              accentColor: AppTheme.textMuted,
            ),
            MetricCell(
              label: 'Preço sugerido',
              value: CurrencyFormatter.format(results.finalPrice, currency),
              icon: AppIcons.tag,
              accentColor: AppTheme.success,
              bold: bare,
            ),
            MetricCell(
              label: 'Lucro bruto',
              value: CurrencyFormatter.format(
                results.finalPrice - results.totalCost,
                currency,
              ),
              icon: AppIcons.trending,
              accentColor: AppTheme.warning,
              bold: bare,
            ),
            MetricCell(
              label: 'Impostos',
              value: CurrencyFormatter.format(results.totalTaxes, currency),
              icon: AppIcons.receipt,
              accentColor: AppTheme.info,
            ),
          ],
        );

        final demonstrativo = Column(
          children: [
            _detailRow(
              'Filamento (${details.weight.toStringAsFixed(1)} g)',
              CurrencyFormatter.format(details.filament, currency),
            ),
            _detailRow(
              'Energia (${details.hours.toStringAsFixed(1)} h · ${details.powerUsed.toStringAsFixed(0)} W · R\$ ${details.energyRate.toStringAsFixed(4)}/kWh)',
              CurrencyFormatter.format(details.energy, currency),
            ),
            _detailRow(
              'Depreciação',
              CurrencyFormatter.format(details.depreciation, currency),
            ),
            if (details.postProcessing > 0)
              _detailRow(
                'Pós-processamento',
                CurrencyFormatter.format(details.postProcessing, currency),
              ),
            if (details.stockMaterials > 0)
              _detailRow(
                'Estoque',
                CurrencyFormatter.format(details.stockMaterials, currency),
              ),
            _detailRow(
              'Extras / insumos',
              CurrencyFormatter.format(details.extras, currency),
            ),
            _detailRow(
              'Risco (${details.riskPercent.toStringAsFixed(0)}%)',
              CurrencyFormatter.format(details.risk, currency),
            ),
            if (details.batchDiscount > 0)
              _detailRow(
                'Desconto batch (${details.batchQuantity} un)',
                '- ${CurrencyFormatter.format(details.batchDiscount, currency)}',
              ),
            const Divider(height: 16),
            _detailRow(
              'Lucro (${details.profitMargin.toStringAsFixed(0)}%)',
              CurrencyFormatter.format(details.profit, currency),
              highlight: true,
            ),
          ],
        );

        if (bare) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              metrics,
              if (results.unitPrice != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Unitário (${details.batchQuantity} un): ${CurrencyFormatter.format(results.unitPrice!, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              demonstrativo,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            MetricsPanel(
              metrics: [
                MetricCell(
                  label: 'Custo produção',
                  value: CurrencyFormatter.format(results.totalCost, currency),
                  icon: AppIcons.layers,
                  accentColor: AppTheme.textMuted,
                ),
                MetricCell(
                  label: 'Preço sugerido',
                  value: CurrencyFormatter.format(results.finalPrice, currency),
                  icon: AppIcons.tag,
                  accentColor: AppTheme.success,
                ),
                MetricCell(
                  label: 'Lucro bruto',
                  value: CurrencyFormatter.format(
                    results.finalPrice - results.totalCost,
                    currency,
                  ),
                  icon: AppIcons.trending,
                  accentColor: AppTheme.warning,
                ),
                MetricCell(
                  label: 'Impostos',
                  value: CurrencyFormatter.format(results.totalTaxes, currency),
                  icon: AppIcons.receipt,
                  accentColor: AppTheme.info,
                ),
              ],
            ),
            if (results.unitPrice != null) ...[
              const SizedBox(height: 6),
              Text(
                'Unitário (${details.batchQuantity} un): ${CurrencyFormatter.format(results.unitPrice!, currency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            AppCard(
              title: 'Composição de custos',
              icon: AppIcons.chartPie,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CostBreakdownChart(details: details),
            ),
            const SizedBox(height: 16),
            AppCard(
              title: 'Demonstrativo',
              icon: AppIcons.receipt,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: demonstrativo,
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: highlight ? AppTheme.success : AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              color: highlight ? AppTheme.success : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
