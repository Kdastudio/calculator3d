import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/user_storage_keys.dart';
import '../../domain/models/supply_models.dart';

class SupplyRepository {
  SupplyRepository({SupabaseClient? client, SharedPreferences? prefs})
    : _client =
          client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null),
      _prefs = prefs;

  final SupabaseClient? _client;
  SharedPreferences? _prefs;
  static const _uuid = Uuid();

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<SupplyItem>> loadLocal(String userId) async {
    final prefs = await _storage;
    final raw = prefs.getString(UserStorageKeys.supplies(userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SupplyItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SupplyPriceHistory>> loadLocalHistory(String userId) async {
    final prefs = await _storage;
    final raw = prefs.getString(UserStorageKeys.supplyHistory(userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SupplyPriceHistory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveLocal(String userId, List<SupplyItem> supplies) async {
    final prefs = await _storage;
    final json = jsonEncode(supplies.map((s) => s.toJson()).toList());
    await prefs.setString(UserStorageKeys.supplies(userId), json);
  }

  Future<void> saveLocalHistory(
    String userId,
    List<SupplyPriceHistory> history,
  ) async {
    final prefs = await _storage;
    final json = jsonEncode(history.map((h) => h.toJson()).toList());
    await prefs.setString(UserStorageKeys.supplyHistory(userId), json);
  }

  Future<List<SupplyItem>> fetchRemote(String userId) async {
    if (_client == null) return [];
    final rows = await _client
        .from('supplies')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((row) => _supplyFromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<SupplyPriceHistory>> fetchRemoteHistory(String userId) async {
    if (_client == null) return [];
    final rows = await _client
        .from('supply_price_history')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);
    return (rows as List)
        .map(
          (row) => SupplyPriceHistory.fromJson({
            'id': row['id'],
            'supplyId': row['supply_id'],
            'price': row['price'],
            'supplier': row['supplier'],
            'recordedAt': row['recorded_at'],
          }),
        )
        .toList();
  }

  Future<void> upsertRemote(String userId, SupplyItem supply) async {
    if (_client == null) return;
    await _client.from('supplies').upsert({
      'id': supply.id,
      'user_id': userId,
      'name': supply.name,
      'type': supply.type.name,
      'brand': supply.brand,
      'supplier': supply.supplier,
      'price_per_unit': supply.pricePerUnit,
      'unit': supply.unit,
      'color': supply.color,
      'material': supply.material,
      'density': supply.density,
      'purchased_at': supply.purchasedAt?.toIso8601String(),
      'is_active': supply.isActive,
      'notes': supply.notes,
    });
  }

  Future<void> insertPriceHistoryRemote(
    String userId,
    SupplyPriceHistory entry,
  ) async {
    if (_client == null) return;
    await _client.from('supply_price_history').insert({
      'id': entry.id,
      'user_id': userId,
      'supply_id': entry.supplyId,
      'price': entry.price,
      'supplier': entry.supplier,
      'recorded_at': entry.recordedAt.toIso8601String(),
    });
  }

  Future<void> deleteRemote(String supplyId) async {
    if (_client == null) return;
    await _client.from('supplies').delete().eq('id', supplyId);
  }

  SupplyItem _supplyFromRow(Map<String, dynamic> row) => SupplyItem(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    type: SupplyType.values.firstWhere(
      (t) => t.name == (row['type'] as String? ?? 'filament'),
      orElse: () => SupplyType.filament,
    ),
    brand: row['brand'] as String? ?? '',
    supplier: row['supplier'] as String? ?? '',
    pricePerUnit: (row['price_per_unit'] as num?)?.toDouble() ?? 0,
    unit: row['unit'] as String? ?? 'kg',
    color: row['color'] as String?,
    material: row['material'] as String?,
    density: (row['density'] as num?)?.toDouble() ?? 1.24,
    purchasedAt: row['purchased_at'] != null
        ? DateTime.tryParse(row['purchased_at'] as String)
        : null,
    isActive: row['is_active'] as bool? ?? true,
    notes: row['notes'] as String? ?? '',
  );

  String newId() => _uuid.v4();
}
