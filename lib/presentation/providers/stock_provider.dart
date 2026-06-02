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
  String? _userId;

  List<StockItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isInitialized => _initialized;
  String? get message => _message;
  String? get userId => _userId;

  StockItem? findById(String? id) {
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> loadForUser(String userId) async {
    if (_userId == userId && _initialized) return;

    _userId = userId;
    _loading = true;
    notifyListeners();

    try {
      var local = await _repository.loadLocal(userId);
      final remote = await _repository.fetchRemote(userId);

      if (remote.isNotEmpty) {
        _items = remote;
        await _repository.saveLocal(userId, _items);
      } else {
        _items = local;
        if (local.isNotEmpty) {
          for (final item in local) {
            await _repository.upsertRemote(userId, item);
          }
        }
      }

      _initialized = true;
    } catch (e) {
      _message = 'Erro ao carregar estoque: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> syncFromCloud(String userId) async {
    if (_userId != userId) {
      await loadForUser(userId);
      return;
    }

    try {
      final remote = await _repository.fetchRemote(userId);
      if (remote.isNotEmpty) {
        _items = remote;
        await _repository.saveLocal(userId, _items);
        notifyListeners();
      }
    } catch (e) {
      _message = 'Sync parcial do estoque: $e';
      notifyListeners();
    }
  }

  void resetSession() {
    _items = [];
    _loading = false;
    _initialized = false;
    _message = null;
    _userId = null;
    notifyListeners();
  }

  String newId() => _repository.newId();

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.saveLocal(userId, _items);
  }

  Future<void> _syncItem(StockItem item) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.upsertRemote(userId, item);
  }

  Future<void> addItem(StockItem item) async {
    _items = [..._items, item];
    await _persist();
    await _syncItem(item);
    notifyListeners();
  }

  Future<void> updateItem(StockItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index < 0) return;
    _items = [..._items]..[index] = item;
    await _persist();
    await _syncItem(item);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items = _items.where((i) => i.id != id).toList();
    await _persist();
    await _repository.deleteRemote(id);
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
