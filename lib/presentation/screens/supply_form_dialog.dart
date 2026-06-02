import 'package:flutter/material.dart';

import '../../domain/models/supply_models.dart';
import '../widgets/color_swatch_picker.dart';

class SupplyFormDialog extends StatefulWidget {
  const SupplyFormDialog({super.key, this.existing, required this.newId});

  final SupplyItem? existing;
  final String newId;

  @override
  State<SupplyFormDialog> createState() => _SupplyFormDialogState();
}

class _SupplyFormDialogState extends State<SupplyFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _supplier;
  late final TextEditingController _price;
  late final TextEditingController _material;
  late final TextEditingController _density;
  late final TextEditingController _notes;
  late SupplyType _type;
  String? _selectedColorHex;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _brand = TextEditingController(text: e?.brand ?? '');
    _supplier = TextEditingController(text: e?.supplier ?? '');
    _price = TextEditingController(
      text: e != null ? e.pricePerUnit.toStringAsFixed(2) : '',
    );
    _selectedColorHex = e?.color;
    _material = TextEditingController(text: e?.material ?? 'PLA');
    _density = TextEditingController(text: (e?.density ?? 1.24).toString());
    _notes = TextEditingController(text: e?.notes ?? '');
    _type = e?.type ?? SupplyType.filament;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _supplier.dispose();
    _price.dispose();
    _material.dispose();
    _density.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Novo insumo' : 'Editar insumo'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SupplyType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: SupplyType.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _type = v ?? SupplyType.filament),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _brand,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supplier,
                decoration: const InputDecoration(labelText: 'Fornecedor'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$/kg) *',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _material,
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              if (_type == SupplyType.filament) ...[
                const SizedBox(height: 14),
                ColorSwatchPicker(
                  selectedHex: _selectedColorHex,
                  onChanged: (hex) => setState(() => _selectedColorHex = hex),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _density,
                decoration: const InputDecoration(
                  labelText: 'Densidade (g/cm³)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;

    Navigator.pop(
      context,
      SupplyItem(
        id: widget.existing?.id ?? widget.newId,
        name: _name.text.trim(),
        type: _type,
        brand: _brand.text.trim(),
        supplier: _supplier.text.trim(),
        pricePerUnit: price,
        unit: 'kg',
        color: _selectedColorHex,
        material: _material.text.trim().isEmpty ? null : _material.text.trim(),
        density: double.tryParse(_density.text.replaceAll(',', '.')) ?? 1.24,
        purchasedAt: DateTime.now(),
        notes: _notes.text.trim(),
      ),
    );
  }
}
