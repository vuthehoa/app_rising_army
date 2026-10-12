import 'package:flutter/material.dart';

/// Hệ thống thiết kế "Rising Army": giấy da tối, gỗ, đồng thau, xanh rêu và đỏ máu.
class Pal {
  static const bg = Color(0xFF17120E);
  static const panel = Color(0xFF261D15);
  static const panelHi = Color(0xFF35281C);
  static const line = Color(0xFF4A3826);
  static const gold = Color(0xFFD9A441);
  static const goldDim = Color(0xFF9C7A32);
  static const blood = Color(0xFFC0503E);
  static const moss = Color(0xFF7BA05B);
  static const steel = Color(0xFF8FA3B3);
  static const text = Color(0xFFF1E7D2);
  static const dim = Color(0xFFA99B84);
  static const parchment = Color(0xFFD8C39A);
  static const ink = Color(0xFF2B2016);
}

const serif = 'Georgia';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Pal.gold,
    brightness: Brightness.dark,
    primary: Pal.gold,
    secondary: Pal.moss,
    error: Pal.blood,
    surface: Pal.panel,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Pal.bg,
    dialogTheme: DialogThemeData(
      backgroundColor: Pal.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Pal.line, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontFamily: serif,
        fontWeight: FontWeight.w700,
        color: Pal.text,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        fontFamily: serif,
        fontWeight: FontWeight.w700,
        color: Pal.text,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(color: Pal.text, fontSize: 13, height: 1.3),
      bodySmall: TextStyle(color: Pal.dim, fontSize: 11.5, height: 1.25),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Pal.panelHi,
      contentTextStyle: const TextStyle(color: Pal.text, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Pal.gold),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 300),
    ),
  );
}
