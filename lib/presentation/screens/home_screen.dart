import 'package:flutter/material.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/cloud_sync_bar.dart';
import '../widgets/cost_section.dart';
import '../widgets/energy_region_selector.dart';
import '../widgets/gcode_reader_section.dart';
import '../widgets/margin_presets_row.dart';
import '../widgets/multi_filament_section.dart';
import '../widgets/panel_widgets.dart';
import '../widgets/quote_preview_section.dart';
import '../widgets/quote_section.dart';
import '../widgets/quote_stock_section.dart';
import '../widgets/results_section.dart';
import '../widgets/tax_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      cacheExtent: 400,
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KDA3D Print Studio', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Custos de impressão',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppLayout.pagePadding),
          sliver: SliverToBoxAdapter(
            child: AppLayout.pageContainer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1280;
                  final isTablet = constraints.maxWidth >= 768;

                  return Column(
                    children: [
                      const CloudSyncBar(),
                      const SizedBox(height: 16),
                      if (isDesktop)
                        _DesktopThreeColumnLayout()
                      else if (isTablet)
                        _TabletLayout()
                      else
                        _MobileLayout(),
                      const SizedBox(height: 32),
                      Text(
                        '© 2026 KDA3D',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopThreeColumnLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Expanded(
            flex: 3,
            child: UnifiedPanel(
              title: 'Configuração',
              subtitle: 'Moeda, máquina, energia e materiais',
              children: [
                PanelSection(
                  title: 'Custos de impressão',
                  icon: AppIcons.calculator,
                  child: const CostSection(bare: true),
                ),
                PanelSection(
                  title: 'Tarifa regional',
                  icon: AppIcons.bolt,
                  child: const EnergyRegionSelector(bare: true),
                ),
                PanelSection(
                  title: 'Multi-filamento',
                  icon: AppIcons.palette,
                  showDivider: false,
                  child: const MultiFilamentSection(bare: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: UnifiedPanel(
              title: 'Processo & resultados',
              subtitle: 'G-code, demonstrativo e impostos',
              children: [
                PanelSection(
                  title: 'Leitor G-code',
                  icon: AppIcons.code,
                  child: const GCodeReaderSection(bare: true),
                ),
                PanelSection(
                  title: 'Resumo de resultados',
                  icon: AppIcons.trending,
                  child: const ResultsSection(bare: true),
                ),
                PanelSection(
                  title: 'Simulador de margem',
                  icon: AppIcons.tune,
                  child: const WhatIfSlider(bare: true),
                ),
                PanelSection(
                  title: 'Impostos e taxas',
                  icon: AppIcons.receipt,
                  child: const TaxSection(bare: true),
                ),
                PanelSection(
                  title: 'Materiais do estoque',
                  icon: AppIcons.warehouse,
                  showDivider: false,
                  child: const QuoteStockSection(bare: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: const _QuoteWorkspace(),
          ),
        ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UnifiedPanel(
          title: 'Configuração',
          subtitle: 'Moeda, máquina, energia e materiais',
          children: [
            PanelSection(
              title: 'Custos de impressão',
              icon: AppIcons.calculator,
              child: const CostSection(bare: true),
            ),
            PanelSection(
              title: 'Tarifa regional',
              icon: AppIcons.bolt,
              child: const EnergyRegionSelector(bare: true),
            ),
            PanelSection(
              title: 'Multi-filamento',
              icon: AppIcons.palette,
              showDivider: false,
              child: const MultiFilamentSection(bare: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        UnifiedPanel(
          title: 'Processo & resultados',
          children: [
            PanelSection(
              title: 'Leitor G-code',
              icon: AppIcons.code,
              child: const GCodeReaderSection(bare: true),
            ),
            PanelSection(
              title: 'Resumo',
              icon: AppIcons.trending,
              child: const ResultsSection(bare: true),
            ),
            PanelSection(
              title: 'Simulador de margem',
              icon: AppIcons.tune,
              child: const WhatIfSlider(bare: true),
            ),
            PanelSection(
              title: 'Impostos e taxas',
              icon: AppIcons.receipt,
              child: const TaxSection(bare: true),
            ),
            PanelSection(
              title: 'Estoque no orçamento',
              icon: AppIcons.warehouse,
              showDivider: false,
              child: const QuoteStockSection(bare: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _QuoteWorkspace(),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CostSection(),
        const SizedBox(height: 16),
        const EnergyRegionSelector(),
        const SizedBox(height: 16),
        const MultiFilamentSection(),
        const SizedBox(height: 16),
        const GCodeReaderSection(),
        const ResultsSection(),
        const SizedBox(height: 16),
        const WhatIfSlider(),
        const SizedBox(height: 16),
        const TaxSection(),
        const SizedBox(height: 16),
        const QuoteStockSection(),
        const SizedBox(height: 16),
        const _QuoteWorkspace(useCards: true),
      ],
    );
  }
}

class _QuoteWorkspace extends StatelessWidget {
  const _QuoteWorkspace({this.useCards = false});

  final bool useCards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (useCards)
          const QuoteSection()
        else
          UnifiedPanel(
            title: 'Gerador de orçamento',
            subtitle: 'Preencha os dados — a visualização atualiza abaixo',
            child: const QuoteSection(bare: true),
          ),
        const SizedBox(height: 16),
        QuotePreviewSection(floating: !useCards),
      ],
    );
  }
}
