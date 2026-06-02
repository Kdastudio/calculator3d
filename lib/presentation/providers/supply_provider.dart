import 'package:flutter/foundation.dart';

import '../../data/repositories/supply_repository.dart';
import '../../domain/models/supply_models.dart';
import '../../domain/services/supply_service.dart';

class SupplyProvider extends ChangeNotifier {
  SupplyProvider({
    SupplyRepository? repository,
    SupplyService? service,
  })  : _repository = repository ?? SupplyRepository(),
        _service = service ?? SupplyService();

  final SupplyRepository _repository;
  final SupplyService _service;

  List<SupplyItem> _supplies = [];
  List<SupplyPriceHistory> _history = [];
  bool _loading = false;
  String? _message;
  bool _initialized = false;

  List<SupplyItem> get supplies => List.unmodifiable(_supplies);
  List<SupplyItem> get activeSupplies =>
      _supplies.where((s) => s.isActive).toList();
  List<SupplyPriceHistory> get history => List.unmodifiable(_history);
  bool get isLoading => _loading;
  String? get message => _message;
  bool get isInitialized => _initialized;

  SupplyItem? findById(String? id) {
    if (id == null) return null;
    for (final s in _supplies) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> initialize({String? userId}) async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();

    try {
      var local = await _repository.loadLocal();
      if (local.isEmpty) {
        local = _service.defaultSamples();
        await _repository.saveLocal(local);
      }
      _supplies = local;
      _history = await _repository.loadLocalHistory();

      if (userId != null) {
        await syncFromCloud(userId);
      }
      _initialized = true;
    } catch (e) {
      _message = 'Erro ao carregar insumos: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> syncFromCloud(String userId) async {
    try {
      final remote = await _repository.fetchRemote(userId);
      if (remote.isNotEmpty) {
        _supplies = remote;
        await _repository.saveLocal(_supplies);
      }
      final remoteHistory = await _repository.fetchRemoteHistory(userId);
      if (remoteHistory.isNotEmpty) {
        _history = remoteHistory;
        await _repository.saveLocalHistory(_history);
      }
    } catch (e) {
      _message = 'Sync parcial: $e';
    }
    notifyListeners();
  }

  Future<void> addSupply(SupplyItem supply, {String? userId}) async {
    _supplies = [..._supplies, supply];
    await _recordPrice(supply);
    await _repository.saveLocal(_supplies);
    if (userId != null) {
      await _repository.upsertRemote(userId, supply);
    }
    notifyListeners();
  }

  Future<void> updateSupply(SupplyItem supply, {String? userId}) async {
    final index = _supplies.indexWhere((s) => s.id == supply.id);
    if (index < 0) return;

    final previous = _supplies[index];
    _supplies = [..._supplies]..[index] = supply;

    if (previous.pricePerUnit != supply.pricePerUnit) {
      await _recordPrice(supply);
    }

    await _repository.saveLocal(_supplies);
    if (userId != null) {
      await _repository.upsertRemote(userId, supply);
    }
    notifyListeners();
  }

  Future<void> deleteSupply(String id, {String? userId}) async {
    _supplies = _supplies.where((s) => s.id != id).toList();
    _history = _history.where((h) => h.supplyId != id).toList();
    await _repository.saveLocal(_supplies);
    await _repository.saveLocalHistory(_history);
    if (userId != null) {
      await _repository.deleteRemote(id);
    }
    notifyListeners();
  }

  Future<void> _recordPrice(SupplyItem supply) async {
    final entry = SupplyPriceHistory(
      id: _repository.newId(),
      supplyId: supply.id,
      price: supply.pricePerUnit,
      supplier: supply.supplier,
      recordedAt: DateTime.now(),
    );
    _history = [..._history, entry];
    await _repository.saveLocalHistory(_history);
  }

  List<SupplyItem> rankCheapest({SupplyType? type}) =>
      _service.rankCheapest(_supplies, type: type);

  double? priceChangePercent(SupplyItem supply) =>
      _service.priceChangePercent(supply, _history);

  List<SupplyPriceHistory> historyForSupply(String supplyId) =>
      _history.where((h) => h.supplyId == supplyId).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  String newId() => _repository.newId();
}
