import 'package:flutter/foundation.dart';

import '../../data/repositories/stock_repository.dart';
import '../../domain/models/stock_models.dart';
import '../../domain/models/supply_models.dart';
import '../../domain/services/stock_service.dart';

class StockProvider extends ChangeNotifier {
  StockProvider({
    StockRepository? repository,
    StockService? service,
  })  : _repository = repository ?? StockRepository(),
        _service = service ?? StockService();

  final StockRepository _repository;
  final StockService _service;

  List<StockItem> _items = [];
  bool _loading = false;
  bool _initialized = false;
  String? _message;

  List<StockItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isInitialized => _initialized;
  String? get message => _message;

  StockItem? findById(String? id) {
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();

    try {
      var local = await _repository.loadLocal();
      if (local.isEmpty) {
        local = _service.defaultSamples();
        await _repository.saveLocal(local);
      }
      _items = local;
      _initialized = true;
    } catch (e) {
      _message = 'Erro ao carregar estoque: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String newId() => _repository.newId();

  Future<void> addItem(StockItem item) async {
    _items = [..._items, item];
    await _repository.saveLocal(_items);
    notifyListeners();
  }

  Future<void> updateItem(StockItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index < 0) return;
    _items = [..._items]..[index] = item;
    await _repository.saveLocal(_items);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items = _items.where((i) => i.id != id).toList();
    await _repository.saveLocal(_items);
    notifyListeners();
  }

  Future<void> adjustQuantity(String id, double delta) async {
    final item = findById(id);
    if (item == null) return;
    final next = (item.quantityOnHand + delta).clamp(0.0, double.infinity);
    await updateItem(item.copyWith(quantityOnHand: next));
  }

  Future<List<QuoteStockMovement>> applyMovements(
    List<QuoteStockMovement> movements,
  ) async {
    final applied = <QuoteStockMovement>[];
    for (final movement in movements) {
      final item = findById(movement.stockItemId);
      if (item == null) continue;
      final updated = item.copyWith(quantityOnHand: movement.quantityAfter);
      await updateItem(updated);
      applied.add(movement);
    }
    return applied;
  }

  StockItem withSupplyPricing(StockItem item, SupplyItem? supply) {
    return _service.resolveUnitCostFromSupply(item, supply) ?? item;
  }

  double allocationCost(List<QuoteStockAllocation> allocations) =>
      _service.allocationCost(allocations, _items);

  String? validateAllocations(List<QuoteStockAllocation> allocations) =>
      _service.validateAllocations(allocations, _items);

  List<QuoteStockMovement> buildMovements(List<QuoteStockAllocation> allocations) =>
      _service.buildMovements(allocations, _items);

  void clearMessage() {
    _message = null;
    notifyListeners();
  }
}
