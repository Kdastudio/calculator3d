import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/calculator_models.dart';
import '../../domain/models/supply_models.dart';
import '../providers/calculator_provider.dart';
import '../providers/supply_provider.dart';
import 'common_widgets.dart';

class MultiFilamentSection extends StatelessWidget {
  const MultiFilamentSection({super.key, this.bare = false});

  final bool bare;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalculatorProvider, SupplyProvider>(
      builder: (context, calculator, supplies, _) {
        final filaments = calculator.costInputs.filaments;

        final body = filaments.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Use filamento único acima ou adicione cores/materiais diferentes.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: calculator.addFilamentUsage,
                      icon: const Icon(AppIcons.add, size: 16),
                      label: const Text('Adicionar filamento'),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < filaments.length; i++)
                      _FilamentRow(
                        index: i,
                        usage: filaments[i],
                        supplies: supplies.activeSupplies,
                        onChanged: (u) => calculator.updateFilamentUsage(i, u),
                        onRemove: () => calculator.removeFilamentUsage(i),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${filaments.fold(0.0, (s, f) => s + f.weightGrams).toStringAsFixed(1)}g',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );

        if (bare) return body;
        return AppCard(
          title: 'Multi-filamento',
          icon: AppIcons.palette,
          trailing: IconButton(
            icon: const Icon(AppIcons.addCircle, color: AppTheme.textSecondary),
            onPressed: calculator.addFilamentUsage,
            tooltip: 'Adicionar filamento',
          ),
          child: body,
        );
      },
    );
  }
}

class _FilamentRow extends StatelessWidget {
  const _FilamentRow({
    required this.index,
    required this.usage,
    required this.supplies,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final FilamentUsage usage;
  final List<SupplyItem> supplies;
  final ValueChanged<FilamentUsage> onChanged;
  final VoidCallback onRemove;

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(usage.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (color != null)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              Text(
                'Filamento ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  AppIcons.delete,
                  size: 16,
                  color: AppTheme.danger,
                ),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: usage.supplyId,
            decoration: const InputDecoration(labelText: 'Insumo'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Manual')),
              ...supplies.map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.displayLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (id) {
              SupplyItem? supply;
              for (final s in supplies) {
                if (s.id == id) {
                  supply = s;
                  break;
                }
              }
              onChanged(
                usage.copyWith(
                  supplyId: id,
                  label: supply?.name ?? usage.label,
                  pricePerKg: supply?.pricePerKg ?? usage.pricePerKg,
                  color: supply?.color ?? usage.color,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: usage.weightGrams > 0
                      ? usage.weightGrams.toString()
                      : '',
                  decoration: const InputDecoration(labelText: 'Peso (g)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onChanged(
                    usage.copyWith(weightGrams: double.tryParse(v) ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: usage.pricePerKg.toString(),
                  decoration: const InputDecoration(labelText: 'R\$/kg'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onChanged(
                    usage.copyWith(pricePerKg: double.tryParse(v) ?? 0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SupplySelector extends StatelessWidget {
  const SupplySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalculatorProvider, SupplyProvider>(
      builder: (context, calculator, supplies, _) {
        final selectedId = calculator.costInputs.selectedSupplyId;
        final active = supplies.activeSupplies;

        return DropdownButtonFormField<String?>(
          initialValue: active.any((s) => s.id == selectedId)
              ? selectedId
              : null,
          decoration: const InputDecoration(labelText: 'Insumo / Filamento'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Preço manual')),
            ...active.map(
              (s) => DropdownMenuItem(
                value: s.id,
                child: Text(
                  '${s.name} · ${s.brand} · R\$ ${s.pricePerKg.toStringAsFixed(2)}/kg',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (id) {
            if (id == null) {
              calculator.selectSupply(null);
              return;
            }
            calculator.selectSupply(supplies.findById(id));
          },
        );
      },
    );
  }
}
