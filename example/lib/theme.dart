import 'package:flutter/material.dart';

/// The demo's colour palette.
abstract final class AppColors {
  static const background = Color(0xFF050A16);
  static const backgroundTop = Color(0xFF0A1530);
  static const card = Color(0xFF111A2F);
  static const cardBorder = Color(0xFF1D2A47);
  static const blue = Color(0xFF1E8BFF);
  static const green = Color(0xFF00E58A);
  static const red = Color(0xFFFF4757);
  static const amber = Color(0xFFFFC24B);
  static const text = Color(0xFFF4F7FF);
  static const muted = Color(0xFF96A3C0);
}

/// Spacing used for every margin and padding, so screens stay consistent.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  /// Padding around the content of a screen.
  static const screen = EdgeInsets.fromLTRB(xl, lg, xl, xxl);

  /// Padding inside a card.
  static const card = EdgeInsets.all(lg);
}

const double cardRadius = 18;

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.text,
        error: AppColors.red,
      );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.blue.withValues(alpha: 0.18),
      height: 72,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.all(Insets.lg),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
