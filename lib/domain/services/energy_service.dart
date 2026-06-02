import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/energy_regions.dart';

class EnergyService {
  EnergyService({List<EnergyRegion>? regions}) : _regions = regions ?? EnergyRegion.all;

  List<EnergyRegion> _regions;

  List<EnergyRegion> get regions => List.unmodifiable(_regions);

  EnergyRegion? regionForState(String state) {
    for (final r in _regions) {
      if (r.state == state) return r;
    }
    return EnergyRegion.findByState(state);
  }

  double effectiveRate({
    required String stateEnergy,
    double? customEnergyRate,
    TariffFlag tariffFlag = TariffFlag.none,
  }) {
    final base =
        customEnergyRate ?? regionForState(stateEnergy)?.ratePerKwh ?? 0.90;
    return base + tariffFlag.surchargePerKwh;
  }

  Future<void> loadBundledRates() async {
    try {
      final raw = await rootBundle.loadString('assets/data/energy_rates.json');
      _applyJson(raw);
    } catch (_) {
      _regions = EnergyRegion.all;
    }
  }

  Future<bool> fetchRemoteRates(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      _applyJson(response.body);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _applyJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final states = data['states'] as List<dynamic>? ?? [];
    if (states.isEmpty) return;

    _regions = states
        .map(
          (s) => EnergyRegion(
            state: s['state'] as String,
            uf: s['uf'] as String,
            region: s['region'] as String,
            distributor: s['distributor'] as String,
            ratePerKwh: (s['ratePerKwh'] as num).toDouble(),
          ),
        )
        .toList();
  }
}
