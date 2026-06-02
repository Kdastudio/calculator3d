import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../domain/models/supply_models.dart';
import '../providers/auth_provider.dart';
import '../providers/supply_provider.dart';
import '../widgets/common_widgets.dart';
import 'supply_form_dialog.dart';

class SuppliesScreen extends StatelessWidget {
  const SuppliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupplyProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final supplies = provider.supplies;
        final userId = auth.user?.id;

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
                                'Meus Insumos',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (auth.isAuthenticated)
                              IconButton(
                                tooltip: 'Sincronizar',
                                onPressed: userId == null
                                    ? null
                                    : () => provider.syncFromCloud(userId),
                                icon: const Icon(AppIcons.cloudSync, size: 20),
                              ),
                            FilledButton.icon(
                              onPressed: () => _openForm(context),
                              icon: const Icon(AppIcons.add, size: 18),
                              label: const Text('Novo insumo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cadastre filamentos, resinas e materiais com marca e fornecedor.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 20),
                        if (supplies.isEmpty)
                          const AppCard(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Nenhum insumo cadastrado.\nToque em "Novo insumo" para começar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, c) {
                              final crossCount = c.maxWidth >= 1100 ? 4 : c.maxWidth >= 720 ? 3 : c.maxWidth >= 480 ? 2 : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.4,
                                ),
                                itemCount: supplies.length,
                                itemBuilder: (context, index) =>
                                    _SupplyCard(supply: supplies[index]),
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

  Future<void> _openForm(BuildContext context, [SupplyItem? existing]) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<SupplyProvider>();
    final result = await showDialog<SupplyItem>(
      context: context,
      builder: (_) => SupplyFormDialog(
        existing: existing,
        newId: provider.newId(),
      ),
    );
    if (result == null || !context.mounted) return;

    if (existing != null) {
      await provider.updateSupply(result, userId: auth.user?.id);
    } else {
      await provider.addSupply(result, userId: auth.user?.id);
    }
  }
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.supply});

  final SupplyItem supply;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SupplyProvider>();
    final auth = context.read<AuthProvider>();
    final color = ColorUtils.fromHex(supply.color);
    final change = provider.priceChangePercent(supply);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (color != null)
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              Expanded(
                child: Text(
                  supply.name,
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
                    final result = await showDialog<SupplyItem>(
                      context: context,
                      builder: (_) => SupplyFormDialog(
                        existing: supply,
                        newId: supply.id,
                      ),
                    );
                    if (result != null && context.mounted) {
                      await provider.updateSupply(result, userId: auth.user?.id);
                    }
                  } else if (v == 'delete') {
                    await provider.deleteSupply(supply.id, userId: auth.user?.id);
                  }
                },
              ),
            ],
          ),
          if (supply.brand.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                supply.brand,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          if (supply.supplier.isNotEmpty)
            Text(
              supply.supplier,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${supply.pricePerKg.toStringAsFixed(2)}/kg',
            style: const TextStyle(
              color: AppTheme.success,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% no período',
                style: TextStyle(
                  fontSize: 11,
                  color: change >= 0 ? AppTheme.warning : AppTheme.success,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              supply.type.label,
              style: const TextStyle(fontSize: 10, color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}
