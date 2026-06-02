import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/energy_regions.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/calculator_provider.dart';
import '../providers/energy_provider.dart';
import 'common_widgets.dart';

class EnergyRegionSelector extends StatelessWidget {
  const EnergyRegionSelector({super.key, this.bare = false});

  final bool bare;

  @override
  Widget build(BuildContext context) {
    return Consumer2<EnergyProvider, CalculatorProvider>(
      builder: (context, energy, calculator, _) {
        final region = energy.selectedRegion;
        final rate = energy.effectiveRate;

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const SectionLabel('Filtrar por região'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RegionChip(
                    label: 'Todos',
                    selected: energy.selectedRegionFilter == null,
                    onTap: () {
                      energy.setRegionFilter(null);
                      calculator.syncEnergyFromProvider(energy);
                    },
                  ),
                  ...EnergyRegion.regions.map(
                    (r) => _RegionChip(
                      label: r,
                      selected: energy.selectedRegionFilter == r,
                      onTap: () {
                        energy.setRegionFilter(r);
                        calculator.syncEnergyFromProvider(energy);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: energy.dropdownStateValue,
                decoration: const InputDecoration(labelText: 'Estado (UF)'),
                items: energy.filteredRegions
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.state,
                        child: Text('${r.uf} — ${r.state}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  energy.setState(value);
                  calculator.syncEnergyFromProvider(energy);
                },
              ),
              if (region != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              region.uf,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            region.region,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        region.distributor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tarifa: R\$ ${rate.toStringAsFixed(4)}/kWh',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<TariffFlag>(
                isExpanded: true,
                initialValue: energy.tariffFlag,
                decoration: const InputDecoration(
                  labelText: 'Bandeira Tarifária',
                ),
                items: TariffFlag.values
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f == TariffFlag.none
                              ? f.label
                              : '${f.label} (+R\$ ${f.surchargePerKwh.toStringAsFixed(5)}/kWh)',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  energy.setTariffFlag(value);
                  calculator.syncEnergyFromProvider(energy);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tarifa personalizada'),
                subtitle: const Text('Usar valor do seu contrato'),
                value: energy.useCustomRate,
                onChanged: (v) {
                  energy.setCustomRate(
                    energy.customRate ?? region?.ratePerKwh,
                    enabled: v,
                  );
                  if (!v) energy.setCustomRate(null, enabled: false);
                  calculator.syncEnergyFromProvider(energy);
                },
              ),
              if (energy.useCustomRate)
                TextFormField(
                  initialValue: energy.customRate?.toStringAsFixed(4) ?? '',
                  decoration: const InputDecoration(
                    labelText: 'R\$/kWh personalizado',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final rate = double.tryParse(v.replaceAll(',', '.'));
                    energy.setCustomRate(rate, enabled: true);
                    calculator.syncEnergyFromProvider(energy);
                  },
                ),
            ],
          );

        if (bare) return body;
        return AppCard(
          title: 'Energia elétrica',
          icon: AppIcons.bolt,
          child: body,
        );
      },
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.accent.withValues(alpha: 0.25),
      checkmarkColor: AppTheme.accent,
      labelStyle: TextStyle(
        color: selected ? AppTheme.accent : AppTheme.textMuted,
        fontSize: 12,
      ),
    );
  }
}
