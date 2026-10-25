import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Colores que cambian entre modo claro y oscuro.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.ink,
    required this.muted,
    required this.bg,
    required this.card,
    required this.field,
    required this.border,
  });

  final Color primary;
  final Color primaryDark;
  final Color ink;
  final Color muted;
  final Color bg;
  final Color card;
  final Color field;
  final Color border;

  static const light = AppPalette(
    primary: Color(0xFF1B5E3F), // Selva: botones y títulos
    primaryDark: Color(0xFF143F2B),
    ink: Color(0xFF10231A),
    muted: Color(0xFF66766D),
    bg: Color(0xFFF2F2F1),
    card: Colors.white,
    field: Color(0xFFF1F4F2),
    border: Color(0xFFE1E5E2),
  );

  /// Modo oscuro: la selva de noche.
  static const dark = AppPalette(
    primary: Color(0xFF2E9E6B),
    primaryDark: Color(0xFF6CC79A),
    ink: Color(0xFFE6EFE9),
    muted: Color(0xFF94A69B),
    bg: Color(0xFF0B1712),
    card: Color(0xFF13231B),
    field: Color(0xFF1A2E24),
    border: Color(0xFF233A2E),
  );

  static AppPalette of(Brightness b) => b == Brightness.dark ? dark : light;
}

class AppColors {
  /// Paleta en uso; la actualiza [DeliveryApp] según el tema.
  static AppPalette palette = AppPalette.light;
  static bool get isDark => identical(palette, AppPalette.dark);

  // Paleta "Selva", la misma del colibrí.
  static Color get primary => palette.primary;
  static const quinde = Color(0xFF2E9E6B); // Quinde: color principal del ave
  static Color get primaryDark => palette.primaryDark;
  static const primaryLight = Color(0xFFA8E6C1); // Brote: fondos suaves
  static const cyan = Color(0xFF1F7A8C);
  static const cyanLight = Color(0xFFA8E6C1);
  static const accent = Color(0xFFF2705E); // Coral: el pecho del colibrí
  static const gold = Color(0xFFD9A441); // detalles premium: estrellas, insignias
  static const night = Color(0xFF10231A); // Tinta
  static Color get ink => palette.ink;
  static Color get muted => palette.muted;
  static Color get bg => palette.bg;
  static Color get card => palette.card;
  static Color get field => palette.field;
  static Color get border => palette.border;

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
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? .35 : .06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? .2 : .04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
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

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final p = AppPalette.of(brightness);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: AppColors.quinde,
      primary: p.primary,
      secondary: AppColors.cyan,
      tertiary: AppColors.accent,
      secondaryContainer: AppColors.primaryLight,
      surface: p.card,
    ),
    scaffoldBackgroundColor: p.bg,
  );

  final text = GoogleFonts.outfitTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink);

  final radius = BorderRadius.circular(16);

  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
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
        side: BorderSide(color: p.border, width: 1.4),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: p.primary, width: 1.6),
      ),
      prefixIconColor: p.muted,
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: p.border),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: BorderSide(color: p.border),
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    switchTheme: SwitchThemeData(trackOutlineColor: WidgetStateProperty.all(Colors.transparent)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      elevation: 0,
      height: 68,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.primary.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.primary : p.muted)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: s.contains(WidgetState.selected) ? p.primary : p.muted),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
  );
}
