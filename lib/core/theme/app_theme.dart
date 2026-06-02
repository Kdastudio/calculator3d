import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/calculator_constants.dart';

/// Paleta premium — slate profundo, menta elétrico, dourado pálido, azul gelo.
class AppTheme {
  AppTheme._();

  static const accent = Color(CalculatorConstants.accentColor);
  static const accentOn = Color(0xFF0A0F14);
  static const accentSoft = Color(0xFF1A2824);
  static const gold = Color(0xFFE8D5A3);
  static const ice = Color(0xFF7EC8E3);

  static const background = Color(CalculatorConstants.backgroundColor);
  static const card = Color(CalculatorConstants.cardColor);
  static const surfaceRaised = Color(0xFF171E28);
  static const surfaceHover = Color(0xFF1E2733);
  static const border = Color(0xFF252D3A);
  static const borderSubtle = Color(0xFF1A212C);

  static const textPrimary = Color(0xFFE8EDF4);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textInput = Color(0xFFF1F5F9);

  static const success = Color(0xFF4FFFB0);
  static const warning = Color(0xFFE8D5A3);
  static const danger = Color(0xFFF87171);
  static const info = Color(0xFF7EC8E3);

  static const quotePaper = Color(0xFFFAFBFC);
  static const quoteInk = Color(0xFF0F172A);
  static const quoteMuted = Color(0xFF64748B);
  static const quoteAccent = Color(0xFF0D9488);

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;

  static const fieldSpacing = 10.0;
  static const sectionSpacing = 20.0;

  static TextStyle _base({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData dark() {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseText.copyWith(
      headlineSmall: _base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      titleLarge: _base(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleMedium: _base(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      bodyMedium: _base(fontSize: 13, height: 1.5, color: textSecondary),
      bodySmall: _base(fontSize: 12, height: 1.45, color: textSecondary),
      labelLarge: _base(fontSize: 13, fontWeight: FontWeight.w500, color: textInput),
      labelSmall: _base(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: textMuted,
      ),
    );

    const colorScheme = ColorScheme.dark(
      primary: accent,
      onPrimary: accentOn,
      secondary: gold,
      surface: card,
      onSurface: textPrimary,
      outline: border,
      surfaceContainerHighest: surfaceRaised,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      colorScheme: colorScheme,
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _base(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        iconTheme: const IconThemeData(color: textSecondary, size: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: _base(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
        floatingLabelStyle: _base(fontSize: 12, color: textSecondary),
        hintStyle: _base(fontSize: 13, color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentOn,
          disabledBackgroundColor: border,
          disabledForegroundColor: textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          minimumSize: const Size(0, 38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: _base(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: BorderSide(color: border.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: _base(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 32),
          textStyle: _base(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: accent.withValues(alpha: 0.14),
        elevation: 0,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _base(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accent : textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accent : textMuted, size: 18);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentOn;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.withValues(alpha: 0.55);
          return border;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      dividerTheme: DividerThemeData(color: border.withValues(alpha: 0.6), thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        selectedColor: accent.withValues(alpha: 0.16),
        labelStyle: _base(fontSize: 12, color: textSecondary),
        side: BorderSide(color: border.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: _base(fontSize: 13, color: textPrimary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: _base(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        unselectedLabelStyle: _base(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        dividerColor: borderSubtle,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: border,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
    );
  }
}
