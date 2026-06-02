import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/constants/calculator_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/calculator_provider.dart';
import 'common_widgets.dart';
import 'cost_energy_rate_field.dart';
import 'margin_presets_row.dart';
import 'multi_filament_section.dart';

class CostSection extends StatefulWidget {
  const CostSection({super.key, this.bare = false});

  final bool bare;

  @override
  State<CostSection> createState() => _CostSectionState();
}

class _CostSectionState extends State<CostSection> {
  late final TextEditingController _productNameController;
  late final TextEditingController _filamentPriceController;
  late final TextEditingController _modelWeightController;
  late final TextEditingController _printTimeController;
  late final TextEditingController _printerModelController;
  late final TextEditingController _printerValueController;
  late final TextEditingController _printerPowerController;
  late final TextEditingController _lifespanController;
  late final TextEditingController _riskController;
  late final TextEditingController _extrasController;
  late final TextEditingController _profitController;
  late final TextEditingController _postProcessingController;
  late final TextEditingController _batchController;

  @override
  void initState() {
    super.initState();
    final inputs = context.read<CalculatorProvider>().costInputs;
    _productNameController = TextEditingController(text: inputs.productName);
    _filamentPriceController = TextEditingController(
      text: inputs.filamentPrice.toString(),
    );
    _modelWeightController = TextEditingController(
      text: inputs.modelWeight.toString(),
    );
    _printTimeController = TextEditingController(text: inputs.printTime);
    _printerModelController = TextEditingController(text: inputs.printerModel);
    _printerValueController = TextEditingController(
      text: CurrencyFormatter.format(
        inputs.printerValue,
        context.read<CalculatorProvider>().currency,
      ),
    );
    _printerPowerController = TextEditingController(
      text: inputs.printerPower.toString(),
    );
    _lifespanController = TextEditingController(
      text: inputs.lifespanHours.toString(),
    );
    _riskController = TextEditingController(
      text: inputs.riskPercent.toString(),
    );
    _extrasController = TextEditingController(text: inputs.extras.toString());
    _profitController = TextEditingController(
      text: inputs.profitMargin.toString(),
    );
    _postProcessingController = TextEditingController(
      text: inputs.postProcessingCost.toString(),
    );
    _batchController = TextEditingController(
      text: inputs.batchQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _filamentPriceController.dispose();
    _modelWeightController.dispose();
    _printTimeController.dispose();
    _printerModelController.dispose();
    _printerValueController.dispose();
    _printerPowerController.dispose();
    _lifespanController.dispose();
    _riskController.dispose();
    _extrasController.dispose();
    _profitController.dispose();
    _postProcessingController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final inputs = provider.costInputs;
        final currency = provider.currency;

        final body = LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final narrow = !w.isFinite || w < 420;
                      final currencyField = DropdownButtonFormField<String>(
                        initialValue: currency.code,
                        decoration: const InputDecoration(
                          labelText: 'Moeda',
                          isDense: true,
                        ),
                        items: CalculatorConstants.currencies
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.code,
                                child: Text('${c.flag} ${c.code}'),
                              ),
                            )
                            .toList(),
                        onChanged: (code) {
                          if (code == null) return;
                          final selected = CalculatorConstants.currencies
                              .firstWhere((c) => c.code == code);
                          provider.setCurrency(selected);
                          _printerValueController.text =
                              CurrencyFormatter.format(
                                inputs.printerValue,
                                selected,
                              );
                        },
                      );

