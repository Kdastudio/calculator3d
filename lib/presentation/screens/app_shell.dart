import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/energy_provider.dart';
import '../providers/quote_history_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/supply_provider.dart';
import '../providers/sync_provider.dart';
import 'main_nav_shell.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  VoidCallback? _stockSyncListener;
  StockProvider? _stockProvider;

  @override
  void dispose() {
    if (_stockSyncListener != null && _stockProvider != null) {
      _stockProvider!.removeListener(_stockSyncListener!);
    }
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final energy = context.read<EnergyProvider>();
    final supplies = context.read<SupplyProvider>();
    final stock = context.read<StockProvider>();
    final history = context.read<QuoteHistoryProvider>();
    final calculator = context.read<CalculatorProvider>();

    unawaited(_loadCoreData(energy, supplies, stock, history, calculator, auth));
  }

  Future<void> _loadCoreData(
    EnergyProvider energy,
    SupplyProvider supplies,
    StockProvider stock,
    QuoteHistoryProvider history,
    CalculatorProvider calculator,
    AuthProvider auth,
  ) async {
    await Future.wait([
      energy.initialize(),
      supplies.initialize(userId: auth.user?.id),
      stock.initialize(),
      history.initialize(),
    ]);

    if (!mounted) return;

    energy.applyFromCostInputs(
      stateEnergy: calculator.costInputs.stateEnergy,
      customEnergyRate: calculator.costInputs.customEnergyRate,
      tariffFlag: calculator.costInputs.tariffFlag,
    );
    calculator.syncEnergyFromProvider(energy);

    _stockProvider = stock;
    _stockSyncListener = () {
      if (mounted) calculator.updateStockContext(stock.items);
    };
    stock.addListener(_stockSyncListener!);
    calculator.updateStockContext(stock.items);

    if (!auth.isAuthenticated || auth.user == null) return;

    final sync = context.read<SyncProvider>();
    final userId = auth.user!.id;

    await sync.loadAll(userId);
    if (!mounted) return;

    await Future.wait([
      sync.applyProfileToCalculator(calculator, userId),
      supplies.syncFromCloud(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const MainNavShell();
      },
    );
  }
}
