import 'calculator_models.dart';
import 'stock_models.dart';

class QuoteHistoryEntry {
  QuoteHistoryEntry({
    required this.id,
    required this.quote,
    required this.currencyCode,
    required this.total,
    required this.savedAt,
  });

  final String id;
  final QuoteData quote;
  final String currencyCode;
  final double total;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'currencyCode': currencyCode,
        'total': total,
        'savedAt': savedAt.toIso8601String(),
        'quote': _quoteToJson(quote),
      };

  factory QuoteHistoryEntry.fromJson(Map<String, dynamic> json) {
    final quoteMap = Map<String, dynamic>.from(json['quote'] as Map? ?? {});
    return QuoteHistoryEntry(
      id: json['id'] as String? ?? '',
      quote: _quoteFromJson(quoteMap),
      currencyCode: json['currencyCode'] as String? ?? 'BRL',
      total: _toDouble(json['total']),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _quoteToJson(QuoteData data) => {
        'quoteNumber': data.quoteNumber,
        'companyName': data.companyName,
        'companyEmail': data.companyEmail,
        'companyPhone': data.companyPhone,
        'companySlogan': data.companySlogan,
        'companyLogoBytes': data.companyLogoBytes,
        'clientName': data.clientName,
        'contact': data.contact,
        'date': data.date,
        'items': data.items
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'description': item.description,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'supplyId': item.supplyId,
              },
            )
            .toList(),
        'discountPercent': data.discountPercent,
        'shippingCost': data.shippingCost,
        'observations': data.observations,
        'stockMovements': data.stockMovements.map((m) => m.toJson()).toList(),
        'isFinalized': data.isFinalized,
        'finalizedAt': data.finalizedAt,
      };

  static QuoteData _quoteFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map(
          (e) => QuoteItem(
            id: e['id'] as String? ?? '',
            name: e['name'] as String? ?? '',
            description: e['description'] as String? ?? '',
            quantity: (e['quantity'] as num?)?.toInt() ?? 1,
            unitPrice: _toDouble(e['unitPrice']),
            supplyId: e['supplyId'] as String?,
          ),
        )
        .toList();

    final logoRaw = json['companyLogoBytes'];
    List<int>? logoBytes;
    if (logoRaw is List) {
      logoBytes = logoRaw.map((e) => (e as num).toInt()).toList();
    }

    return QuoteData(
      quoteNumber: json['quoteNumber'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      companyEmail: json['companyEmail'] as String? ?? '',
      companyPhone: json['companyPhone'] as String? ?? '',
      companySlogan: json['companySlogan'] as String? ?? 'Soluções em Manufatura Aditiva',
      companyLogoBytes: logoBytes,
      clientName: json['clientName'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      date: json['date'] as String? ?? '',
      items: items,
      discountPercent: _toDouble(json['discountPercent']),
      shippingCost: _toDouble(json['shippingCost']),
      observations: json['observations'] as String? ?? '',
      stockMovements: (json['stockMovements'] as List<dynamic>? ?? [])
          .map((e) => QuoteStockMovement.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      isFinalized: json['isFinalized'] as bool? ?? false,
      finalizedAt: json['finalizedAt'] as String?,
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}
