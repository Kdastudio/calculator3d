import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/calculator_constants.dart';
import '../../core/constants/energy_regions.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/time_parser.dart';
import '../../domain/models/calculator_models.dart';
import '../../domain/services/calculator_service.dart';
import '../../domain/services/energy_service.dart';
import '../../domain/services/gcode_parser.dart';
import '../../domain/services/quote_pdf_service.dart';
import '../../domain/services/supply_service.dart';
import '../../domain/models/stock_models.dart';
import '../../domain/services/stock_service.dart';
import '../../domain/models/supply_models.dart';
import 'energy_provider.dart';
import 'stock_provider.dart';

class CalculatorProvider extends ChangeNotifier {
  CalculatorProvider({
    CalculatorService? calculatorService,
    GCodeParser? gCodeParser,
    QuotePdfService? quotePdfService,
    SupplyService? supplyService,
    EnergyService? energyService,
  })  : _calculatorService = calculatorService ?? CalculatorService(),
        _gCodeParser = gCodeParser ?? GCodeParser(),
        _quotePdfService = quotePdfService ?? QuotePdfService(),
        _supplyService = supplyService ?? SupplyService(),
        _energyService = energyService ?? EnergyService(),
        _stockService = StockService();

  final CalculatorService _calculatorService;
  final GCodeParser _gCodeParser;
  final QuotePdfService _quotePdfService;
  final SupplyService _supplyService;
  final EnergyService _energyService;
  final StockService _stockService;
  final _uuid = const Uuid();
  final _debouncer = Debouncer();

  CostInputs _costInputs = CostInputs();
  TaxInputs _taxInputs = TaxInputs();
  CurrencySpec _currency = CalculatorConstants.currencies.first;
  QuoteData _quoteData = QuoteData(
    quoteNumber: _generateQuoteNumber(),
    date: DateTime.now().toIso8601String().split('T').first,
  );

  CalculationResult? _results;
  GCodeMetrics? _gCodeMetrics;
  String? _gCodeFileName;
  List<int>? _gCodeContentBytes;
  bool _autoCalculate = true;
  bool _parsingGcode = false;
  List<QuoteStockAllocation> _stockAllocations = [];
  List<StockItem> _cachedStockItems = [];

  CostInputs get costInputs => _costInputs;
  TaxInputs get taxInputs => _taxInputs;
  CurrencySpec get currency => _currency;
  QuoteData get quoteData => _quoteData;
  List<QuoteStockAllocation> get stockAllocations => List.unmodifiable(_stockAllocations);
  CalculationResult? get results => _results;
  GCodeMetrics? get gCodeMetrics => _gCodeMetrics;
  String? get gCodeFileName => _gCodeFileName;
  List<int>? get gCodeContentBytes => _gCodeContentBytes;
  bool get autoCalculate => _autoCalculate;
  bool get parsingGcode => _parsingGcode;

