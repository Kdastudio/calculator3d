import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/calculator_provider.dart';
import 'common_widgets.dart';
import 'finalize_quote_bar.dart';

class QuoteSection extends StatelessWidget {
  const QuoteSection({super.key, this.bare = false});

  final bool bare;

  Future<void> _pickLogo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    if (!context.mounted) return;
    context.read<CalculatorProvider>().setCompanyLogo(bytes);
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final provider = context.read<CalculatorProvider>();
    final bytes = await provider.generateQuotePdf();
    if (!context.mounted) return;

    final clientName = provider.quoteData.clientName.isEmpty
        ? 'cliente'
        : provider.quoteData.clientName.replaceAll(' ', '_');

    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'orcamento_$clientName.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final data = provider.quoteData;
        final currency = provider.currency;

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickLogo(context),
                      icon: const Icon(AppIcons.upload, size: 16),
                      label: Text(data.companyLogoBytes != null ? 'Trocar Logo' : 'Upload Logo'),
                    ),
                  ),
                  if (data.companyLogoBytes != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => provider.setCompanyLogo(null),
                      icon: const Icon(AppIcons.delete, color: AppTheme.danger, size: 18),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _field('Nome da sua Empresa', data.companyName, (v) {
                provider.updateQuoteData(data.copyWith(companyName: v));
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('E-mail da Empresa', data.companyEmail, (v) {
                      provider.updateQuoteData(data.copyWith(companyEmail: v));
                    }, hint: 'contato@empresa.com'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Telefone da Empresa', data.companyPhone, (v) {
                      provider.updateQuoteData(data.copyWith(companyPhone: v));
                    }, hint: '(00) 00000-0000'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field('Slogan / Subtítulo', data.companySlogan, (v) {
                provider.updateQuoteData(data.copyWith(companySlogan: v));
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('Nome do Cliente', data.clientName, (v) {
                      provider.updateQuoteData(data.copyWith(clientName: v));
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Contato', data.contact, (v) {
                      provider.updateQuoteData(data.copyWith(contact: v));
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('Número do Orçamento', data.quoteNumber, (v) {
                      provider.updateQuoteData(data.copyWith(quoteNumber: v));
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: data.date,
                      decoration: const InputDecoration(labelText: 'Data'),
                      onChanged: (v) => provider.updateQuoteData(data.copyWith(date: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Itens'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    children: [
                      TextButton(
                        onPressed: provider.addQuoteItem,
                        child: const Text('ADICIONAR ITEM'),
                      ),
                      TextButton(
                        onPressed: provider.importCalculationToQuote,
                        child: const Text(
                          'IMPORTAR CÁLCULO',
                          style: TextStyle(color: AppTheme.success),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...data.items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: item.name,
                        decoration: const InputDecoration(labelText: 'Nome do Item'),
                        onChanged: (v) => provider.updateQuoteItem(item.id, name: v),
                      ),
                      TextFormField(
                        initialValue: item.description,
                        decoration: const InputDecoration(labelText: 'Descrição'),
                        onChanged: (v) => provider.updateQuoteItem(item.id, description: v),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: const InputDecoration(labelText: 'Qtd'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => provider.updateQuoteItem(
                                item.id,
                                quantity: int.tryParse(v) ?? 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(item.total, currency),
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => provider.removeQuoteItem(item.id),
                            icon: const Icon(AppIcons.close, color: AppTheme.danger, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: data.discountPercent.toString(),
                      decoration: const InputDecoration(labelText: 'Desconto (%)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => provider.updateQuoteData(
                        data.copyWith(discountPercent: double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: data.shippingCost.toString(),
                      decoration: const InputDecoration(labelText: 'Frete (R\$)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => provider.updateQuoteData(
                        data.copyWith(shippingCost: double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: data.observations,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observações do Orçamento'),
                onChanged: (v) => provider.updateQuoteData(data.copyWith(observations: v)),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Baixar Orçamento PDF',
                icon: AppIcons.pdf,
                onPressed: () => _downloadPdf(context),
              ),
              const SizedBox(height: 12),
              Selector<CalculatorProvider, bool>(
                selector: (_, p) => p.quoteData.isFinalized,
                builder: (context, finalized, _) {
                  if (finalized) {
                    return PrimaryButton(
                      label: 'Novo orçamento',
                      icon: AppIcons.add,
                      outlined: true,
                      onPressed: provider.startNewQuote,
                    );
                  }
                  return PrimaryButton(
                    label: 'Finalizar orçamento',
                    icon: AppIcons.checkCircle,
                    onPressed: () => runFinalizeQuoteFlow(context),
                  );
                },
              ),
            ],
          );

        if (bare) return body;
        return AppCard(
          title: 'Gerador de orçamento',
          icon: AppIcons.fileText,
          child: body,
        );
      },
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? hint,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: onChanged,
    );
  }
}
