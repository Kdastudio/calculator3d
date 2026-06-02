import '../../core/utils/time_parser.dart';
import '../models/calculator_models.dart';
import 'energy_service.dart';

class CalculatorService {
  CalculatorService({EnergyService? energyService})
      : _energyService = energyService ?? EnergyService();

  final EnergyService _energyService;

  CalculationResult calculatePrintingCost(
    CostInputs inputs, [
    EnergyService? energyService,
  ]) {
    final energy = energyService ?? _energyService;
    final printTimeHours = TimeParser.toHours(inputs.printTime);
    final qty = inputs.batchQuantity.clamp(1, 9999);

    final materialCost = _materialCost(inputs) * qty;
    final energyRate = energy.effectiveRate(
      stateEnergy: inputs.stateEnergy,
      customEnergyRate: inputs.customEnergyRate,
      tariffFlag: inputs.tariffFlag,
    );
    final powerWatt = inputs.printerPower;
    final totalHours = printTimeHours * qty;
    final energyCost = (powerWatt / 1000) * totalHours * energyRate;

    final depreciationCost = inputs.lifespanHours > 0
        ? (inputs.printerValue / inputs.lifespanHours) * totalHours
        : 0.0;

    final postProcessing = inputs.postProcessingCost * qty;
    final extrasTotal = inputs.extras + postProcessing;

    final baseCost = materialCost + energyCost + depreciationCost + extrasTotal;
    final riskCost = baseCost * (inputs.riskPercent / 100);
    var totalCost = baseCost + riskCost;

    final batchDiscount = _batchDiscount(qty, totalCost);
    totalCost -= batchDiscount;

    final margin = inputs.effectiveProfitMargin;
    final finalPrice = totalCost * (1 + margin / 100);
    final profit = finalPrice - totalCost;

    final weight = inputs.totalFilamentWeight * qty;

    return CalculationResult(
      totalCost: totalCost,
      finalPrice: finalPrice,
      totalTaxes: 0,
      unitPrice: qty > 1 ? finalPrice / qty : null,
      details: CostDetails(
        filament: materialCost,
        energy: energyCost,
        depreciation: depreciationCost,
        extras: extrasTotal,
        risk: riskCost,
        profit: profit,
        powerUsed: powerWatt,
        weight: weight,
        hours: totalHours,
        riskPercent: inputs.riskPercent,
        profitMargin: margin,
        postProcessing: postProcessing,
        energyRate: energyRate,
        batchQuantity: qty,
        batchDiscount: batchDiscount,
      ),
    );
  }

  double _materialCost(CostInputs inputs) {
    if (inputs.filaments.isNotEmpty) {
      return inputs.filaments.fold(0.0, (sum, f) => sum + f.cost);
    }
    return (inputs.filamentPrice / 1000) * inputs.modelWeight;
  }

  double _batchDiscount(int qty, double totalCost) {
    if (qty <= 1) return 0;
    final tiers = (qty / 10).floor().clamp(0, 3);
    final percent = tiers * 0.05;
    return totalCost * percent;
  }

  ({double finalPrice, double totalTaxes}) calculatePriceWithTaxes(
    double basePrice,
    TaxInputs taxes,
  ) {
    final totalTaxPercent =
        (taxes.commission + taxes.taxNF + taxes.extraTaxPercent) / 100;

    if (totalTaxPercent >= 1) {
      return (
        finalPrice: basePrice + taxes.fixedFee + taxes.shipping + taxes.extraTaxValue,
        totalTaxes: 0,
      );
    }

    final finalPrice =
        (basePrice + taxes.fixedFee + taxes.shipping + taxes.extraTaxValue) /
            (1 - totalTaxPercent);
    return (finalPrice: finalPrice, totalTaxes: finalPrice - basePrice);
  }

  CalculationResult calculateTotal(
    CostInputs costInputs,
    TaxInputs taxInputs, [
    EnergyService? energyService,
  ]) {
    final costResult = calculatePrintingCost(costInputs, energyService);
    final taxResult = calculatePriceWithTaxes(costResult.finalPrice, taxInputs);

    return CalculationResult(
      totalCost: costResult.totalCost,
      finalPrice: taxResult.finalPrice,
      totalTaxes: taxResult.totalTaxes,
      details: costResult.details,
      unitPrice: costResult.unitPrice != null
          ? taxResult.finalPrice / costResult.details.batchQuantity
          : null,
    );
  }
}
