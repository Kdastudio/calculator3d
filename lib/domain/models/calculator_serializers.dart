import '../../core/constants/calculator_constants.dart';
import '../../core/constants/energy_regions.dart';
import '../models/calculator_models.dart';
import '../models/stock_models.dart';

class CalculatorSerializer {
  CalculatorSerializer._();

  static Map<String, dynamic> costInputsToJson(CostInputs inputs) => {
        'productName': inputs.productName,
        'filamentPrice': inputs.filamentPrice,
        'modelWeight': inputs.modelWeight,
        'printTime': inputs.printTime,
        'stateEnergy': inputs.stateEnergy,
        'printerModel': inputs.printerModel,
        'printerValue': inputs.printerValue,
        'printerPower': inputs.printerPower,
        'lifespanHours': inputs.lifespanHours,
        'riskPercent': inputs.riskPercent,
        'extras': inputs.extras,
        'profitMargin': inputs.profitMargin,
        'selectedSupplyId': inputs.selectedSupplyId,
        'customEnergyRate': inputs.customEnergyRate,
        'tariffFlag': inputs.tariffFlag.name,
        'filaments': inputs.filaments.map((f) => f.toJson()).toList(),
        'postProcessingCost': inputs.postProcessingCost,
        'batchQuantity': inputs.batchQuantity,
        'marginPresetId': inputs.marginPresetId,
      };

  static CostInputs costInputsFromJson(Map<String, dynamic> json) {
    final flagName = json['tariffFlag'] as String? ?? 'none';
    final filamentsJson = json['filaments'] as List<dynamic>? ?? [];

    return CostInputs(
      productName: json['productName'] as String? ?? '',
      filamentPrice: _toDouble(json['filamentPrice'], 120),
      modelWeight: _toDouble(json['modelWeight'], 0),
      printTime: json['printTime'] as String? ?? '0:00',
      stateEnergy: json['stateEnergy'] as String? ?? 'São Paulo',
      printerModel: json['printerModel'] as String? ?? '',
      printerValue: _toDouble(json['printerValue'], 1800),
      printerPower: _toDouble(json['printerPower'], 150),
      lifespanHours: _toDouble(json['lifespanHours'], 3000),
      riskPercent: _toDouble(json['riskPercent'], 10),
      extras: _toDouble(json['extras'], 0),
      profitMargin: _toDouble(json['profitMargin'], 100),
      selectedSupplyId: json['selectedSupplyId'] as String?,
      customEnergyRate: json['customEnergyRate'] != null
          ? _toDouble(json['customEnergyRate'], 0)
          : null,
      tariffFlag: TariffFlag.values.firstWhere(
        (f) => f.name == flagName,
        orElse: () => TariffFlag.none,
      ),
      filaments: filamentsJson
          .map((f) => FilamentUsage.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
      postProcessingCost: _toDouble(json['postProcessingCost'], 0),
      batchQuantity: (json['batchQuantity'] as num?)?.toInt() ?? 1,
      marginPresetId: json['marginPresetId'] as String? ?? 'professional',
    );
  }

  static Map<String, dynamic> taxInputsToJson(TaxInputs inputs) => {
        'platform': inputs.platform,
        'commission': inputs.commission,
        'fixedFee': inputs.fixedFee,
        'shipping': inputs.shipping,
        'taxNF': inputs.taxNF,
        'extraTaxPercent': inputs.extraTaxPercent,
        'extraTaxValue': inputs.extraTaxValue,
      };

  static TaxInputs taxInputsFromJson(Map<String, dynamic> json) => TaxInputs(
        platform: json['platform'] as String? ?? 'Mercado Livre',
        commission: _toDouble(json['commission'], 16),
        fixedFee: _toDouble(json['fixedFee'], 5.5),
        shipping: _toDouble(json['shipping'], 0),
        taxNF: _toDouble(json['taxNF'], 4),
        extraTaxPercent: _toDouble(json['extraTaxPercent'], 0),
        extraTaxValue: _toDouble(json['extraTaxValue'], 0),
      );

  static Map<String, dynamic>? resultsToJson(CalculationResult? result) {
    if (result == null) return null;
    return {
      'totalCost': result.totalCost,
      'finalPrice': result.finalPrice,
      'totalTaxes': result.totalTaxes,
      'unitPrice': result.unitPrice,
      'details': {
        'filament': result.details.filament,
        'energy': result.details.energy,
        'depreciation': result.details.depreciation,
        'extras': result.details.extras,
        'risk': result.details.risk,
        'profit': result.details.profit,
        'powerUsed': result.details.powerUsed,
        'weight': result.details.weight,
        'hours': result.details.hours,
        'riskPercent': result.details.riskPercent,
        'profitMargin': result.details.profitMargin,
        'postProcessing': result.details.postProcessing,
        'energyRate': result.details.energyRate,
        'batchQuantity': result.details.batchQuantity,
        'batchDiscount': result.details.batchDiscount,
      },
    };
  }

  static CalculationResult? resultsFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final details = json['details'] as Map<String, dynamic>? ?? {};
    return CalculationResult(
      totalCost: _toDouble(json['totalCost'], 0),
      finalPrice: _toDouble(json['finalPrice'], 0),
      totalTaxes: _toDouble(json['totalTaxes'], 0),
      unitPrice: json['unitPrice'] != null ? _toDouble(json['unitPrice'], 0) : null,
      details: CostDetails(
        filament: _toDouble(details['filament'], 0),
        energy: _toDouble(details['energy'], 0),
        depreciation: _toDouble(details['depreciation'], 0),
        extras: _toDouble(details['extras'], 0),
        risk: _toDouble(details['risk'], 0),
        profit: _toDouble(details['profit'], 0),
        powerUsed: _toDouble(details['powerUsed'], 150),
        weight: _toDouble(details['weight'], 0),
        hours: _toDouble(details['hours'], 0),
        riskPercent: _toDouble(details['riskPercent'], 0),
        profitMargin: _toDouble(details['profitMargin'], 0),
        postProcessing: _toDouble(details['postProcessing'], 0),
        energyRate: _toDouble(details['energyRate'], 0),
        batchQuantity: (details['batchQuantity'] as num?)?.toInt() ?? 1,
        batchDiscount: _toDouble(details['batchDiscount'], 0),
      ),
    );
  }

