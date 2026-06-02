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
  String? _userId;

  List<SupplyItem> get supplies => List.unmodifiable(_supplies);
  List<SupplyItem> get activeSupplies =>
      _supplies.where((s) => s.isActive).toList();
  List<SupplyPriceHistory> get history => List.unmodifiable(_history);
  bool get isLoading => _loading;
  String? get message => _message;
  bool get isInitialized => _initialized;
  String? get userId => _userId;

  SupplyItem? findById(String? id) {
    if (id == null) return null;
    for (final s in _supplies) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> loadForUser(String userId) async {
    if (_userId == userId && _initialized) return;

    _userId = userId;
    _loading = true;
    notifyListeners();

    try {
      final local = await _repository.loadLocal(userId);
      final localHistory = await _repository.loadLocalHistory(userId);
      final remote = await _repository.fetchRemote(userId);
      final remoteHistory = await _repository.fetchRemoteHistory(userId);

      if (remote.isNotEmpty) {
        _supplies = remote;
        await _repository.saveLocal(userId, _supplies);
      } else {
        _supplies = local;
        if (local.isNotEmpty) {
          for (final supply in local) {
            await _repository.upsertRemote(userId, supply);
          }
        }
      }

      if (remoteHistory.isNotEmpty) {
        _history = remoteHistory;
        await _repository.saveLocalHistory(userId, _history);
      } else {
        _history = localHistory;
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
    if (_userId != userId) {
      await loadForUser(userId);
      return;
    }

    try {
      final remote = await _repository.fetchRemote(userId);
      if (remote.isNotEmpty) {
        _supplies = remote;
        await _repository.saveLocal(userId, _supplies);
      }
      final remoteHistory = await _repository.fetchRemoteHistory(userId);
      if (remoteHistory.isNotEmpty) {
        _history = remoteHistory;
        await _repository.saveLocalHistory(userId, _history);
      }
    } catch (e) {
      _message = 'Sync parcial: $e';
    }
    notifyListeners();
  }

  void resetSession() {
    _supplies = [];
    _history = [];
    _loading = false;
    _message = null;
    _initialized = false;
    _userId = null;
    notifyListeners();
  }

  String _resolveUserId(String? userId) => userId ?? _userId ?? '';

  Future<void> addSupply(SupplyItem supply, {String? userId}) async {
    final uid = _resolveUserId(userId);
    if (uid.isEmpty) return;

    _supplies = [..._supplies, supply];
    await _recordPrice(supply, uid);
    await _repository.saveLocal(uid, _supplies);
    await _repository.upsertRemote(uid, supply);
    notifyListeners();
  }

  Future<void> updateSupply(SupplyItem supply, {String? userId}) async {
    final uid = _resolveUserId(userId);
    if (uid.isEmpty) return;

    final index = _supplies.indexWhere((s) => s.id == supply.id);
    if (index < 0) return;

    final previous = _supplies[index];
    _supplies = [..._supplies]..[index] = supply;

    if (previous.pricePerUnit != supply.pricePerUnit) {
      await _recordPrice(supply, uid);
    }

    await _repository.saveLocal(uid, _supplies);
    await _repository.upsertRemote(uid, supply);
    notifyListeners();
  }

  Future<void> deleteSupply(String id, {String? userId}) async {
    final uid = _resolveUserId(userId);
    if (uid.isEmpty) return;

    _supplies = _supplies.where((s) => s.id != id).toList();
    _history = _history.where((h) => h.supplyId != id).toList();
    await _repository.saveLocal(uid, _supplies);
    await _repository.saveLocalHistory(uid, _history);
    await _repository.deleteRemote(id);
    notifyListeners();
  }

  Future<void> _recordPrice(SupplyItem supply, String userId) async {
    final entry = SupplyPriceHistory(
      id: _repository.newId(),
      supplyId: supply.id,
      price: supply.pricePerUnit,
      supplier: supply.supplier,
      recordedAt: DateTime.now(),
    );
    _history = [..._history, entry];
    await _repository.saveLocalHistory(userId, _history);
    await _repository.insertPriceHistoryRemote(userId, entry);
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
