import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/calculator_provider.dart';
import '../providers/energy_provider.dart';

/// Tarifa R$/kWh sincronizada com [EnergyRegionSelector], editável localmente.
class CostEnergyRateField extends StatefulWidget {
  const CostEnergyRateField({super.key});

  @override
  State<CostEnergyRateField> createState() => _CostEnergyRateFieldState();
}

class _CostEnergyRateFieldState extends State<CostEnergyRateField> {
  late final TextEditingController _controller;
  bool _userEditing = false;
  String _syncToken = '';

  @override
  void initState() {
    super.initState();
    final energy = context.read<EnergyProvider>();
    _controller = TextEditingController(text: _formatRate(energy.effectiveRate));
    _syncToken = _token(energy);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _token(EnergyProvider energy) =>
      '${energy.selectedState}|${energy.tariffFlag.name}|${energy.useCustomRate}|${energy.customRate}';

  String _formatRate(double rate) => rate.toStringAsFixed(4);

  void _applyFromEnergy(EnergyProvider energy, CalculatorProvider calculator) {
    _syncToken = _token(energy);
    if (!_userEditing) {
      _controller.text = _formatRate(energy.effectiveRate);
    }
    calculator.syncEnergyFromProvider(energy);
  }

  void _onRateChanged(String value, EnergyProvider energy, CalculatorProvider calculator) {
    _userEditing = true;
    final rate = double.tryParse(value.replaceAll(',', '.'));
    if (rate == null) return;

    energy.setCustomRate(rate, enabled: true);
    calculator.updateCostField(
      stateEnergy: energy.selectedState,
      customEnergyRate: rate,
      tariffFlag: energy.tariffFlag,
    );
  }

  void _resetToRegion(EnergyProvider energy, CalculatorProvider calculator) {
    _userEditing = false;
    energy.setCustomRate(null, enabled: false);
    energy.setTariffFlag(energy.tariffFlag);
    _controller.text = _formatRate(energy.effectiveRate);
    calculator.syncEnergyFromProvider(energy);
    setState(() => _syncToken = _token(energy));
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<EnergyProvider, CalculatorProvider, String>(
      selector: (_, energy, _) => _token(energy),
      builder: (context, token, _) {
        final energy = context.read<EnergyProvider>();
        final calculator = context.read<CalculatorProvider>();
        final region = energy.selectedRegion;

        if (token != _syncToken) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _applyFromEnergy(energy, calculator);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Tarifa energia (R\$/kWh)',
                helperText: region != null
                    ? '${region.uf} · ${region.distributor}'
                    : null,
                helperMaxLines: 1,
                suffixIcon: energy.useCustomRate
                    ? IconButton(
                        tooltip: 'Usar tarifa da região',
                        icon: const Icon(Icons.link, size: 18),
                        onPressed: () => _resetToRegion(energy, calculator),
                      )
                    : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _onRateChanged(v, energy, calculator),
              onTapOutside: (_) => _userEditing = false,
            ),
            if (energy.useCustomRate)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tarifa personalizada ativa',
                  style: TextStyle(fontSize: 11, color: AppTheme.warning.withValues(alpha: 0.95)),
                ),
              ),
          ],
        );
      },
    );
  }
}
