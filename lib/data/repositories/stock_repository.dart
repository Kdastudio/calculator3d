import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/stock_models.dart';

class StockRepository {
  StockRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _stockKey = 'kda3d_stock';
  static const _uuid = Uuid();

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  String newId() => _uuid.v4();

  Future<List<StockItem>> loadLocal() async {
    final prefs = await _storage;
    final raw = prefs.getString(_stockKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => StockItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveLocal(List<StockItem> items) async {
    final prefs = await _storage;
    final json = jsonEncode(items.map((s) => s.toJson()).toList());
    await prefs.setString(_stockKey, json);
  }
}
