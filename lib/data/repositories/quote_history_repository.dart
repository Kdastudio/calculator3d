import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/quote_history_models.dart';

class QuoteHistoryRepository {
  QuoteHistoryRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _historyKey = 'kda3d_quote_history';
  static const _uuid = Uuid();

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  String newId() => _uuid.v4();

  Future<List<QuoteHistoryEntry>> loadAll() async {
    final prefs = await _storage;
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => QuoteHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> saveAll(List<QuoteHistoryEntry> entries) async {
    final prefs = await _storage;
    final sorted = [...entries]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final json = jsonEncode(sorted.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, json);
  }

  Future<void> add(QuoteHistoryEntry entry) async {
    final current = await loadAll();
    await saveAll([entry, ...current]);
  }

  Future<void> delete(String id) async {
    final current = await loadAll();
    await saveAll(current.where((e) => e.id != id).toList());
  }
}
