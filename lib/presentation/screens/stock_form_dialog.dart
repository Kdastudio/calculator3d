import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/stock_models.dart';
import '../../domain/models/supply_models.dart';
import '../providers/supply_provider.dart';

class StockFormDialog extends StatefulWidget {
  const StockFormDialog({super.key, this.existing, required this.newId});

  final StockItem? existing;
  final String newId;

  @override
  State<StockFormDialog> createState() => _StockFormDialogState();
}

class _StockFormDialogState extends State<StockFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late String _unit;
  String? _supplyId;

  static const _units = ['g', 'kg', 'un', 'ml', 'm'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _quantityController = TextEditingController(
      text: e != null ? e.quantityOnHand.toString() : '',
    );
    _costController = TextEditingController(
      text: e != null ? e.unitCost.toString() : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _unit = e?.unit ?? 'g';
    _supplyId = e?.supplyId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applySupply(SupplyItem? supply) {
    if (supply == null) return;
    setState(() {
      _supplyId = supply.id;
      _costController.text = switch (_unit) {
        'g' => (supply.pricePerKg / 1000).toStringAsFixed(4),
        'kg' => supply.pricePerKg.toStringAsFixed(2),
        _ => supply.pricePerUnit.toStringAsFixed(2),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final supplies = context.watch<SupplyProvider>().activeSupplies;

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Novo material' : 'Editar material',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do material',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantidade em estoque',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v ?? 'g'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: 'Custo por $_unit (R\$)',
                  helperText: 'Usado no cálculo quando consumir do estoque',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _supplyId,
                decoration: const InputDecoration(
                  labelText: 'Vincular insumo (opcional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Nenhum')),
                  ...supplies.map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        s.displayLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (id) {
                  setState(() => _supplyId = id);
                  _applySupply(supplies.where((s) => s.id == id).firstOrNull);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
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
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final item = StockItem(
      id: widget.existing?.id ?? widget.newId,
      name: name,
      unit: _unit,
      quantityOnHand:
          double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0,
      unitCost: double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0,
      supplyId: _supplyId,
      notes: _notesController.text.trim(),
    );
    Navigator.pop(context, item);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
