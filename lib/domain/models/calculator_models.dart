import '../../core/constants/energy_regions.dart';
import 'stock_models.dart';

class FilamentUsage {
  FilamentUsage({
    this.supplyId,
    this.label = '',
    this.weightGrams = 0,
    this.pricePerKg = 120,
    this.color,
  });

  final String? supplyId;
  final String label;
  final double weightGrams;
  final double pricePerKg;
  final String? color;

  double get cost => (pricePerKg / 1000) * weightGrams;

  FilamentUsage copyWith({
    String? supplyId,
    String? label,
    double? weightGrams,
    double? pricePerKg,
    String? color,
  }) {
    return FilamentUsage(
      supplyId: supplyId ?? this.supplyId,
      label: label ?? this.label,
      weightGrams: weightGrams ?? this.weightGrams,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'supplyId': supplyId,
        'label': label,
        'weightGrams': weightGrams,
        'pricePerKg': pricePerKg,
        'color': color,
      };

  factory FilamentUsage.fromJson(Map<String, dynamic> json) => FilamentUsage(
        supplyId: json['supplyId'] as String?,
        label: json['label'] as String? ?? '',
        weightGrams: _toDouble(json['weightGrams']),
        pricePerKg: _toDouble(json['pricePerKg'], fallback: 120),
        color: json['color'] as String?,
      );

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}

class CostInputs {
  CostInputs({
    this.productName = '',
    this.filamentPrice = 120,
    this.modelWeight = 0,
    this.printTime = '0:00',
    this.stateEnergy = 'São Paulo',
    this.printerModel = '',
    this.printerValue = 1800,
    this.printerPower = 150,
    this.lifespanHours = 3000,
    this.riskPercent = 10,
    this.extras = 0,
    this.profitMargin = 100,
    this.selectedSupplyId,
    this.customEnergyRate,
    this.tariffFlag = TariffFlag.none,
    this.filaments = const [],
    this.postProcessingCost = 0,
    this.batchQuantity = 1,
    this.marginPresetId = 'professional',
    this.whatIfProfitMargin,
  });

  final String productName;
  final double filamentPrice;
  final double modelWeight;
  final String printTime;
  final String stateEnergy;
  final String printerModel;
  final double printerValue;
  final double printerPower;
  final double lifespanHours;
  final double riskPercent;
  final double extras;
  final double profitMargin;
  final String? selectedSupplyId;
  final double? customEnergyRate;
  final TariffFlag tariffFlag;
  final List<FilamentUsage> filaments;
  final double postProcessingCost;
  final int batchQuantity;
  final String marginPresetId;
  final double? whatIfProfitMargin;

  double get effectiveProfitMargin => whatIfProfitMargin ?? profitMargin;

  double get totalFilamentWeight {
    if (filaments.isNotEmpty) {
      return filaments.fold(0.0, (sum, f) => sum + f.weightGrams);
    }
    return modelWeight;
  }

  CostInputs copyWith({
    String? productName,
    double? filamentPrice,
    double? modelWeight,
    String? printTime,
    String? stateEnergy,
    String? printerModel,
    double? printerValue,
    double? printerPower,
    double? lifespanHours,
    double? riskPercent,
    double? extras,
    double? profitMargin,
    String? selectedSupplyId,
    bool clearSupplyId = false,
    double? customEnergyRate,
    bool clearCustomEnergyRate = false,
    TariffFlag? tariffFlag,
    List<FilamentUsage>? filaments,
    double? postProcessingCost,
    int? batchQuantity,
    String? marginPresetId,
    double? whatIfProfitMargin,
    bool clearWhatIf = false,
  }) {
    return CostInputs(
      productName: productName ?? this.productName,
      filamentPrice: filamentPrice ?? this.filamentPrice,
      modelWeight: modelWeight ?? this.modelWeight,
      printTime: printTime ?? this.printTime,
      stateEnergy: stateEnergy ?? this.stateEnergy,
      printerModel: printerModel ?? this.printerModel,
      printerValue: printerValue ?? this.printerValue,
      printerPower: printerPower ?? this.printerPower,
      lifespanHours: lifespanHours ?? this.lifespanHours,
      riskPercent: riskPercent ?? this.riskPercent,
      extras: extras ?? this.extras,
      profitMargin: profitMargin ?? this.profitMargin,
      selectedSupplyId: clearSupplyId ? null : (selectedSupplyId ?? this.selectedSupplyId),
      customEnergyRate:
          clearCustomEnergyRate ? null : (customEnergyRate ?? this.customEnergyRate),
      tariffFlag: tariffFlag ?? this.tariffFlag,
      filaments: filaments ?? this.filaments,
      postProcessingCost: postProcessingCost ?? this.postProcessingCost,
      batchQuantity: batchQuantity ?? this.batchQuantity,
      marginPresetId: marginPresetId ?? this.marginPresetId,
      whatIfProfitMargin:
          clearWhatIf ? null : (whatIfProfitMargin ?? this.whatIfProfitMargin),
    );
  }
}

class TaxInputs {
  TaxInputs({
    this.platform = 'Mercado Livre',
    this.commission = 0,
    this.fixedFee = 6,
    this.shipping = 0,
    this.taxNF = 4,
    this.extraTaxPercent = 0,
    this.extraTaxValue = 0,
  });