  static List<Map<String, dynamic>> quoteItemsToJson(List<QuoteItem> items) =>
      items
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
          .toList();

  static List<QuoteItem> quoteItemsFromJson(List<dynamic> json) => json
      .map(
        (item) => QuoteItem(
          id: item['id'] as String? ?? '',
          name: item['name'] as String? ?? '',
          description: item['description'] as String? ?? '',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          unitPrice: _toDouble(item['unitPrice'], 0),
          supplyId: item['supplyId'] as String?,
        ),
      )
      .toList();

  static Map<String, dynamic> quoteDataToJson(QuoteData data) => {
        'quoteNumber': data.quoteNumber,
        'companyName': data.companyName,
        'companyEmail': data.companyEmail,
        'companyPhone': data.companyPhone,
        'companySlogan': data.companySlogan,
        'clientName': data.clientName,
        'contact': data.contact,
        'date': data.date,
        'items': quoteItemsToJson(data.items),
        'discountPercent': data.discountPercent,
        'shippingCost': data.shippingCost,
        'observations': data.observations,
        'stockMovements': data.stockMovements.map((m) => m.toJson()).toList(),
        'isFinalized': data.isFinalized,
        'finalizedAt': data.finalizedAt,
      };

  static QuoteData quoteDataFromJson(Map<String, dynamic> json, {List<int>? logoBytes}) =>
      QuoteData(
        quoteNumber: json['quoteNumber'] as String? ?? '',
        companyName: json['companyName'] as String? ?? '',
        companyEmail: json['companyEmail'] as String? ?? '',
        companyPhone: json['companyPhone'] as String? ?? '',
        companySlogan: json['companySlogan'] as String? ?? 'Soluções em Manufatura Aditiva',
        companyLogoBytes: logoBytes,
        clientName: json['clientName'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        date: json['date'] as String? ?? DateTime.now().toIso8601String().split('T').first,
        items: quoteItemsFromJson(json['items'] as List<dynamic>? ?? []),
        discountPercent: _toDouble(json['discountPercent'], 0),
        shippingCost: _toDouble(json['shippingCost'], 0),
        observations: json['observations'] as String? ?? '',
        stockMovements: (json['stockMovements'] as List<dynamic>? ?? [])
            .map((e) => QuoteStockMovement.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        isFinalized: json['isFinalized'] as bool? ?? false,
        finalizedAt: json['finalizedAt'] as String?,
      );

  static CurrencySpec currencyFromCode(String? code) {
    return CalculatorConstants.currencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CalculatorConstants.currencies.first,
    );
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}
