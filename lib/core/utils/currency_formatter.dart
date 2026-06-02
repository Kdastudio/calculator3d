import 'package:intl/intl.dart';

import '../constants/calculator_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double? value, CurrencySpec currency) {
    if (value == null || value.isNaN) return '-';
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: _symbolFor(currency.code),
      decimalDigits: currency.code == 'JPY' ? 0 : 2,
    );
    return formatter.format(value);
  }

  static double parse(String? text) {
    if (text == null || text.trim().isEmpty) return 0;
    final cleaned = text.replaceAll(RegExp(r'[^0-9,.-]'), '').trim();
    if (cleaned.isEmpty) return 0;

    final decimalSeparator = cleaned.contains(',') ? ',' : '.';
    String normalized = cleaned;
    if (decimalSeparator == ',') {
      normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = cleaned.replaceAll(',', '');
    }

    final value = double.tryParse(normalized);
    return value ?? 0;
  }

  static CurrencySpec currencyForCode(String code) {
    return CalculatorConstants.currencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CalculatorConstants.currencies.first,
    );
  }

  static String _symbolFor(String code) {
    switch (code) {
      case 'BRL':
        return 'R\$';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      default:
        return code;
    }
  }
}
