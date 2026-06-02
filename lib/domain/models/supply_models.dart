enum SupplyType {
  filament('Filamento'),
  resin('Resina'),
  nozzle('Bico/Nozzle'),
  adhesive('Adesivo'),
  packaging('Embalagem'),
  postProcessing('Pós-processamento'),
  other('Outro');

  const SupplyType(this.label);
  final String label;
}

class SupplyItem {
  SupplyItem({
    required this.id,
    required this.name,
    this.type = SupplyType.filament,
    this.brand = '',
    this.supplier = '',
    this.pricePerUnit = 0,
    this.unit = 'kg',
    this.color,
    this.material,
    this.density = 1.24,
    this.purchasedAt,
    this.isActive = true,
    this.notes = '',
  });

  final String id;
  final String name;
  final SupplyType type;
  final String brand;
  final String supplier;
  final double pricePerUnit;
  final String unit;
  final String? color;
  final String? material;
  final double density;
  final DateTime? purchasedAt;
  final bool isActive;
  final String notes;

  double get pricePerKg {
    if (unit == 'g') return pricePerUnit * 1000;
    if (unit == 'kg') return pricePerUnit;
    return pricePerUnit;
  }

  String get displayLabel {
    final parts = <String>[name];
    if (brand.isNotEmpty) parts.add(brand);
    if (supplier.isNotEmpty) parts.add('($supplier)');
    return parts.join(' · ');
  }

  SupplyItem copyWith({
    String? id,
    String? name,
    SupplyType? type,
    String? brand,
    String? supplier,
    double? pricePerUnit,
    String? unit,
    String? color,
    String? material,
    double? density,
    DateTime? purchasedAt,
    bool? isActive,
    String? notes,
  }) {
    return SupplyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      supplier: supplier ?? this.supplier,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      material: material ?? this.material,
      density: density ?? this.density,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'brand': brand,
        'supplier': supplier,
        'pricePerUnit': pricePerUnit,
        'unit': unit,
        'color': color,
        'material': material,
        'density': density,
        'purchasedAt': purchasedAt?.toIso8601String(),
        'isActive': isActive,
        'notes': notes,
      };

  factory SupplyItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'filament';
    return SupplyItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: SupplyType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => SupplyType.filament,
      ),
      brand: json['brand'] as String? ?? '',
      supplier: json['supplier'] as String? ?? '',
      pricePerUnit: _toDouble(json['pricePerUnit']),
      unit: json['unit'] as String? ?? 'kg',
      color: json['color'] as String?,
      material: json['material'] as String?,
      density: _toDouble(json['density'], fallback: 1.24),
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.tryParse(json['purchasedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}

class SupplyPriceHistory {
  SupplyPriceHistory({
    required this.id,
    required this.supplyId,
    required this.price,
    required this.supplier,
    required this.recordedAt,
  });

  final String id;
  final String supplyId;
  final double price;
  final String supplier;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplyId': supplyId,
        'price': price,
        'supplier': supplier,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory SupplyPriceHistory.fromJson(Map<String, dynamic> json) =>
      SupplyPriceHistory(
        id: json['id'] as String? ?? '',
        supplyId: json['supplyId'] as String? ?? '',
        price: SupplyItem._toDouble(json['price']),
        supplier: json['supplier'] as String? ?? '',
        recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class SupplyComparisonResult {
  SupplyComparisonResult({
    required this.supply,
    required this.materialCost,
    required this.totalCost,
    required this.finalPrice,
    required this.profit,
  });

  final SupplyItem supply;
  final double materialCost;
  final double totalCost;
  final double finalPrice;
  final double profit;
}
