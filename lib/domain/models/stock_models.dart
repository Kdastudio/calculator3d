class StockItem {
  StockItem({
    required this.id,
    required this.name,
    this.unit = 'g',
    this.quantityOnHand = 0,
    this.unitCost = 0,
    this.supplyId,
    this.notes = '',
  });

  final String id;
  final String name;
  final String unit;
  final double quantityOnHand;
  final double unitCost;
  final String? supplyId;
  final String notes;

  String get displayQuantity => '${_formatQty(quantityOnHand)} $unit';

  double costForQuantity(double quantity) => unitCost * quantity;

  StockItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? quantityOnHand,
    double? unitCost,
    String? supplyId,
    bool clearSupplyId = false,
    String? notes,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      unitCost: unitCost ?? this.unitCost,
      supplyId: clearSupplyId ? null : (supplyId ?? this.supplyId),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'quantityOnHand': quantityOnHand,
        'unitCost': unitCost,
        'supplyId': supplyId,
        'notes': notes,
      };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? 'g',
        quantityOnHand: _toDouble(json['quantityOnHand']),
        unitCost: _toDouble(json['unitCost']),
        supplyId: json['supplyId'] as String?,
        notes: json['notes'] as String? ?? '',
      );

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static String _formatQty(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

class QuoteStockAllocation {
  QuoteStockAllocation({
    required this.id,
    required this.stockItemId,
    this.quantityToUse = 0,
  });

  final String id;
  final String stockItemId;
  final double quantityToUse;

  QuoteStockAllocation copyWith({
    String? id,
    String? stockItemId,
    double? quantityToUse,
  }) {
    return QuoteStockAllocation(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      quantityToUse: quantityToUse ?? this.quantityToUse,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stockItemId': stockItemId,
        'quantityToUse': quantityToUse,
      };

  factory QuoteStockAllocation.fromJson(Map<String, dynamic> json) =>
      QuoteStockAllocation(
        id: json['id'] as String? ?? '',
        stockItemId: json['stockItemId'] as String? ?? '',
        quantityToUse: StockItem._toDouble(json['quantityToUse']),
      );
}

class QuoteStockMovement {
  QuoteStockMovement({
    required this.stockItemId,
    required this.itemName,
    required this.unit,
    required this.quantityUsed,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.unitCost,
  });

  final String stockItemId;
  final String itemName;
  final String unit;
  final double quantityUsed;
  final double quantityBefore;
  final double quantityAfter;
  final double unitCost;

  double get totalCost => unitCost * quantityUsed;

  Map<String, dynamic> toJson() => {
        'stockItemId': stockItemId,
        'itemName': itemName,
        'unit': unit,
        'quantityUsed': quantityUsed,
        'quantityBefore': quantityBefore,
        'quantityAfter': quantityAfter,
        'unitCost': unitCost,
      };

  factory QuoteStockMovement.fromJson(Map<String, dynamic> json) =>
      QuoteStockMovement(
        stockItemId: json['stockItemId'] as String? ?? '',
        itemName: json['itemName'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        quantityUsed: StockItem._toDouble(json['quantityUsed']),
        quantityBefore: StockItem._toDouble(json['quantityBefore']),
        quantityAfter: StockItem._toDouble(json['quantityAfter']),
        unitCost: StockItem._toDouble(json['unitCost']),
      );
}

class FinalizeQuoteResult {
  const FinalizeQuoteResult.success(this.movements)
      : error = null,
        success = true;

  const FinalizeQuoteResult.failure(this.error)
      : movements = const [],
        success = false;

  final bool success;
  final String? error;
  final List<QuoteStockMovement> movements;
}
