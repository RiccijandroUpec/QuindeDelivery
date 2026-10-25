import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppColors {
  // Paleta "Selva", la misma del colibrí.
  static const primary = Color(0xFF1B5E3F); // Selva: botones y títulos
  static const quinde = Color(0xFF2E9E6B); // Quinde: color principal del ave
  static const primaryDark = Color(0xFF143F2B);
  static const primaryLight = Color(0xFFA8E6C1); // Brote: fondos suaves
  static const cyan = Color(0xFF1F7A8C);
  static const cyanLight = Color(0xFFA8E6C1);
  static const accent = Color(0xFFF2705E); // Coral: el pecho del colibrí
  static const gold = Color(0xFFD9A441); // detalles premium: estrellas, insignias
  static const night = Color(0xFF10231A); // Tinta
  static const ink = Color(0xFF10231A);
  static const muted = Color(0xFF66766D);
  static const bg = Color(0xFFF2F2F1);
  static const card = Colors.white;
  static const border = Color(0xFFE1E5E2);

  /// Paleta de los fondos de polígonos: de la tinta al verde quinde.
  static const poly = [
    Color(0xFF0B1A12),
    Color(0xFF10231A),
    Color(0xFF143F2B),
    Color(0xFF1B5E3F),
    Color(0xFF22744F),
    Color(0xFF2E9E6B),
    Color(0xFF1B5E3F),
  ];

  /// Degradado de marca para botones y acentos.
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF1B5E3F), Color(0xFF2E9E6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sombra suave usada en tarjetas flotantes.
  static final softShadow = [
    BoxShadow(color: const Color(0xFF0B1A1E).withValues(alpha: .06), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: const Color(0xFF0B1A1E).withValues(alpha: .04), blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static Color fromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  static Color status(String s) => switch (s) {
        'pendiente' => accent,
        'aceptado' || 'preparando' => cyan,
        'listo' || 'en_camino' => primary,
        'entregado' => primaryDark,
        'cancelado' => const Color(0xFFDC2626),
        _ => muted,
      };
}

/// Ecuador usa dólares con formato $1.50
final money = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.cyan,
      tertiary: AppColors.accent,
      secondaryContainer: AppColors.primaryLight,
      surface: AppColors.card,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );

  final text = GoogleFonts.outfitTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  final radius = BorderRadius.circular(16);

  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.3),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        elevation: 0,
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: .2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F4F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      prefixIconColor: AppColors.muted,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppColors.border)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: const BorderSide(color: AppColors.border),
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 68,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
  );
}
