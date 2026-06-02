import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/calculator_provider.dart';
import '../providers/quote_history_provider.dart';
import '../providers/stock_provider.dart';
import 'common_widgets.dart';

class FinalizeQuoteBar extends StatelessWidget {
  const FinalizeQuoteBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, calculator, _) {
        final finalized = calculator.quoteData.isFinalized;

        if (compact) {
          return Row(
            children: [
              if (finalized)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: calculator.startNewQuote,
                    icon: const Icon(AppIcons.add, size: 16),
                    label: const Text('Novo orçamento'),
                  ),
                )
              else
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => runFinalizeQuoteFlow(context),
                    icon: const Icon(AppIcons.checkCircle, size: 18),
                    label: const Text('Finalizar orçamento'),
                  ),
                ),
            ],
          );
        }

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finalized ? 'Orçamento finalizado' : 'Pronto para fechar?',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      finalized
                          ? 'Salvo no histórico. Gere o PDF ou inicie um novo orçamento.'
                          : 'Confirme os itens e materiais do estoque. Ao finalizar, o orçamento vai para o histórico.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (finalized)
                OutlinedButton.icon(
                  onPressed: calculator.startNewQuote,
                  icon: const Icon(AppIcons.add, size: 16),
                  label: const Text('Novo orçamento'),
                )
              else
                FilledButton.icon(
                  onPressed: () => runFinalizeQuoteFlow(context),
                  icon: const Icon(AppIcons.checkCircle, size: 18),
                  label: const Text('Finalizar orçamento'),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> runFinalizeQuoteFlow(BuildContext context) async {
  final calculator = context.read<CalculatorProvider>();
  final stock = context.read<StockProvider>();

  if (calculator.quoteData.isFinalized) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Este orçamento já foi finalizado.')),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Finalizar orçamento?'),
      content: Text(
        calculator.stockAllocations.isNotEmpty
            ? 'O orçamento será marcado como finalizado e os materiais do estoque serão descontados.'
            : 'O orçamento será marcado como finalizado. Nenhum material do estoque será descontado.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Finalizar'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final result = await calculator.finalizeQuote(stock);
  if (!context.mounted) return;

  if (!result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Erro ao finalizar'), backgroundColor: AppTheme.danger),
    );
    return;
  }

  await context.read<QuoteHistoryProvider>().addFromCalculator(calculator);

  if (!context.mounted) return;

  final message = result.movements.isEmpty
      ? 'Orçamento finalizado e salvo no histórico.'
      : 'Orçamento finalizado. Estoque atualizado e salvo no histórico.';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppTheme.success),
  );
}
