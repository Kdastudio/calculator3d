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
  bool _userSessionReady = false;
  bool _sessionLoading = false;
  String? _loadedUserId;

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

  Future<void> _loadUserSession(AuthProvider auth) async {
    if (!auth.isAuthenticated || auth.user == null) return;
    final userId = auth.user!.id;

    if (_sessionLoading) return;
    if (_userSessionReady && _loadedUserId == userId) return;

    if (_loadedUserId != null && _loadedUserId != userId) {
      _resetUserProviders();
    }

    _sessionLoading = true;

    try {
      final sync = context.read<SyncProvider>();
      final supplies = context.read<SupplyProvider>();
      final stock = context.read<StockProvider>();
      final history = context.read<QuoteHistoryProvider>();
      final calculator = context.read<CalculatorProvider>();
      final energy = context.read<EnergyProvider>();

      await sync.loadAll(userId);
      if (!mounted) return;

      await Future.wait([
        supplies.loadForUser(userId),
        stock.loadForUser(userId),
        history.loadForUser(userId),
      ]);
      if (!mounted) return;

      calculator.resetSession();
      await sync.applyProfileToCalculator(calculator, userId);
      if (!mounted) return;

      energy.applyFromCostInputs(
        stateEnergy: calculator.costInputs.stateEnergy,
        customEnergyRate: calculator.costInputs.customEnergyRate,
        tariffFlag: calculator.costInputs.tariffFlag,
      );
      calculator.syncEnergyFromProvider(energy);
      calculator.updateStockContext(stock.items);

      if (mounted) {
        setState(() {
          _userSessionReady = true;
          _loadedUserId = userId;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userSessionReady = true;
          _loadedUserId = userId;
        });
      }
    } finally {
      _sessionLoading = false;
    }
  }

  void _resetUserProviders() {
    context.read<SyncProvider>().resetSession();
    context.read<StockProvider>().resetSession();
    context.read<SupplyProvider>().resetSession();
    context.read<QuoteHistoryProvider>().resetSession();
    context.read<CalculatorProvider>().resetSession();
    _userSessionReady = false;
    _loadedUserId = null;
    _sessionLoading = false;
  }

  void _onLoggedOut() {
    if (!mounted) return;
    setState(_resetUserProviders);
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
        if (!_coreReady && !auth.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
        }

        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          if (_userSessionReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onLoggedOut();
            });
          }
          return const LoginScreen();
        }

        if (!_userSessionReady || _loadedUserId != auth.user?.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadUserSession(auth);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const MainNavShell();
      },
    );
  }
}
