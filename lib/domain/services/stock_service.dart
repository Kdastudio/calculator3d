import '../../domain/models/stock_models.dart';
import '../../domain/models/supply_models.dart';

class StockService {
  List<StockItem> defaultSamples() => [
        StockItem(
          id: 'sample-pla-branco',
          name: 'PLA Branco',
          unit: 'g',
          quantityOnHand: 1000,
          unitCost: 0.12,
          notes: 'Exemplo — 120/kg',
        ),
        StockItem(
          id: 'sample-petg-preto',
          name: 'PETG Preto',
          unit: 'g',
          quantityOnHand: 750,
          unitCost: 0.14,
          notes: 'Exemplo — 140/kg',
        ),
      ];

  double allocationCost(
    List<QuoteStockAllocation> allocations,
    List<StockItem> stockItems,
  ) {
    var total = 0.0;
    for (final allocation in allocations) {
      if (allocation.quantityToUse <= 0) continue;
      final item = _find(stockItems, allocation.stockItemId);
      if (item == null) continue;
      total += item.costForQuantity(allocation.quantityToUse);
    }
    return total;
  }

  String? validateAllocations(
    List<QuoteStockAllocation> allocations,
    List<StockItem> stockItems,
  ) {
    if (allocations.isEmpty) {
      return 'Adicione materiais do estoque ao orçamento antes de finalizar.';
    }

    for (final allocation in allocations) {
      if (allocation.quantityToUse <= 0) {
        return 'Informe a quantidade a usar para cada material do estoque.';
      }
      final item = _find(stockItems, allocation.stockItemId);
      if (item == null) {
        return 'Material de estoque não encontrado. Atualize a lista.';
      }
      if (allocation.quantityToUse > item.quantityOnHand) {
        return '${item.name}: uso de ${allocation.quantityToUse} ${item.unit} '
            'excede estoque (${item.quantityOnHand} ${item.unit}).';
      }
    }
    return null;
  }

  List<QuoteStockMovement> buildMovements(
    List<QuoteStockAllocation> allocations,
    List<StockItem> stockItems,
  ) {
    final movements = <QuoteStockMovement>[];
    for (final allocation in allocations) {
      final item = _find(stockItems, allocation.stockItemId);
      if (item == null) continue;
      movements.add(
        QuoteStockMovement(
          stockItemId: item.id,
          itemName: item.name,
          unit: item.unit,
          quantityUsed: allocation.quantityToUse,
          quantityBefore: item.quantityOnHand,
          quantityAfter: item.quantityOnHand - allocation.quantityToUse,
          unitCost: item.unitCost,
        ),
      );
    }
    return movements;
  }

  StockItem? resolveUnitCostFromSupply(StockItem item, SupplyItem? supply) {
    if (supply == null) return null;
    final cost = switch (item.unit) {
      'g' => supply.pricePerKg / 1000,
      'kg' => supply.pricePerKg,
      _ => supply.pricePerUnit,
    };
    return item.copyWith(unitCost: cost, supplyId: supply.id);
  }

  StockItem? _find(List<StockItem> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
