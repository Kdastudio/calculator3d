import '../models/calculator_models.dart';
import '../models/supply_models.dart';
import 'calculator_service.dart';
import 'energy_service.dart';

class SupplyService {
  SupplyService({
    CalculatorService? calculatorService,
    EnergyService? energyService,
  })  : _calculator = calculatorService ?? CalculatorService(),
        _energy = energyService ?? EnergyService();

  final CalculatorService _calculator;
  final EnergyService _energy;

  List<SupplyItem> defaultSamples() => [
        SupplyItem(
          id: 'sample-pla-voolt',
          name: 'PLA Preto',
          brand: 'Voolt3D',
          supplier: 'Mercado Livre',
          pricePerUnit: 89.90,
          material: 'PLA',
          color: '#1a1a1a',
          density: 1.24,
          purchasedAt: DateTime.now(),
        ),
        SupplyItem(
          id: 'sample-petg-esun',
          name: 'PETG Transparente',
          brand: 'eSun',
          supplier: 'Filamentos 3D BR',
          pricePerUnit: 119.00,
          material: 'PETG',
          color: '#ffffff',
          density: 1.27,
          purchasedAt: DateTime.now(),
        ),
        SupplyItem(
          id: 'sample-pla-3dferramentas',
          name: 'PLA Branco',
          brand: '3DF',
          supplier: '3D Ferramentas',
          pricePerUnit: 75.00,
          material: 'PLA',
          color: '#f5f5f5',
          density: 1.24,
          purchasedAt: DateTime.now(),
        ),
      ];

  List<SupplyComparisonResult> compareSupplies({
    required List<SupplyItem> supplies,
    required CostInputs baseInputs,
    required TaxInputs taxInputs,
  }) {
    return supplies.map((supply) {
      final inputs = baseInputs.copyWith(
        selectedSupplyId: supply.id,
        filamentPrice: supply.pricePerKg,
        clearSupplyId: false,
      );
      final result = _calculator.calculateTotal(inputs, taxInputs, _energy);
      return SupplyComparisonResult(
        supply: supply,
        materialCost: result.details.filament,
        totalCost: result.totalCost,
        finalPrice: result.finalPrice,
        profit: result.finalPrice - result.totalCost,
      );
    }).toList()
      ..sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
  }

  List<SupplyItem> rankCheapest(List<SupplyItem> items, {SupplyType? type}) {
    final filtered = type == null
        ? items.where((s) => s.isActive).toList()
        : items.where((s) => s.isActive && s.type == type).toList();
    filtered.sort((a, b) => a.pricePerKg.compareTo(b.pricePerKg));
    return filtered;
  }

  double? priceChangePercent(SupplyItem supply, List<SupplyPriceHistory> history) {
    final entries = history.where((h) => h.supplyId == supply.id).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (entries.length < 2) return null;
    final first = entries.first.price;
    final last = entries.last.price;
    if (first == 0) return null;
    return ((last - first) / first) * 100;
  }
}
