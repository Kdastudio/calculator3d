import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/color_utils.dart';

/// Paleta visual para cor de filamento — sem digitar HEX.
class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    super.key,
    this.selectedHex,
    required this.onChanged,
  });

  final String? selectedHex;
  final ValueChanged<String?> onChanged;

  static const _presets = <({String label, String hex})>[
    (label: 'Preto', hex: '#1A1A1A'),
    (label: 'Branco', hex: '#F5F5F5'),
    (label: 'Cinza', hex: '#9E9E9E'),
    (label: 'Prata', hex: '#B0BEC5'),
    (label: 'Vermelho', hex: '#E53935'),
    (label: 'Azul', hex: '#1E88E5'),
    (label: 'Verde', hex: '#43A047'),
    (label: 'Amarelo', hex: '#FDD835'),
    (label: 'Laranja', hex: '#FB8C00'),
    (label: 'Rosa', hex: '#EC407A'),
    (label: 'Roxo', hex: '#8E24AA'),
    (label: 'Marrom', hex: '#6D4C41'),
    (label: 'Bege', hex: '#D7CCC8'),
    (label: 'Dourado', hex: '#FFC107'),
    (label: 'Ciano', hex: '#00ACC1'),
    (label: 'Turquesa', hex: '#26A69A'),
    (label: 'Vinho', hex: '#880E4F'),
    (label: 'Azul petróleo', hex: '#00695C'),
    (label: 'Oliva', hex: '#827717'),
    (label: 'Creme', hex: '#FFF8E1'),
    (label: 'Neon verde', hex: '#76FF03'),
    (label: 'Neon rosa', hex: '#FF4081'),
    (label: 'Madeira', hex: '#A1887F'),
    (label: 'Transparente', hex: '#ECEFF1'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = ColorUtils.fromHex(selectedHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Cor', style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            if (selectedHex != null)
              TextButton(
                onPressed: () => onChanged(null),
                child: const Text('Limpar'),
              ),
            TextButton.icon(
              onPressed: () => _openCustomPicker(context),
              icon: const Icon(Icons.palette_outlined, size: 16),
              label: const Text('Personalizar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              _Swatch(
                label: preset.label,
                color: ColorUtils.fromHex(preset.hex)!,
                selected: selectedHex?.toUpperCase() == preset.hex.toUpperCase(),
                onTap: () => onChanged(preset.hex),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selectedHex!.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openCustomPicker(BuildContext context) async {
    final initial = ColorUtils.fromHex(selectedHex) ?? const Color(0xFF1E88E5);
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _CustomColorDialog(initial: initial),
    );
    if (picked != null) {
      onChanged(ColorUtils.toHex(picked));
    }
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.border,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initial});

  final Color initial;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();

    return AlertDialog(
      title: const Text('Cor personalizada'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
            ),
            const SizedBox(height: 16),
            _slider('Matiz', _hsv.hue, 360, (v) {
              setState(() => _hsv = _hsv.withHue(v));
            }),
            _slider('Saturação', _hsv.saturation, 1, (v) {
              setState(() => _hsv = _hsv.withSaturation(v));
            }),
            _slider('Brilho', _hsv.value, 1, (v) {
              setState(() => _hsv = _hsv.withValue(v));
            }),
            const SizedBox(height: 8),
            Text(
              ColorUtils.toHex(color),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text('Usar cor'),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0, max),
              min: 0,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
