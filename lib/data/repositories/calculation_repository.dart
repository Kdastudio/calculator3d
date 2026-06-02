import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/calculator_constants.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/models/calculator_serializers.dart';
import '../../domain/models/calculator_models.dart';
import '../../domain/models/cloud_models.dart';

class CalculationRepository {
  CalculationRepository({SupabaseClient? client})
    : _client =
          client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null);

  final SupabaseClient? _client;

  Future<List<SavedCalculation>> list(String userId) async {
    if (_client == null) return [];

    final rows = await _client
        .from('calculations')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (rows as List)
        .map((row) => SavedCalculation.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String> save({
    required String userId,
    required CostInputs costInputs,
    required TaxInputs taxInputs,
    required CurrencySpec currency,
    CalculationResult? results,
    String? gcodePath,
    String? gcodeFilename,
    String? existingId,
  }) async {
    if (_client == null) {
      throw StateError('Supabase não configurado.');
    }

    final title = costInputs.productName.isEmpty
        ? 'Cálculo ${DateTime.now().toString().substring(0, 16)}'
        : costInputs.productName;

    final payload = {
      'user_id': userId,
      'title': title,
      'cost_inputs': CalculatorSerializer.costInputsToJson(costInputs),
      'tax_inputs': CalculatorSerializer.taxInputsToJson(taxInputs),
      'currency_code': currency.code,
      'results': CalculatorSerializer.resultsToJson(results),
      'gcode_path': gcodePath,
      'gcode_filename': gcodeFilename,
    };

    if (existingId != null) {
      await _client.from('calculations').update(payload).eq('id', existingId);
      return existingId;
    }

    final inserted = await _client
        .from('calculations')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<void> delete(String id) async {
    if (_client == null) return;
    await _client.from('calculations').delete().eq('id', id);
  }

  Future<
    ({
      CostInputs cost,
      TaxInputs tax,
      CurrencySpec currency,
      CalculationResult? results,
      String? gcodePath,
      String? gcodeFilename,
    })?
  >
  loadState(String id) async {
    if (_client == null) return null;

    final row = await _client
        .from('calculations')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    final map = Map<String, dynamic>.from(row);
    return (
      cost: CalculatorSerializer.costInputsFromJson(
        Map<String, dynamic>.from(map['cost_inputs'] as Map? ?? {}),
      ),
      tax: CalculatorSerializer.taxInputsFromJson(
        Map<String, dynamic>.from(map['tax_inputs'] as Map? ?? {}),
      ),
      currency: CalculatorSerializer.currencyFromCode(
        map['currency_code'] as String?,
      ),
      results: CalculatorSerializer.resultsFromJson(
        map['results'] != null
            ? Map<String, dynamic>.from(map['results'] as Map)
            : null,
      ),
      gcodePath: map['gcode_path'] as String?,
      gcodeFilename: map['gcode_filename'] as String?,
    );
  }

  Future<Uint8List?> downloadGcode(String? path) async {
    if (_client == null || path == null) return null;
    return _client.storage.from('gcodes').download(path);
  }
}
