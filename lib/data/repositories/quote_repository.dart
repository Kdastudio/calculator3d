import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/calculator_constants.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/models/calculator_serializers.dart';
import '../../domain/models/calculator_models.dart';
import '../../domain/models/cloud_models.dart';

class QuoteRepository {
  QuoteRepository({SupabaseClient? client})
    : _client =
          client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null);

  final SupabaseClient? _client;

  Future<List<SavedQuote>> list(String userId) async {
    if (_client == null) return [];

    final rows = await _client
        .from('quotes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (rows as List)
        .map((row) => SavedQuote.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String> save({
    required String userId,
    required QuoteData quote,
    required CurrencySpec currency,
    String? logoPath,
    String? existingId,
  }) async {
    if (_client == null) {
      throw StateError('Supabase não configurado.');
    }

    final payload = {
      'user_id': userId,
      'quote_number': quote.quoteNumber,
      'client_name': quote.clientName,
      'contact': quote.contact,
      'quote_date': quote.date,
      'items': CalculatorSerializer.quoteItemsToJson(quote.items),
      'discount_percent': quote.discountPercent,
      'shipping_cost': quote.shippingCost,
      'observations': quote.observations,
      'company_name': quote.companyName,
      'company_email': quote.companyEmail,
      'company_phone': quote.companyPhone,
      'company_slogan': quote.companySlogan,
      'logo_path': logoPath,
      'currency_code': currency.code,
    };

    if (existingId != null) {
      await _client.from('quotes').update(payload).eq('id', existingId);
      return existingId;
    }

    final inserted = await _client
        .from('quotes')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<void> delete(String id) async {
    if (_client == null) return;
    await _client.from('quotes').delete().eq('id', id);
  }

  Future<({QuoteData quote, CurrencySpec currency, String? logoPath})?>
  loadState(String id, {List<int>? logoBytes}) async {
    if (_client == null) return null;

    final row = await _client
        .from('quotes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    final map = Map<String, dynamic>.from(row);
    final quoteJson = CalculatorSerializer.quoteDataToJson(
      QuoteData(
        quoteNumber: map['quote_number'] as String? ?? '',
        companyName: map['company_name'] as String? ?? '',
        companyEmail: map['company_email'] as String? ?? '',
        companyPhone: map['company_phone'] as String? ?? '',
        companySlogan: map['company_slogan'] as String? ?? '',
        clientName: map['client_name'] as String? ?? '',
        contact: map['contact'] as String? ?? '',
        date: map['quote_date'] as String? ?? '',
        items: CalculatorSerializer.quoteItemsFromJson(
          map['items'] as List<dynamic>? ?? [],
        ),
        discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0,
        shippingCost: (map['shipping_cost'] as num?)?.toDouble() ?? 0,
        observations: map['observations'] as String? ?? '',
      ),
    );

    return (
      quote: CalculatorSerializer.quoteDataFromJson(
        quoteJson,
        logoBytes: logoBytes,
      ),
      currency: CalculatorSerializer.currencyFromCode(
        map['currency_code'] as String?,
      ),
      logoPath: map['logo_path'] as String?,
    );
  }
}
