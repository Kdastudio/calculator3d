import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kda3d_calculator/core/config/env.dart';
import 'package:kda3d_calculator/presentation/providers/auth_provider.dart';
import 'package:kda3d_calculator/presentation/providers/calculator_provider.dart';
import 'package:kda3d_calculator/presentation/providers/energy_provider.dart';
import 'package:kda3d_calculator/presentation/providers/quote_history_provider.dart';
import 'package:kda3d_calculator/presentation/providers/stock_provider.dart';
import 'package:kda3d_calculator/presentation/providers/supply_provider.dart';
import 'package:kda3d_calculator/presentation/providers/sync_provider.dart';
import 'package:kda3d_calculator/presentation/screens/app_shell.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  testWidgets('App exige login antes da calculadora', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EnergyProvider()),
          ChangeNotifierProvider(create: (_) => SupplyProvider()),
          ChangeNotifierProvider(create: (_) => StockProvider()),
          ChangeNotifierProvider(create: (_) => QuoteHistoryProvider()),
          ChangeNotifierProvider(create: (_) => CalculatorProvider()),
          ChangeNotifierProvider(create: (_) => SyncProvider()),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sincronize cálculos e orçamentos entre dispositivos'),
      findsOneWidget,
    );
    expect(find.text('Continuar sem conta'), findsNothing);
    expect(find.text('KDA3D Print Studio'), findsNothing);
  });
}
