import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/calculator_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/calculator_models.dart';
import '../providers/calculator_provider.dart';
import 'common_widgets.dart';

class QuotePreviewSection extends StatelessWidget {
  const QuotePreviewSection({super.key, this.floating = false});

  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final data = provider.quoteData;
        final currency = provider.currency;
        final preview = _QuoteDocumentPreview(data: data, currency: currency);

        if (floating) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visualizador de orçamento',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Atualização em tempo real',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (data.isFinalized)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Text(
                            'FINALIZADO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
                Padding(padding: const EdgeInsets.all(16), child: preview),
              ],
            ),
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised,
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Text(
                  'Visualização em tempo real',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                ),
              ),
              Padding(padding: const EdgeInsets.all(24), child: preview),
            ],
          ),
        );
      },
    );
  }
}

class _QuoteDocumentPreview extends StatelessWidget {
  const _QuoteDocumentPreview({required this.data, required this.currency});

  final QuoteData data;
  final CurrencySpec currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.quotePaper,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent, AppTheme.quoteAccent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: DefaultTextStyle(
                style: const TextStyle(color: AppTheme.quoteInk),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data.companyLogoBytes != null)
                                Image.memory(
                                  Uint8List.fromList(data.companyLogoBytes!),
                                  height: 56,
                                  fit: BoxFit.contain,
                                )
                              else ...[
                                Text(
                                  data.companyName.isEmpty ? 'KDA3D' : data.companyName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    color: AppTheme.quoteInk,
                                  ),
                                ),
                                if (data.companyName.isEmpty)
                                  const Text(
                                    'Print Studio',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.quoteAccent,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                data.companySlogan.isEmpty
                                    ? 'Soluções em Manufatura Aditiva'
                                    : data.companySlogan,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.quoteMuted,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ORÇAMENTO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppTheme.quoteMuted.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              '#${data.quoteNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.date,
                              style: const TextStyle(fontSize: 11, color: AppTheme.quoteMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _quoteBlock(
                            'Destinatário',
                            data.clientName.isEmpty ? 'Nome do Cliente' : data.clientName,
                            data.contact.isEmpty ? 'Contato' : data.contact,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _quoteBlock(
                            'Emitido por',
                            data.companyName.isEmpty ? 'Sua Empresa' : data.companyName,
                            [
                              if (data.companyEmail.isNotEmpty) data.companyEmail,
                              if (data.companyPhone.isNotEmpty) data.companyPhone,
                            ].join('\n'),
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _itemsHeader(),
                    ...data.items.map(_itemRow),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            _totalLine('Subtotal', CurrencyFormatter.format(data.subtotal, currency)),
                            _totalLine('Frete', CurrencyFormatter.format(data.shippingCost, currency)),
                            _totalLine(
                              'Desconto (${data.discountPercent.toStringAsFixed(0)}%)',
                              '- ${CurrencyFormatter.format(data.discountAmount, currency)}',
                              valueColor: const Color(0xFF059669),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Color(0xFFE2E8F0), height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(data.total, currency),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (data.stockMovements.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _stockBox(data),
                    ],
                    if (data.observations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _observationsBox(data.observations),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Gerado com KDA3D Print Studio',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.quoteMuted.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'ITEM',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.quoteMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'QTD',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.quoteMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TOTAL',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.quoteMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(QuoteItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.quoteMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.quantity.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.format(item.total, currency),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteBlock(String label, String title, String subtitle, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.quoteMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 11, color: AppTheme.quoteMuted, height: 1.4),
          ),
      ],
    );
  }

  Widget _totalLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.quoteMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.quoteInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockBox(QuoteData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTOQUE UTILIZADO',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          ...data.stockMovements.map(
            (m) => Text(
              '• ${m.itemName}: -${m.quantityUsed} ${m.unit} (saldo ${m.quantityAfter} ${m.unit})',
              style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _observationsBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OBSERVAÇÕES',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.quoteMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.quoteMuted)),
        ],
      ),
    );
  }
}
