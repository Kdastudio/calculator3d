import 'package:flutter/material.dart';

abstract final class ColorUtils {
  static Color? fromHex(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    var c = hex.trim().replaceFirst('#', '');
    if (c.length == 6) {
      return Color(int.parse('FF$c', radix: 16));
    }
    if (c.length == 8) {
      return Color(int.parse(c, radix: 16));
    }
    return null;
  }

  static String toHex(Color color) {
    final v = color.toARGB32() & 0xFFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
