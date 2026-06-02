import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/stock_models.dart';
import '../providers/calculator_provider.dart';
import '../providers/stock_provider.dart';
import 'common_widgets.dart';

class QuoteStockSection extends StatelessWidget {
  const QuoteStockSection({super.key, this.bare = false});

  final bool bare;

  @override
  Widget build(BuildContext context) {
    return Selector2<CalculatorProvider, StockProvider, (List, bool)>(
      selector: (_, calculator, stock) =>
          (calculator.stockAllocations, calculator.quoteData.isFinalized),
      builder: (context, _, _) {
        final calculator = context.read<CalculatorProvider>();
        final stock = context.read<StockProvider>();
        final allocations = calculator.stockAllocations;
        final currency = calculator.currency;
        final stockCost = calculator.stockMaterialCost;
        final locked = calculator.quoteData.isFinalized;

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
                locked
                    ? 'Orçamento finalizado — estoque já foi atualizado.'
                    : 'Informe o que será consumido do estoque. O custo entra no cálculo e será descontado ao finalizar.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (!locked) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: stock.items.isEmpty
                        ? null
                        : () => _pickStockItem(context, stock, calculator),
                    icon: const Icon(AppIcons.add, size: 16),
                    label: const Text('Adicionar material'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (allocations.isEmpty)
                const Text(
                  'Nenhum material do estoque vinculado.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                )
              else
                ...allocations.map((allocation) {
                  final item = stock.findById(allocation.stockItemId);
                  final lineCost =
                      item?.costForQuantity(allocation.quantityToUse) ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: allocation.stockItemId,
                                decoration: const InputDecoration(
                                  labelText: 'Material',
                                  isDense: true,
                                ),
                                items: stock.items
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(
                                          '${s.name} (${s.displayQuantity})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: locked
                                    ? null
                                    : (v) {
                                        if (v == null) return;
                                        calculator.updateStockAllocation(
                                          allocation.id,
                                          stockItemId: v,
                                        );
                                      },
                              ),
                            ),
                            if (!locked)
                              IconButton(
                                onPressed: () => calculator
                                    .removeStockAllocation(allocation.id),
                                icon: const Icon(
                                  AppIcons.delete,
                                  color: AppTheme.danger,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey(
                                  'qty-${allocation.id}-${allocation.quantityToUse}',
                                ),
                                initialValue: allocation.quantityToUse > 0
                                    ? allocation.quantityToUse.toString()
                                    : '',
                                enabled: !locked,
                                decoration: InputDecoration(
                                  labelText:
                                      'Quantidade a usar (${item?.unit ?? ''})',
                                  helperText: item != null
                                      ? 'Disponível: ${item.quantityOnHand} ${item.unit}'
                                      : null,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: locked
                                    ? null
                                    : (v) => calculator.updateStockAllocation(
                                        allocation.id,
                                        quantityToUse:
                                            double.tryParse(
                                              v.replaceAll(',', '.'),
                                            ) ??
                                            0,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Custo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(lineCost, currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              if (stockCost > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Custo total do estoque',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      CurrencyFormatter.format(stockCost, currency),
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (calculator.quoteData.stockMovements.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionLabel('Baixa registrada neste orçamento'),
                const SizedBox(height: 8),
                ...calculator.quoteData.stockMovements.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${m.itemName}: -${m.quantityUsed} ${m.unit} → saldo ${m.quantityAfter} ${m.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );

        if (bare) return body;
        return AppCard(
          title: 'Materiais do estoque no orçamento',
          icon: AppIcons.warehouse,
          child: body,
        );
      },
    );
  }

  Future<void> _pickStockItem(
    BuildContext context,
    StockProvider stock,
    CalculatorProvider calculator,
  ) async {
    final available = stock.items
        .where(
          (s) => !calculator.stockAllocations.any((a) => a.stockItemId == s.id),
        )
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os materiais já foram adicionados.'),
        ),
      );
      return;
    }

    final selected = await showDialog<StockItem>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecionar material'),
        children: available
            .map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, s),
                child: Text('${s.name} — ${s.displayQuantity}'),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      calculator.addStockAllocation(selected.id);
    }
  }
}
