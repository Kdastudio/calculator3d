import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/calculator_constants.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../providers/calculator_provider.dart';
import 'common_widgets.dart';

class TaxSection extends StatelessWidget {
  const TaxSection({super.key, this.bare = false});

  final bool bare;

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final inputs = provider.taxInputs;
        final currency = provider.currency;
        final zeroCommission = CalculatorConstants.isBuiltinMarketplace(
          inputs.platform,
        );

        final body = LayoutBuilder(
          builder: (context, constraints) {
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: inputs.platform,
                    decoration: const InputDecoration(labelText: 'Plataforma'),
                    items: CalculatorConstants.platforms
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateTaxField(platform: value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppLayout.responsiveFields(
                    maxWidth: constraints.maxWidth,
                    fields: [
                      TextFormField(
                        key: ValueKey(
                          'commission-${inputs.platform}-${inputs.commission}',
                        ),
                        initialValue: inputs.commission.toString(),
                        enabled: !zeroCommission,
                        decoration: InputDecoration(
                          labelText: 'Comissão (%)',
                          helperText: zeroCommission
                              ? 'Taxa incluída na taxa fixa da plataforma'
                              : null,
                          helperMaxLines: 2,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: zeroCommission
                            ? null
                            : (v) => provider.updateTaxField(
                                commission: double.tryParse(v) ?? 0,
                              ),
                      ),
                      TextFormField(
                        key: ValueKey(
                          'fixed-${inputs.platform}-${inputs.fixedFee}',
                        ),
                        initialValue: inputs.fixedFee.toString(),
                        decoration: InputDecoration(
                          labelText:
                              'Taxa Fixa (${currency.flag} ${currency.code})',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => provider.updateTaxField(
                          fixedFee: double.tryParse(v) ?? 0,
                        ),
                      ),
                      TextFormField(
                        key: ValueKey('shipping-${inputs.shipping}'),
                        initialValue: inputs.shipping.toString(),
                        decoration: InputDecoration(
                          labelText:
                              'Frete (${currency.flag} ${currency.code})',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => provider.updateTaxField(
                          shipping: double.tryParse(v) ?? 0,
                        ),
                      ),
                      TextFormField(
                        key: ValueKey('nf-${inputs.taxNF}'),
                        initialValue: inputs.taxNF.toString(),
                        decoration: const InputDecoration(labelText: 'NF (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => provider.updateTaxField(
                          taxNF: double.tryParse(v) ?? 0,
                        ),
                      ),
                      TextFormField(
                        key: ValueKey('extra-p-${inputs.extraTaxPercent}'),
                        initialValue: inputs.extraTaxPercent.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Taxa Extra (%)',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => provider.updateTaxField(
                          extraTaxPercent: double.tryParse(v) ?? 0,
                        ),
                      ),
                      TextFormField(
                        key: ValueKey('extra-v-${inputs.extraTaxValue}'),
                        initialValue: inputs.extraTaxValue.toString(),
                        decoration: InputDecoration(
                          labelText:
                              'Taxa Extra (${currency.flag} ${currency.code})',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => provider.updateTaxField(
                          extraTaxValue: double.tryParse(v) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Calcular Taxas',
                    onPressed: provider.calculate,
                  ),
                ],
              );
            },
          );

        if (bare) return body;
        return AppCard(
          title: 'Impostos e taxas',
          icon: AppIcons.wallet,
          child: body,
        );
      },
    );
  }
}