                      final autoControls = Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Cálculo automático',
                            child: Switch(
                              value: provider.autoCalculate,
                              onChanged: provider.setAutoCalculate,
                            ),
                          ),
                          StatusDot(
                            label: provider.autoCalculate ? 'Auto' : 'Manual',
                            active: provider.autoCalculate,
                          ),
                        ],
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            currencyField,
                            const SizedBox(height: 8),
                            autoControls,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: currencyField),
                          autoControls,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  const MarginPresetsRow(),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  FormFieldGroup(
                    title: 'Produto',
                    child: Column(
                      children: [
                        _fullWidthField(
                          controller: _productNameController,
                          label: 'Nome do produto',
                          hint: 'Ex: Articulado Dragon V2',
                          onChanged: (v) => provider.updateCostField(productName: v),
                        ),
                        const SizedBox(height: AppTheme.fieldSpacing),
                        const SupplySelector(),
                        const SizedBox(height: AppTheme.fieldSpacing),
                        AppLayout.responsiveFields(
                          maxWidth: w,
                          fields: [
                            _numberField(
                              controller: _filamentPriceController,
                              label: 'Preço filamento (kg)',
                              onChanged: (v) => provider.updateCostField(
                                filamentPrice: double.tryParse(v) ?? 0,
                              ),
                            ),
                            _numberField(
                              controller: _modelWeightController,
                              label: 'Peso (g)',
                              onChanged: (v) => provider.updateCostField(
                                modelWeight: double.tryParse(v) ?? 0,
                              ),
                            ),
                            _textField(
                              controller: _printTimeController,
                              label: 'Tempo (h:mm)',
                              hint: '2:35',
                              onChanged: (v) =>
                                  provider.updateCostField(printTime: v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  FormFieldGroup(
                    title: 'Máquina e energia',
                    child: AppLayout.responsiveFields(
                      maxWidth: w,
                      fields: [
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: inputs.printerModel),
                          optionsBuilder: (query) {
                            return CalculatorConstants.popularPrinters.keys.where(
                              (model) => model.toLowerCase().contains(
                                query.text.toLowerCase(),
                              ),
                            );
                          },
                          onSelected: (value) {
                            _printerModelController.text = value;
                            provider.updateCostField(printerModel: value);
                            final updated = provider.costInputs;
                            _printerValueController.text =
                                CurrencyFormatter.format(
                                  updated.printerValue,
                                  currency,
                                );
                            _printerPowerController.text =
                                updated.printerPower.toString();
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmitted) {
                            _printerModelController.value = controller.value;
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Modelo impressora',
                              ),
                              onChanged: (v) =>
                                  provider.updateCostField(printerModel: v),
                            );
                          },
                        ),
                        _textField(
                          controller: _printerValueController,
                          label: 'Valor máquina (${currency.code})',
                          onChanged: (v) => provider.updateCostField(
                            printerValue: CurrencyFormatter.parse(v),
                          ),
                        ),
                        _numberField(
                          controller: _printerPowerController,
                          label: 'Potência (W)',
                          hint: '150',
                          onChanged: (v) => provider.updateCostField(
                            printerPower: double.tryParse(v) ?? 0,
                          ),
                        ),
                        const CostEnergyRateField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  FormFieldGroup(
                    title: 'Custos e margem',
                    child: AppLayout.responsiveFields(
                      maxWidth: w,
                      fields: [
                        _numberField(
                          controller: _lifespanController,
                          label: 'Vida útil (h)',
                          onChanged: (v) => provider.updateCostField(
                            lifespanHours: double.tryParse(v) ?? 0,
                          ),
                        ),
                        _numberField(
                          controller: _riskController,
                          label: 'Risco (%)',
                          onChanged: (v) => provider.updateCostField(
                            riskPercent: double.tryParse(v) ?? 0,
                          ),
                        ),
                        _numberField(
                          controller: _postProcessingController,
                          label: 'Pós-processamento',
                          onChanged: (v) => provider.updateCostField(
                            postProcessingCost: double.tryParse(v) ?? 0,
                          ),
                        ),
                        _numberField(
                          controller: _extrasController,
                          label: 'Taxa extra',
                          onChanged: (v) => provider.updateCostField(
                            extras: double.tryParse(v) ?? 0,
                          ),
                        ),
                        _numberField(
                          controller: _profitController,
                          label: 'Margem lucro (%)',
                          onChanged: (v) => provider.updateCostField(
                            profitMargin: double.tryParse(v) ?? 0,
                          ),
                        ),
                        _numberField(
                          controller: _batchController,
                          label: 'Quantidade batch',
                          onChanged: (v) => provider.updateCostField(
                            batchQuantity: int.tryParse(v) ?? 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.sectionSpacing),
                  PrimaryButton(
                    label: provider.autoCalculate
                        ? 'Recalcular'
                        : 'Calcular custos',
                    icon: AppIcons.play,
                    onPressed: provider.calculate,
                  ),
                ],
              );
            },
          );

        if (widget.bare) return body;
        return AppCard(
          title: 'Custos de impressão',
          icon: AppIcons.calculator,
          child: body,
        );
      },
    );
  }

  Widget _fullWidthField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: onChanged,
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: onChanged,
    );
  }
}
