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
import 'login_screen.dart';
import 'main_nav_shell.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  VoidCallback? _stockSyncListener;
  StockProvider? _stockProvider;
  bool _coreReady = false;
  String? _activeUserId;
  bool _sessionStarted = false;

  static const _sessionLoadTimeout = Duration(seconds: 15);

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
    if (!mounted || _coreReady) return;
    _coreReady = true;

    final energy = context.read<EnergyProvider>();
    final stock = context.read<StockProvider>();
    final calculator = context.read<CalculatorProvider>();

    unawaited(_loadCoreData(energy, stock, calculator));
  }

  void _scheduleUserSession(AuthProvider auth) {
    final userId = auth.user?.id;
    if (userId == null) return;

    if (_activeUserId != null && _activeUserId != userId) {
      _resetUserProviders();
      _sessionStarted = false;
    }

    _activeUserId = userId;

    if (_sessionStarted) return;
    _sessionStarted = true;
    unawaited(_loadUserSession(userId));
  }

  Future<void> _loadUserSession(String userId) async {
    try {
      final sync = context.read<SyncProvider>();
      final supplies = context.read<SupplyProvider>();
      final stock = context.read<StockProvider>();
      final history = context.read<QuoteHistoryProvider>();
      final calculator = context.read<CalculatorProvider>();
      final energy = context.read<EnergyProvider>();

      await sync.loadAll(userId).timeout(_sessionLoadTimeout);
      if (!mounted || _activeUserId != userId) return;

      await Future.wait([
        supplies.loadForUser(userId),
        stock.loadForUser(userId),
        history.loadForUser(userId),
      ]).timeout(_sessionLoadTimeout);
      if (!mounted || _activeUserId != userId) return;

      calculator.resetSession();
      await sync
          .applyProfileToCalculator(calculator, userId)
          .timeout(_sessionLoadTimeout);
      if (!mounted || _activeUserId != userId) return;

      energy.applyFromCostInputs(
        stateEnergy: calculator.costInputs.stateEnergy,
        customEnergyRate: calculator.costInputs.customEnergyRate,
        tariffFlag: calculator.costInputs.tariffFlag,
      );
      calculator.syncEnergyFromProvider(energy);
      calculator.updateStockContext(stock.items);
    } catch (e, stack) {
      debugPrint('Falha ao carregar sessão do usuário: $e\n$stack');
    }
  }

  void _resetUserProviders() {
    context.read<SyncProvider>().resetSession();
    context.read<StockProvider>().resetSession();
    context.read<SupplyProvider>().resetSession();
    context.read<QuoteHistoryProvider>().resetSession();
    context.read<CalculatorProvider>().resetSession();
  }

  void _onLoggedOut() {
    _activeUserId = null;
    _sessionStarted = false;
    _resetUserProviders();
  }

  Future<void> _loadCoreData(
    EnergyProvider energy,
    StockProvider stock,
    CalculatorProvider calculator,
  ) async {
    await energy.initialize();

    if (!mounted) return;

    _stockProvider = stock;
    _stockSyncListener = () {
      if (mounted) calculator.updateStockContext(stock.items);
    };
    stock.addListener(_stockSyncListener!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!_coreReady && !auth.isInitializing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
        }

        if (auth.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          if (_activeUserId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(_onLoggedOut);
              }
            });
          }
          return const LoginScreen();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && auth.isAuthenticated) {
            _scheduleUserSession(auth);
          }
        });

        return const MainNavShell();
      },
    );
  }
}
