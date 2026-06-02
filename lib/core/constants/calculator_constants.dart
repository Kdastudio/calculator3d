import 'energy_regions.dart';

class PrinterSpec {
  const PrinterSpec({required this.price, required this.power});

  final double price;
  final double power;
}

class CurrencySpec {
  const CurrencySpec({
    required this.code,
    required this.label,
    required this.locale,
    required this.flag,
  });

  final String code;
  final String label;
  final String locale;
  final String flag;
}

class PlatformPreset {
  const PlatformPreset({required this.commission, required this.fixedFee});

  final double commission;
  final double fixedFee;
}


class CalculatorConstants {
  CalculatorConstants._();

  static const accentColor = 0xFF4FFFB0;
  static const backgroundColor = 0xFF0A0F14;
  static const cardColor = 0xFF111820;

  static final Map<String, double> energyRates = EnergyRegion.toLegacyRatesMap();

  static const Map<String, PrinterSpec> popularPrinters = {
    'Creality Ender 3 V3 SE': PrinterSpec(price: 1800, power: 120),
    'Creality Ender 3 V3 KE': PrinterSpec(price: 2350, power: 150),
    'Creality K1': PrinterSpec(price: 4600, power: 350),
    'Creality K1 Max': PrinterSpec(price: 6500, power: 450),
    'Creality Ender 3 S1': PrinterSpec(price: 2200, power: 150),
    'Creality Ender 3 S1 Pro': PrinterSpec(price: 2700, power: 150),
    'Bambu Lab P1S': PrinterSpec(price: 7800, power: 350),
    'Bambu Lab X1-Carbon': PrinterSpec(price: 13800, power: 450),
    'Bambu Lab A1': PrinterSpec(price: 5200, power: 200),
    'Bambu Lab A1 Mini': PrinterSpec(price: 3300, power: 150),
    'Anycubic Kobra 2 Neo': PrinterSpec(price: 1700, power: 150),
    'Anycubic Kobra 2 Pro': PrinterSpec(price: 2500, power: 200),
    'Anycubic Kobra 3': PrinterSpec(price: 1850, power: 250),
    'Anycubic Kobra 3V2': PrinterSpec(price: 2150, power: 280),
    'Anycubic Kobra 3 Max': PrinterSpec(price: 2650, power: 300),
    'Anycubic Kobra S1': PrinterSpec(price: 4400, power: 300),
    'Anycubic Photon Mono M5s': PrinterSpec(price: 4600, power: 100),
    'Anycubic Photon Mono M7 Pro': PrinterSpec(price: 5600, power: 120),
    'Artillery Sidewinder X4 Pro': PrinterSpec(price: 3200, power: 250),
    'Artillery Sidewinder X4 Plus': PrinterSpec(price: 3800, power: 300),
    'Artillery Genius Pro': PrinterSpec(price: 2200, power: 150),
    'Elegoo Neptune 4': PrinterSpec(price: 2500, power: 200),
    'Elegoo Neptune 4 Pro': PrinterSpec(price: 3000, power: 250),
    'Elegoo Mars 4': PrinterSpec(price: 2100, power: 80),
    'Elegoo Saturn 3 Ultra': PrinterSpec(price: 4500, power: 120),
    'Prusa MK4': PrinterSpec(price: 10900, power: 200),
    'Prusa MINI+': PrinterSpec(price: 5900, power: 120),
    'Flashforge Adventurer 5M': PrinterSpec(price: 3600, power: 250),
    'Flashforge Adventurer 5M Pro': PrinterSpec(price: 4700, power: 300),
    'Two Trees Sapphire Pro': PrinterSpec(price: 1850, power: 180),
    'Sovol SV06': PrinterSpec(price: 2300, power: 150),
    'Sovol SV07': PrinterSpec(price: 2700, power: 300),
    'Flying Bear Ghost 6': PrinterSpec(price: 3100, power: 250),
    'Tronxy X5SA': PrinterSpec(price: 2200, power: 200),
    'Outra (Manual)': PrinterSpec(price: 2000, power: 150),
  };

  static const List<CurrencySpec> currencies = [
    CurrencySpec(code: 'BRL', label: 'Real Brasileiro', locale: 'pt_BR', flag: '🇧🇷'),
    CurrencySpec(code: 'USD', label: 'Dólar Americano', locale: 'en_US', flag: '🇺🇸'),
    CurrencySpec(code: 'EUR', label: 'Euro', locale: 'de_DE', flag: '🇪🇺'),
    CurrencySpec(code: 'GBP', label: 'Libra Esterlina', locale: 'en_GB', flag: '🇬🇧'),
    CurrencySpec(code: 'JPY', label: 'Iene Japonês', locale: 'ja_JP', flag: '🇯🇵'),
    CurrencySpec(code: 'CNY', label: 'Yuan Chinês', locale: 'zh_CN', flag: '🇨🇳'),
    CurrencySpec(code: 'AUD', label: 'Dólar Australiano', locale: 'en_AU', flag: '🇦🇺'),
    CurrencySpec(code: 'CAD', label: 'Dólar Canadense', locale: 'en_CA', flag: '🇨🇦'),
  ];

  static const Map<String, PlatformPreset> platformPresets = {
    'Mercado Livre': PlatformPreset(commission: 0, fixedFee: 6),
    'Shopee': PlatformPreset(commission: 0, fixedFee: 3),
    'Amazon': PlatformPreset(commission: 0, fixedFee: 2),
    'Loja Própria': PlatformPreset(commission: 5, fixedFee: 1),
  };

  static const List<String> platforms = [
    'Mercado Livre',
    'Shopee',
    'Amazon',
    'Loja Própria',
  ];

  static const builtinMarketplaces = {'Mercado Livre', 'Shopee', 'Amazon'};

  static bool isBuiltinMarketplace(String platform) =>
      builtinMarketplaces.contains(platform);
}
