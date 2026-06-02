import 'package:flutter_test/flutter_test.dart';
import 'package:kda3d_calculator/core/constants/energy_regions.dart';
import 'package:kda3d_calculator/domain/models/calculator_models.dart';
import 'package:kda3d_calculator/domain/services/calculator_service.dart';
import 'package:kda3d_calculator/domain/services/energy_service.dart';

void main() {
  late CalculatorService service;
  late EnergyService energy;

  setUp(() {
    energy = EnergyService();
    service = CalculatorService(energyService: energy);
  });

  CostInputs baseInputs({
    double printerPower = 150,
    String printTime = '2:00',
    double? customEnergyRate,
    int batchQuantity = 1,
  }) {
    return CostInputs(
      modelWeight: 0,
      filamentPrice: 0,
      printTime: printTime,
      printerPower: printerPower,
      printerValue: 0,
      lifespanHours: 3000,
      stateEnergy: 'São Paulo',
      customEnergyRate: customEnergyRate,
      batchQuantity: batchQuantity,
    );
  }

  group('Custo de energia', () {
    test('fórmula: (W/1000) × horas × R\$/kWh', () {
      const rate = 0.85;
      final result = service.calculatePrintingCost(
        baseInputs(customEnergyRate: rate),
        energy,
      );

      // 150W × 2h = 0,3 kWh × 0,85 = 0,255
      expect(result.details.energy, closeTo(0.255, 0.001));
      expect(result.details.powerUsed, 150);
      expect(result.details.hours, 2);
      expect(result.details.energyRate, rate);
    });

    test('potência (W) não altera tarifa (R\$/kWh)', () {
      final lowPower = service.calculatePrintingCost(
        baseInputs(printerPower: 120, customEnergyRate: 0.90),
        energy,
      );
      final highPower = service.calculatePrintingCost(
        baseInputs(printerPower: 350, customEnergyRate: 0.90),
        energy,
      );

      expect(lowPower.details.energyRate, highPower.details.energyRate);
      expect(highPower.details.energy, greaterThan(lowPower.details.energy));
      expect(highPower.details.energy / lowPower.details.energy, closeTo(350 / 120, 0.01));
    });

    test('batch multiplica horas, não potência', () {
      final single = service.calculatePrintingCost(
        baseInputs(customEnergyRate: 1.0, batchQuantity: 1),
        energy,
      );
      final batch = service.calculatePrintingCost(
        baseInputs(customEnergyRate: 1.0, batchQuantity: 3),
        energy,
      );

      expect(batch.details.hours, 6);
      expect(batch.details.energy, closeTo(single.details.energy * 3, 0.001));
    });

    test('tarifa regional + bandeira', () {
      final inputs = baseInputs(printTime: '1:00', printerPower: 1000).copyWith(
        tariffFlag: TariffFlag.yellow,
      );
      final rate = energy.effectiveRate(
        stateEnergy: inputs.stateEnergy,
        tariffFlag: inputs.tariffFlag,
      );
      final result = service.calculatePrintingCost(inputs, energy);

      // 1 kW × 1h × tarifa com bandeira amarela
      expect(result.details.energy, closeTo(rate, 0.001));
      expect(result.details.energyRate, rate);
    });
  });
}
