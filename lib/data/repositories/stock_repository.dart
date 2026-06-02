import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/user_storage_keys.dart';
import '../../domain/models/stock_models.dart';

class StockRepository {
  StockRepository({SupabaseClient? client, SharedPreferences? prefs})
      : _client =
            client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null),
        _prefs = prefs;

  final SupabaseClient? _client;
  SharedPreferences? _prefs;
  static const _uuid = Uuid();

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  String newId() => _uuid.v4();

  Future<List<StockItem>> loadLocal(String userId) async {
    final prefs = await _storage;
    final raw = prefs.getString(UserStorageKeys.stock(userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StockItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveLocal(String userId, List<StockItem> items) async {
    final prefs = await _storage;
    final json = jsonEncode(items.map((s) => s.toJson()).toList());
    await prefs.setString(UserStorageKeys.stock(userId), json);
  }

  Future<List<StockItem>> fetchRemote(String userId) async {
    if (_client == null) return [];
    final rows = await _client
        .from('stock_items')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((row) => _stockFromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> upsertRemote(String userId, StockItem item) async {
    if (_client == null) return;
    await _client.from('stock_items').upsert({
      'id': item.id,
      'user_id': userId,
      'name': item.name,
      'unit': item.unit,
      'quantity_on_hand': item.quantityOnHand,
      'unit_cost': item.unitCost,
      'supply_id': item.supplyId,
      'notes': item.notes,
    });
  }

  Future<void> deleteRemote(String itemId) async {
    if (_client == null) return;
    await _client.from('stock_items').delete().eq('id', itemId);
  }

  StockItem _stockFromRow(Map<String, dynamic> row) => StockItem(
        id: row['id'] as String,
        name: row['name'] as String? ?? '',
        unit: row['unit'] as String? ?? 'g',
        quantityOnHand: (row['quantity_on_hand'] as num?)?.toDouble() ?? 0,
        unitCost: (row['unit_cost'] as num?)?.toDouble() ?? 0,
        supplyId: row['supply_id'] as String?,
        notes: row['notes'] as String? ?? '',
      );
}
