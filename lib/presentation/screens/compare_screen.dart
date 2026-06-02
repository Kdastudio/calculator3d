import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/calculator_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/supply_models.dart';
import '../providers/calculator_provider.dart';
import '../providers/supply_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/cost_breakdown_chart.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final Set<String> _selectedIds = {};
  bool _defaultsSet = false;

  void _ensureDefaults(List<SupplyItem> active) {
    if (_defaultsSet || active.isEmpty) return;
    _defaultsSet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedIds.addAll(active.take(3).map((s) => s.id)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupplyProvider, CalculatorProvider>(
      builder: (context, supplies, calculator, _) {
        final active = supplies.activeSupplies
            .where((s) => s.type == SupplyType.filament)
            .toList();

        _ensureDefaults(active);

        final selected = active.where((s) => _selectedIds.contains(s.id)).toList();
        final comparison = selected.isEmpty
            ? <SupplyComparisonResult>[]
            : calculator.compareSupplies(selected);
        final cheapest = supplies.rankCheapest(type: SupplyType.filament);

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppLayout.pagePadding),
              sliver: SliverToBoxAdapter(
                child: AppLayout.pageContainer(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comparar Insumos',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Simule o mesmo job com diferentes marcas e fornecedores.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 20),
                        AppCard(
                          title: 'Selecionar insumos',
                          icon: AppIcons.compare,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: active.map((s) {
                              final isSelected = _selectedIds.contains(s.id);
                              return FilterChip(
                                label: Text('${s.brand} · R\$ ${s.pricePerKg.toStringAsFixed(0)}'),
                                selected: isSelected,
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      if (_selectedIds.length < 5) _selectedIds.add(s.id);
                                    } else {
                                      _selectedIds.remove(s.id);
                                    }
                                  });
                                },
                                selectedColor: AppTheme.accent.withValues(alpha: 0.25),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (cheapest.isNotEmpty)
                          AppCard(
                            title: 'Ranking — PLA/Filamento mais barato',
                            icon: AppIcons.trophy,
                            child: Column(
                              children: [
                                for (var i = 0; i < cheapest.take(5).length; i++)
                                  _RankRow(
                                    rank: i + 1,
                                    supply: cheapest[i],
                                    isBest: i == 0,
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (comparison.isEmpty)
                          const AppCard(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Selecione ao menos um insumo para comparar.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          )
                        else ...[
                          AppCard(
                            title: 'Resultado da simulação',
                            icon: AppIcons.chartBar,
                            child: Column(
                              children: [
                                for (final r in comparison)
                                  _ComparisonRow(
                                    result: r,
                                    currency: calculator.currency,
                                    isBest: r == comparison.first,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (comparison.length >= 2)
                            AppCard(
                              title: 'Histórico de preços',
                              icon: AppIcons.chartLine,
                              child: Column(
                                children: [
                                  for (final r in comparison.take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.supply.displayLabel,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          _SupplyHistoryChart(supplyId: r.supply.id),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.supply, required this.isBest});

  final int rank;
  final SupplyItem supply;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isBest
                ? Colors.greenAccent.withValues(alpha: 0.2)
                : AppTheme.accent.withValues(alpha: 0.15),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isBest ? Colors.greenAccent : AppTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(supply.displayLabel)),
          Text(
            'R\$ ${supply.pricePerKg.toStringAsFixed(2)}/kg',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBest ? Colors.greenAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.result,
    required this.currency,
    required this.isBest,
  });

  final SupplyComparisonResult result;
  final CurrencySpec currency;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBest
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : AppTheme.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBest
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : AppTheme.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.supply.displayLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (isBest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MENOR PREÇO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _metric('Material', CurrencyFormatter.format(result.materialCost, currency)),
          _metric('Custo total', CurrencyFormatter.format(result.totalCost, currency)),
          _metric(
            'Preço final',
            CurrencyFormatter.format(result.finalPrice, currency),
            highlight: true,
          ),
          _metric('Lucro', CurrencyFormatter.format(result.profit, currency)),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Colors.greenAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplyHistoryChart extends StatelessWidget {
  const _SupplyHistoryChart({required this.supplyId});

  final String supplyId;

  @override
  Widget build(BuildContext context) {
    final history = context.read<SupplyProvider>().historyForSupply(supplyId);
    if (history.length < 2) {
      return const Text(
        'Sem histórico suficiente',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
      );
    }
    return PriceHistoryChart(
      prices: history.map((h) => h.price).toList(),
      labels: history.map((h) => '${h.recordedAt.day}/${h.recordedAt.month}').toList(),
    );
  }
}
