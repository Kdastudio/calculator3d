import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/env.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/calculator_provider.dart';
import 'presentation/providers/energy_provider.dart';
import 'presentation/providers/quote_history_provider.dart';
import 'presentation/providers/stock_provider.dart';
import 'presentation/providers/supply_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  if (Env.hasSupabase) {
    await SupabaseConfig.initialize();
  }

  runApp(const Kda3dCalculatorApp());
}

class Kda3dCalculatorApp extends StatelessWidget {
  const Kda3dCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EnergyProvider()),
        ChangeNotifierProvider(create: (_) => SupplyProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => QuoteHistoryProvider()),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp(
        title: 'Calculadora 3D Print Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const AppShell(),
      ),
    );
  }
}
