import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_parser.dart';
import '../providers/calculator_provider.dart';
import '../providers/supply_provider.dart';
import 'common_widgets.dart';

class GCodeReaderSection extends StatelessWidget {
  const GCodeReaderSection({super.key, this.bare = false});

  final bool bare;

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['gcode'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final content = String.fromCharCodes(bytes);
    if (!context.mounted) return;

    final calculator = context.read<CalculatorProvider>();
    final supplyId = calculator.costInputs.selectedSupplyId;
    final supply = context.read<SupplyProvider>().findById(supplyId);
    final density = supply?.density ?? 1.24;

    await calculator.parseGCode(content, file.name, density: density);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        final metrics = provider.gCodeMetrics;
        final thumbnail = metrics?.thumbnailBytes;

        final body = Column(
          children: [
            InkWell(
              onTap: provider.parsingGcode ? null : () => _pickFile(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  color: AppTheme.surfaceRaised,
                ),
                child: Row(
                  children: [
                    if (provider.parsingGcode)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(AppIcons.upload, size: 20, color: AppTheme.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.parsingGcode
                            ? 'Processando G-code...'
                            : (provider.gCodeFileName ?? 'Escolher arquivo .gcode'),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                    if (provider.gCodeFileName == null && !provider.parsingGcode)
                      OutlinedButton(
                        onPressed: () => _pickFile(context),
                        child: const Text('Escolher arquivo'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Container(
                key: ValueKey(thumbnail != null),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                  color: AppTheme.surfaceRaised,
                ),
                child: Center(
                  child: thumbnail != null
                      ? Image.memory(
                          Uint8List.fromList(thumbnail),
                          height: 120,
                          fit: BoxFit.contain,
                        )
                      : const Text(
                          'Miniatura aparecerá aqui',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _metricRow('Tipo de Filamento', metrics?.filamentType ?? '---'),
            _metricRow(
              'Metros Estimados',
              metrics != null ? '${metrics.estimatedMeters}m' : '---',
              highlight: true,
            ),
            _metricRow(
              'Tempo de Impressão',
              metrics != null
                  ? TimeParser.formatDurationFromMinutes(metrics.printTimeMinutes)
                  : '---',
            ),
            _metricRow(
              'Peso (Gramas)',
              metrics != null ? '${metrics.weight}g' : '---',
            ),
            if (metrics != null)
              _metricRow('Densidade usada', '${metrics.density} g/cm³'),
          ],
        );

        if (bare) return body;
        return AppCard(
          title: 'Leitor G-code',
          icon: AppIcons.code,
          child: body,
        );
      },
    );
  }

  Widget _metricRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? AppTheme.accent : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
