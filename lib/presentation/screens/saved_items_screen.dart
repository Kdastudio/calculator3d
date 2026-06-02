import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/quote_history_models.dart';
import '../providers/auth_provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/quote_history_provider.dart';
import '../providers/sync_provider.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final history = context.read<QuoteHistoryProvider>();
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();

    await history.refresh();
    if (!mounted) return;
    if (!auth.isAuthenticated || auth.user == null) return;
    await sync.loadAll(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final auth = context.watch<AuthProvider>();
    final history = context.watch<QuoteHistoryProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      children: [
        Material(
          color: AppTheme.card,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accent,
            tabs: const [
              Tab(text: 'CÁLCULOS'),
              Tab(text: 'ORÇAMENTOS'),
              Tab(text: 'HISTÓRICO'),
            ],
          ),
        ),
        if (sync.isLoading || history.isLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCalculationsList(sync, auth, dateFormat),
              _buildCloudQuotesList(sync, auth, dateFormat),
              _buildQuoteHistoryList(history, dateFormat),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationsList(SyncProvider sync, AuthProvider auth, DateFormat fmt) {
    if (!auth.isAuthenticated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Faça login para sincronizar cálculos na nuvem.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    if (sync.calculations.isEmpty) {
      return const Center(child: Text('Nenhum cálculo salvo na nuvem.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      itemCount: sync.calculations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = sync.calculations[index];
        final isActive = sync.activeCalculationId == item.id;

        return Card(
          child: ListTile(
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Atualizado: ${fmt.format(item.updatedAt.toLocal())}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  _badge('ATIVO'),
                IconButton(
                  icon: const Icon(AppIcons.delete, color: AppTheme.danger, size: 18),
                  onPressed: () async {
                    if (auth.user == null) return;
                    await sync.deleteCalculation(item.id, auth.user!.id);
                  },
                ),
              ],
            ),
            onTap: () async {
              await sync.loadCalculation(item.id, context.read<CalculatorProvider>());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cálculo carregado — aba Calculadora')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCloudQuotesList(SyncProvider sync, AuthProvider auth, DateFormat fmt) {
    if (!auth.isAuthenticated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Faça login para sincronizar orçamentos na nuvem.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    if (sync.quotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.cloud, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Nenhum orçamento na nuvem.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Use "Salvar orçamento" na barra de nuvem da Calculadora.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppLayout.pagePadding),
        itemCount: sync.quotes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final quote = sync.quotes[index];
          final isActive = sync.activeQuoteId == quote.id;
          final client = quote.clientName.isEmpty ? 'Sem cliente' : quote.clientName;
          final itemCount = quote.items.length;

          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(AppIcons.cloud, color: AppTheme.accent, size: 18),
              ),
              title: Text(
                '#${quote.quoteNumber} — $client',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$itemCount item(ns) · Atualizado: ${fmt.format(quote.updatedAt.toLocal())}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive) _badge('ATIVO'),
                  IconButton(
                    icon: const Icon(AppIcons.delete, color: AppTheme.danger, size: 18),
                    onPressed: () async {
                      if (auth.user == null) return;
                      await sync.deleteQuote(quote.id, auth.user!.id);
                    },
                  ),
                ],
              ),
              onTap: () async {
                await sync.loadQuote(quote.id, context.read<CalculatorProvider>());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Orçamento #$quote.quoteNumber carregado — aba Calculadora'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuoteHistoryList(
    QuoteHistoryProvider history,
    DateFormat fmt,
  ) {
    if (history.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.fileText, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Nenhum orçamento no histórico.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Orçamentos finalizados na Calculadora aparecem aqui automaticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppLayout.pagePadding),
        itemCount: history.entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = history.entries[index];
          return _HistoryQuoteCard(
            entry: entry,
            dateFormat: fmt,
            onDelete: () => history.deleteEntry(entry.id),
            onOpen: () => _openHistoryQuote(context, entry),
          );
        },
      ),
    );
  }

  Future<void> _openHistoryQuote(BuildContext context, QuoteHistoryEntry entry) async {
    final calculator = context.read<CalculatorProvider>();
    context.read<QuoteHistoryProvider>().loadIntoCalculator(calculator, entry);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento carregado na Calculadora')),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QuoteHistoryDetailSheet(entry: entry),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.accent)),
    );
  }
}

class _HistoryQuoteCard extends StatelessWidget {
  const _HistoryQuoteCard({
    required this.entry,
    required this.dateFormat,
    required this.onDelete,
    required this.onOpen,
  });

  final QuoteHistoryEntry entry;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final quote = entry.quote;
    final currency = CurrencyFormatter.currencyForCode(entry.currencyCode);
    final client = quote.clientName.isEmpty ? 'Sem cliente' : quote.clientName;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(AppIcons.checkCircle, color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${quote.quoteNumber} — $client',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${CurrencyFormatter.format(entry.total, currency)} · ${quote.items.length} item(ns)',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Finalizado: ${dateFormat.format(entry.savedAt.toLocal())}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    if (quote.stockMovements.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Estoque: ${quote.stockMovements.length} material(is) baixado(s)',
                          style: TextStyle(fontSize: 11, color: AppTheme.warning.withValues(alpha: 0.9)),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.delete, color: AppTheme.danger, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteHistoryDetailSheet extends StatelessWidget {
  const _QuoteHistoryDetailSheet({required this.entry});

  final QuoteHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final quote = entry.quote;
    final currency = CurrencyFormatter.currencyForCode(entry.currencyCode);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Orçamento #${quote.quoteNumber}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                quote.clientName.isEmpty ? 'Cliente não informado' : quote.clientName,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ...quote.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text(CurrencyFormatter.format(item.total, currency)),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppTheme.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    CurrencyFormatter.format(entry.total, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                  ),
                ],
              ),
              if (quote.stockMovements.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Estoque utilizado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...quote.stockMovements.map(
                  (m) => Text(
                    '• ${m.itemName}: -${m.quantityUsed} ${m.unit} (saldo ${m.quantityAfter} ${m.unit})',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
              if (quote.observations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Observações', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(quote.observations, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.calculator, size: 18),
                label: const Text('Fechar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
