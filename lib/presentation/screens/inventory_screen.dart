import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/stock_models.dart';
import '../providers/stock_provider.dart';
import '../widgets/common_widgets.dart';
import 'stock_form_dialog.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _openForm(BuildContext context, {StockItem? existing}) async {
    final provider = context.read<StockProvider>();
    final result = await showDialog<StockItem>(
      context: context,
      builder: (_) => StockFormDialog(
        existing: existing,
        newId: provider.newId(),
      ),
    );
    if (result == null || !context.mounted) return;

    if (existing != null) {
      await provider.updateItem(result);
    } else {
      await provider.addItem(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = provider.items;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppLayout.pagePadding),
              sliver: SliverToBoxAdapter(
                child: AppLayout.pageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Estoque',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openForm(context),
                            icon: const Icon(AppIcons.add, size: 18),
                            label: const Text('Novo material'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Controle materiais físicos. Vincule ao orçamento na calculadora para descontar ao finalizar.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      if (items.isEmpty)
                        const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Nenhum material no estoque.\nCadastre filamentos, resinas e insumos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, c) {
                            final crossCount = c.maxWidth >= 1100
                                ? 4
                                : c.maxWidth >= 720
                                    ? 3
                                    : c.maxWidth >= 480
                                        ? 2
                                        : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.35,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) =>
                                  _StockCard(item: items[index], onEdit: () => _openForm(context, existing: items[index])),
                            );
                          },
                        ),
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

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item, required this.onEdit});

  final StockItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StockProvider>();
    final lowStock = item.quantityOnHand <= 100 && item.unit == 'g';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
                onSelected: (v) async {
                  if (v == 'edit') {
                    onEdit();
                  } else if (v == 'delete') {
                    await provider.deleteItem(item.id);
                  }
                },
              ),
            ],
          ),
          if (item.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.notes, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ),
          const SizedBox(height: 12),
          Text(
            item.displayQuantity,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: lowStock ? AppTheme.warning : AppTheme.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Custo: R\$ ${item.unitCost.toStringAsFixed(item.unit == 'g' ? 4 : 2)}/${item.unit}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (lowStock)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Estoque baixo',
                style: TextStyle(fontSize: 11, color: AppTheme.warning.withValues(alpha: 0.9)),
              ),
            ),
        ],
      ),
    );
  }
}
