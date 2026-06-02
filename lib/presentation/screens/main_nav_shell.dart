import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_session_bar.dart';
import 'inventory_screen.dart';
import 'compare_screen.dart';
import 'home_screen.dart';
import 'saved_items_screen.dart';
import 'settings_screen.dart';
import 'supplies_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _index = 0;

  static const _tabs = [
    _NavTab(AppIcons.calculator, 'Calculadora'),
    _NavTab(AppIcons.package, 'Insumos'),
    _NavTab(AppIcons.warehouse, 'Estoque'),
    _NavTab(AppIcons.compare, 'Comparar'),
    _NavTab(AppIcons.folder, 'Histórico'),
    _NavTab(AppIcons.settings, 'Configurações'),
  ];

  Widget _buildPage(int index) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => const SuppliesScreen(),
      2 => const InventoryScreen(),
      3 => const CompareScreen(),
      4 => const SavedItemsScreen(),
      5 => const SettingsScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              UserSessionBar(onLogout: _logout),
              Expanded(
                child: Row(
                  children: [
                    if (useRail) _buildRail(),
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: _buildPage(_index),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: _tabs
                      .map(
                        (t) => NavigationDestination(
                          icon: Icon(t.icon),
                          label: t.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  Widget _buildRail() {
    return Container(
      width: 152,
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(right: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 22, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KDA3D',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Print Studio',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final selected = _index == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: selected
                        ? AppTheme.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: () => setState(() => _index = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              size: 17,
                              color: selected
                                  ? AppTheme.accent
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab(this.icon, this.label);
  final IconData icon;
  final String label;
}
