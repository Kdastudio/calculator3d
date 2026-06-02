import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/energy_regions.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/calculator_provider.dart';
import 'common_widgets.dart';

class MarginPresetsRow extends StatelessWidget {
  const MarginPresetsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final selected = provider.costInputs.marginPresetId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Preset de margem'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MarginPreset.all.map((preset) {
                final isSelected = selected == preset.id;
                return ChoiceChip(
                  label: Text(preset.label),
                  selected: isSelected,
                  onSelected: (_) => provider.applyMarginPreset(preset.id),
                  selectedColor: AppTheme.accent.withValues(alpha: 0.25),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class WhatIfSlider extends StatelessWidget {
  const WhatIfSlider({super.key, this.bare = false});

  final bool bare;

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final base = provider.costInputs.profitMargin;
        final current = provider.costInputs.whatIfProfitMargin ?? base;

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Margem de lucro: ${current.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Slider(
              value: current.clamp(0, 300),
              min: 0,
              max: 300,
              divisions: 60,
              label: '${current.toStringAsFixed(0)}%',
              onChanged: (v) => provider.setWhatIfProfitMargin(v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => provider.setWhatIfProfitMargin(null),
                  child: const Text('Resetar'),
                ),
                Text(
                  'Base: ${base.toStringAsFixed(0)}%',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        );

        if (bare) return body;
        return AppCard(
          title: 'Simulador de margem',
          icon: AppIcons.tune,
          child: body,
        );
      },
    );
  }
}
