import 'package:flutter/foundation.dart';

import '../../core/constants/energy_regions.dart';
import '../../domain/services/energy_service.dart';

class EnergyProvider extends ChangeNotifier {
  EnergyProvider({EnergyService? energyService})
      : _service = energyService ?? EnergyService();

  final EnergyService _service;

  String _selectedState = 'São Paulo';
  String? _selectedRegionFilter;
  double? _customRate;
  TariffFlag _tariffFlag = TariffFlag.none;
  bool _useCustomRate = false;
  bool _loading = false;

  String get selectedState => _selectedState;
  String? get selectedRegionFilter => _selectedRegionFilter;
  double? get customRate => _customRate;
  TariffFlag get tariffFlag => _tariffFlag;
  bool get useCustomRate => _useCustomRate;
  bool get isLoading => _loading;

  List<EnergyRegion> get regions => _service.regions;

  List<EnergyRegion> get filteredRegions {
    if (_selectedRegionFilter == null) return regions;
    return regions.where((r) => r.region == _selectedRegionFilter).toList();
  }

  EnergyRegion? get selectedRegion => _service.regionForState(_selectedState);

  double get effectiveRate => _service.effectiveRate(
        stateEnergy: _selectedState,
        customEnergyRate: _useCustomRate ? _customRate : null,
        tariffFlag: _tariffFlag,
      );

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    await _service.loadBundledRates();
    _loading = false;
    notifyListeners();
  }

  void setState(String state) {
    _selectedState = state;
    notifyListeners();
  }

  void setRegionFilter(String? region) {
    _selectedRegionFilter = region;
    _ensureSelectedStateInFilter();
    notifyListeners();
  }

  void _ensureSelectedStateInFilter() {
    final filtered = filteredRegions;
    if (filtered.isEmpty) return;
    final valid = filtered.any((r) => r.state == _selectedState);
    if (!valid) _selectedState = filtered.first.state;
  }

  String? get dropdownStateValue {
    final filtered = filteredRegions;
    if (filtered.isEmpty) return null;
    if (filtered.any((r) => r.state == _selectedState)) return _selectedState;
    return filtered.first.state;
  }

  void setCustomRate(double? rate, {required bool enabled}) {
    _useCustomRate = enabled;
    _customRate = rate;
    notifyListeners();
  }

  void setTariffFlag(TariffFlag flag) {
    _tariffFlag = flag;
    notifyListeners();
  }

  void applyFromCostInputs({
    required String stateEnergy,
    double? customEnergyRate,
    required TariffFlag tariffFlag,
  }) {
    _selectedState = stateEnergy;
    _customRate = customEnergyRate;
    _useCustomRate = customEnergyRate != null;
    _tariffFlag = tariffFlag;
    notifyListeners();
  }
}