  static String _generateQuoteNumber() {
    final year = DateTime.now().year;
    final random = 100 + DateTime.now().millisecondsSinceEpoch % 900;
    return 'ORC-$year-$random';
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _scheduleCalculate() {
    if (!_autoCalculate) return;
    _debouncer.run(calculate);
  }

  void updateStockContext(List<StockItem> items) {
    if (_stockListsEqual(_cachedStockItems, items)) return;
    _cachedStockItems = items;
    if (_stockAllocations.isNotEmpty) calculate();
  }

  bool _stockListsEqual(List<StockItem> a, List<StockItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].quantityOnHand != b[i].quantityOnHand) return false;
    }
    return true;
  }

  double get stockMaterialCost =>
      _stockService.allocationCost(_stockAllocations, _cachedStockItems);

  void addStockAllocation(String stockItemId) {
    if (_quoteData.isFinalized) return;
    if (_stockAllocations.any((a) => a.stockItemId == stockItemId)) return;
    _stockAllocations = [
      ..._stockAllocations,
      QuoteStockAllocation(id: _uuid.v4(), stockItemId: stockItemId),
    ];
    calculate();
    notifyListeners();
  }

  void updateStockAllocation(String id, {String? stockItemId, double? quantityToUse}) {
    if (_quoteData.isFinalized) return;
    _stockAllocations = _stockAllocations.map((a) {
      if (a.id != id) return a;
      return a.copyWith(stockItemId: stockItemId, quantityToUse: quantityToUse);
    }).toList();
    calculate();
    notifyListeners();
  }

  void removeStockAllocation(String id) {
    if (_quoteData.isFinalized) return;
    _stockAllocations = _stockAllocations.where((a) => a.id != id).toList();
    calculate();
    notifyListeners();
  }

  Future<FinalizeQuoteResult> finalizeQuote(StockProvider stock) async {
    if (_quoteData.isFinalized) {
      return const FinalizeQuoteResult.failure('Este orçamento já foi finalizado.');
    }
    if (_quoteData.items.isEmpty) {
      return const FinalizeQuoteResult.failure(
        'Adicione pelo menos um item ao orçamento antes de finalizar.',
      );
    }

    _cachedStockItems = stock.items;

    if (_stockAllocations.isNotEmpty) {
      final error = stock.validateAllocations(_stockAllocations);
      if (error != null) return FinalizeQuoteResult.failure(error);

      final movements = stock.buildMovements(_stockAllocations);
      await stock.applyMovements(movements);

      final note = _stockObservations(movements);
      _quoteData = _quoteData.copyWith(
        isFinalized: true,
        finalizedAt: DateTime.now().toIso8601String(),
        stockMovements: movements,
        observations: _appendObservations(_quoteData.observations, note),
      );
      _stockAllocations = [];
      notifyListeners();
      return FinalizeQuoteResult.success(movements);
    }

    _quoteData = _quoteData.copyWith(
      isFinalized: true,
      finalizedAt: DateTime.now().toIso8601String(),
    );
    notifyListeners();
    return const FinalizeQuoteResult.success([]);
  }

  void startNewQuote() {
    _quoteData = QuoteData(
      quoteNumber: _generateQuoteNumber(),
      date: DateTime.now().toIso8601String().split('T').first,
      companyName: _quoteData.companyName,
      companyEmail: _quoteData.companyEmail,
      companyPhone: _quoteData.companyPhone,
      companySlogan: _quoteData.companySlogan,
      companyLogoBytes: _quoteData.companyLogoBytes,
    );
    _stockAllocations = [];
    notifyListeners();
  }

  String _stockObservations(List<QuoteStockMovement> movements) {
    return movements
        .map(
          (m) =>
              '• ${m.itemName}: utilizado ${m.quantityUsed} ${m.unit} — saldo restante ${m.quantityAfter} ${m.unit}',
        )
        .join('\n');
  }

  String _appendObservations(String current, String addition) {
    if (addition.isEmpty) return current;
    const header = '--- Materiais do estoque ---';
    if (current.isEmpty) return '$header\n$addition';
    return '$current\n\n$header\n$addition';
  }

  void setAutoCalculate(bool value) {
    _autoCalculate = value;
    if (value) calculate();
    notifyListeners();
  }

  void updateCostInputs(CostInputs inputs) {
    _costInputs = inputs;
    _scheduleCalculate();
    notifyListeners();
  }

  void updateCostField({
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
    var next = _costInputs.copyWith(
      productName: productName,
      filamentPrice: filamentPrice,
      modelWeight: modelWeight,
      printTime: printTime,
      stateEnergy: stateEnergy,
      printerModel: printerModel,
      printerValue: printerValue,
      printerPower: printerPower,
      lifespanHours: lifespanHours,
      riskPercent: riskPercent,
      extras: extras,
      profitMargin: profitMargin,
      selectedSupplyId: selectedSupplyId,
      clearSupplyId: clearSupplyId,
      customEnergyRate: customEnergyRate,
      clearCustomEnergyRate: clearCustomEnergyRate,
      tariffFlag: tariffFlag,
      filaments: filaments,
      postProcessingCost: postProcessingCost,
      batchQuantity: batchQuantity,
      marginPresetId: marginPresetId,
      whatIfProfitMargin: whatIfProfitMargin,
      clearWhatIf: clearWhatIf,
    );

    if (printerModel != null) {
      final spec = CalculatorConstants.popularPrinters[printerModel];
      if (spec != null) {
        next = next.copyWith(
          printerModel: printerModel,
          printerValue: spec.price,
          printerPower: spec.power,
        );
      }
    }

    _costInputs = next;
    _scheduleCalculate();
    notifyListeners();
  }

  void applyMarginPreset(String presetId) {
    final preset = MarginPreset.find(presetId);
    if (preset == null) return;
    updateCostField(
      marginPresetId: presetId,
      profitMargin: preset.profitMargin,
      riskPercent: preset.riskPercent,
    );
    if (presetId == MarginPreset.marketplace.id &&
        CalculatorConstants.isBuiltinMarketplace(_taxInputs.platform)) {
      updateTaxField(commission: 0);
    }
  }

  void selectSupply(SupplyItem? supply) {
    if (supply == null) {
      updateCostField(clearSupplyId: true);
      return;
    }
    updateCostField(
      selectedSupplyId: supply.id,
      filamentPrice: supply.pricePerKg,
    );
  }

  void addFilamentUsage() {
    final list = [..._costInputs.filaments, FilamentUsage()];
    updateCostField(filaments: list);
  }

  void updateFilamentUsage(int index, FilamentUsage usage) {
    final list = [..._costInputs.filaments];
    if (index < 0 || index >= list.length) return;
    list[index] = usage;
    updateCostField(filaments: list);
  }

  void removeFilamentUsage(int index) {
    final list = [..._costInputs.filaments]..removeAt(index);
    updateCostField(filaments: list);
  }

  void setWhatIfProfitMargin(double? margin) {
    updateCostField(
      whatIfProfitMargin: margin,
      clearWhatIf: margin == null,
    );
  }

  void updateTaxInputs(TaxInputs inputs) {
    _taxInputs = inputs;
    _scheduleCalculate();
    notifyListeners();
  }

  void updateTaxField({
    String? platform,
    double? commission,
    double? fixedFee,
    double? shipping,
    double? taxNF,
    double? extraTaxPercent,
    double? extraTaxValue,
  }) {
    var next = _taxInputs.copyWith(
      platform: platform,
      commission: commission,
      fixedFee: fixedFee,
      shipping: shipping,
      taxNF: taxNF,
      extraTaxPercent: extraTaxPercent,
      extraTaxValue: extraTaxValue,
    );

    if (platform != null) {
      final preset = CalculatorConstants.platformPresets[platform];
      if (preset != null) {
        next = next.copyWith(
          platform: platform,
          commission: CalculatorConstants.isBuiltinMarketplace(platform)
              ? 0
              : preset.commission,
          fixedFee: preset.fixedFee,
        );
      }
    }

    _taxInputs = next;
    _scheduleCalculate();
    notifyListeners();
  }

  void setCurrency(CurrencySpec currency) {
    _currency = currency;
    notifyListeners();
  }

  void updateQuoteData(QuoteData data) {
    _quoteData = data;
    notifyListeners();
  }

  void calculate() {
    final stockCost = stockMaterialCost;
    final inputs = stockCost > 0
        ? _costInputs.copyWith(extras: _costInputs.extras + stockCost)
        : _costInputs;
    final base = _calculatorService.calculateTotal(
      inputs,
      _taxInputs,
      _energyService,
    );
    _results = _withStockDetails(base, stockCost);
    notifyListeners();
  }

  CalculationResult _withStockDetails(CalculationResult result, double stockCost) {
    if (stockCost <= 0) return result;
    final d = result.details;
    return CalculationResult(
      totalCost: result.totalCost,
      finalPrice: result.finalPrice,
      totalTaxes: result.totalTaxes,
      unitPrice: result.unitPrice,
      details: CostDetails(
        filament: d.filament,
        energy: d.energy,
        depreciation: d.depreciation,
        extras: d.extras - stockCost,
        risk: d.risk,
        profit: d.profit,
        powerUsed: d.powerUsed,
        weight: d.weight,
        hours: d.hours,
        riskPercent: d.riskPercent,
        profitMargin: d.profitMargin,
        postProcessing: d.postProcessing,
        energyRate: d.energyRate,
        batchQuantity: d.batchQuantity,
        batchDiscount: d.batchDiscount,
        stockMaterials: stockCost,
      ),
    );
  }

  List<SupplyComparisonResult> compareSupplies(List<SupplyItem> supplies) {
    return _supplyService.compareSupplies(
      supplies: supplies,
      baseInputs: _costInputs,
      taxInputs: _taxInputs,
    );
  }

  void importCalculationToQuote() {
    final result = _calculatorService.calculateTotal(
      _costInputs,
      _taxInputs,
      _energyService,
    );
    final hours = TimeParser.toHours(_costInputs.printTime);
    final item = QuoteItem(
      id: _uuid.v4(),
      name: _costInputs.productName.isEmpty ? 'Impressão 3D' : _costInputs.productName,
      description:
          '${_costInputs.modelWeight.toStringAsFixed(0)}g - ${hours.toStringAsFixed(2)}h de impressão',
      quantity: _costInputs.batchQuantity.clamp(1, 9999),
      unitPrice: result.unitPrice ?? result.finalPrice,
      supplyId: _costInputs.selectedSupplyId,
    );

    _quoteData = _quoteData.copyWith(
      items: [..._quoteData.items, item],
      shippingCost: _taxInputs.shipping,
    );
    notifyListeners();
  }

  void addQuoteItem() {
    final item = QuoteItem(
      id: _uuid.v4(),
      name: 'Novo Item',
      description: 'Descrição',
      quantity: 1,
      unitPrice: 0,
    );
    _quoteData = _quoteData.copyWith(items: [..._quoteData.items, item]);
    notifyListeners();
  }

  void removeQuoteItem(String id) {
    _quoteData = _quoteData.copyWith(
      items: _quoteData.items.where((item) => item.id != id).toList(),
    );
    notifyListeners();
  }

  void updateQuoteItem(String id, {String? name, String? description, int? quantity, double? unitPrice}) {
    final items = _quoteData.items.map((item) {
      if (item.id != id) return item;
      return item.copyWith(
        name: name,
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }).toList();
    _quoteData = _quoteData.copyWith(items: items);
    notifyListeners();
  }

  void setCompanyLogo(List<int>? bytes) {
    if (bytes == null) {
      _quoteData = _quoteData.copyWith(clearLogo: true);
    } else {
      _quoteData = _quoteData.copyWith(companyLogoBytes: bytes);
    }
    notifyListeners();
  }

  Future<void> parseGCode(String content, String fileName, {double density = 1.24}) async {
    _parsingGcode = true;
    _gCodeFileName = fileName;
    _gCodeContentBytes = utf8.encode(content);
    notifyListeners();

    try {
      final metrics = await GCodeParser.parseAsync(content, density: density);
      _gCodeMetrics = metrics;

      if (metrics != null) {
        final hours = metrics.printTimeMinutes ~/ 60;
        final minutes = metrics.printTimeMinutes % 60;
        final formattedTime = '$hours:${minutes.toString().padLeft(2, '0')}';

        _costInputs = _costInputs.copyWith(
          productName: _gCodeParser.productNameFromFileName(fileName),
          modelWeight: metrics.weight.toDouble(),
          printTime: formattedTime,
        );
        _scheduleCalculate();
      }
    } finally {
      _parsingGcode = false;
      notifyListeners();
    }
  }

  Future<List<int>> generateQuotePdf() {
    return _quotePdfService.generate(_quoteData, _currency);
  }

  void applyCloudProfile({
    required CurrencySpec currency,
    required QuoteData quote,
  }) {
    _currency = currency;
    _quoteData = quote;
    notifyListeners();
  }

  void resetSession() {
    _costInputs = CostInputs();
    _taxInputs = TaxInputs();
    _currency = CalculatorConstants.currencies.first;
    _quoteData = QuoteData(
      quoteNumber: _generateQuoteNumber(),
      date: DateTime.now().toIso8601String().split('T').first,
    );
    _results = null;
    _gCodeMetrics = null;
    _gCodeFileName = null;
    _gCodeContentBytes = null;
    _stockAllocations = [];
    _cachedStockItems = [];
    notifyListeners();
  }

  void applySavedCalculation({
    required CostInputs costInputs,
    required TaxInputs taxInputs,
    required CurrencySpec currency,
    CalculationResult? results,
    String? gcodeFileName,
    List<int>? gcodeContent,
  }) {
    _costInputs = costInputs;
    _taxInputs = taxInputs;
    _currency = currency;
    _results = results;
    _gCodeFileName = gcodeFileName;
    _gCodeContentBytes = gcodeContent;

    if (gcodeContent != null && gcodeFileName != null) {
      final content = utf8.decode(gcodeContent);
      _gCodeMetrics = _gCodeParser.parse(content, density: 1.24);
    } else {
      _gCodeMetrics = null;
    }

    notifyListeners();
  }

  void applySavedQuote({
    required QuoteData quote,
    required CurrencySpec currency,
  }) {
    _quoteData = quote;
    _currency = currency;
    notifyListeners();
  }

  void syncEnergyFromProvider(EnergyProvider energy) {
    updateCostField(
      stateEnergy: energy.selectedState,
      customEnergyRate: energy.useCustomRate ? energy.customRate : null,
      clearCustomEnergyRate: !energy.useCustomRate,
      tariffFlag: energy.tariffFlag,
    );
  }
}