  final String platform;
  final double commission;
  final double fixedFee;
  final double shipping;
  final double taxNF;
  final double extraTaxPercent;
  final double extraTaxValue;

  TaxInputs copyWith({
    String? platform,
    double? commission,
    double? fixedFee,
    double? shipping,
    double? taxNF,
    double? extraTaxPercent,
    double? extraTaxValue,
  }) {
    return TaxInputs(
      platform: platform ?? this.platform,
      commission: commission ?? this.commission,
      fixedFee: fixedFee ?? this.fixedFee,
      shipping: shipping ?? this.shipping,
      taxNF: taxNF ?? this.taxNF,
      extraTaxPercent: extraTaxPercent ?? this.extraTaxPercent,
      extraTaxValue: extraTaxValue ?? this.extraTaxValue,
    );
  }
}

class CostDetails {
  CostDetails({
    required this.filament,
    required this.energy,
    required this.depreciation,
    required this.extras,
    required this.risk,
    required this.profit,
    required this.powerUsed,
    required this.weight,
    required this.hours,
    required this.riskPercent,
    required this.profitMargin,
    this.postProcessing = 0,
    this.energyRate = 0,
    this.batchQuantity = 1,
    this.batchDiscount = 0,
    this.stockMaterials = 0,
  });

  final double filament;
  final double energy;
  final double depreciation;
  final double extras;
  final double risk;
  final double profit;
  final double powerUsed;
  final double weight;
  final double hours;
  final double riskPercent;
  final double profitMargin;
  final double postProcessing;
  final double energyRate;
  final int batchQuantity;
  final double batchDiscount;
  final double stockMaterials;
}

class CalculationResult {
  CalculationResult({
    required this.totalCost,
    required this.finalPrice,
    required this.totalTaxes,
    required this.details,
    this.unitPrice,
  });

  final double totalCost;
  final double finalPrice;
  final double totalTaxes;
  final CostDetails details;
  final double? unitPrice;
}

class QuoteItem {
  QuoteItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.supplyId,
  });

  final String id;
  final String name;
  final String description;
  final int quantity;
  final double unitPrice;
  final String? supplyId;

  QuoteItem copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    double? unitPrice,
    String? supplyId,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      supplyId: supplyId ?? this.supplyId,
    );
  }

  double get total => unitPrice * quantity;
}

class QuoteData {
  QuoteData({
    required this.quoteNumber,
    this.companyName = '',
    this.companyEmail = '',
    this.companyPhone = '',
    this.companySlogan = 'Soluções em Manufatura Aditiva',
    this.companyLogoBytes,
    this.clientName = '',
    this.contact = '',
    required this.date,
    this.items = const [],
    this.discountPercent = 0,
    this.shippingCost = 0,
    this.observations = '',
    this.stockMovements = const [],
    this.isFinalized = false,
    this.finalizedAt,
  });

  final String quoteNumber;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String companySlogan;
  final List<int>? companyLogoBytes;
  final String clientName;
  final String contact;
  final String date;
  final List<QuoteItem> items;
  final double discountPercent;
  final double shippingCost;
  final String observations;
  final List<QuoteStockMovement> stockMovements;
  final bool isFinalized;
  final String? finalizedAt;

  double get stockMaterialsCost =>
      stockMovements.fold(0.0, (sum, m) => sum + m.totalCost);

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get discountAmount => subtotal * (discountPercent / 100);

  double get total => subtotal - discountAmount + shippingCost;

  QuoteData copyWith({
    String? quoteNumber,
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? companySlogan,
    List<int>? companyLogoBytes,
    bool clearLogo = false,
    String? clientName,
    String? contact,
    String? date,
    List<QuoteItem>? items,
    double? discountPercent,
    double? shippingCost,
    String? observations,
    List<QuoteStockMovement>? stockMovements,
    bool? isFinalized,
    String? finalizedAt,
    bool clearFinalizedAt = false,
  }) {
    return QuoteData(
      quoteNumber: quoteNumber ?? this.quoteNumber,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      companySlogan: companySlogan ?? this.companySlogan,
      companyLogoBytes: clearLogo ? null : (companyLogoBytes ?? this.companyLogoBytes),
      clientName: clientName ?? this.clientName,
      contact: contact ?? this.contact,
      date: date ?? this.date,
      items: items ?? this.items,
      discountPercent: discountPercent ?? this.discountPercent,
      shippingCost: shippingCost ?? this.shippingCost,
      observations: observations ?? this.observations,
      stockMovements: stockMovements ?? this.stockMovements,
      isFinalized: isFinalized ?? this.isFinalized,
      finalizedAt: clearFinalizedAt ? null : (finalizedAt ?? this.finalizedAt),
    );
  }
}

class GCodeMetrics {
  GCodeMetrics({
    required this.filamentType,
    required this.estimatedMeters,
    required this.printTimeMinutes,
    required this.weight,
    this.thumbnailBytes,
    this.density = 1.24,
  });

  final String filamentType;
  final double estimatedMeters;
  final int printTimeMinutes;
  final int weight;
  final List<int>? thumbnailBytes;
  final double density;
}
