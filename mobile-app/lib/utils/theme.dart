import 'package:flutter/material.dart';

// ── Colores del sistema ──────────────────────────────────────────────────────
class AppColors {
  static const Color darkBg       = Color(0xFF0D1117);
  static const Color darkSurface  = Color(0xFF161B22);
  static const Color darkCard     = Color(0xFF1F2733);
  static const Color darkBorder   = Color(0xFF30363D);

  static const Color primary      = Color(0xFF00D084);   // verde institucional
  static const Color primaryLight = Color(0xFF00E891);
  static const Color primaryDark  = Color(0xFF00A065);

  static const Color accent       = Color(0xFF58A6FF);   // azul para empresa
  static const Color accentLight  = Color(0xFF79C0FF);

  static const Color textPrimary  = Color(0xFFE6EDF3);
  static const Color textSecondary= Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF484F58);

  static const Color statusAccepted = Color(0xFF00D084);
  static const Color statusPending  = Color(0xFFF0B429);
  static const Color statusRejected = Color(0xFFF85149);
  static const Color statusPartial  = Color(0xFF58A6FF);

  static const Color bottomBar    = Color(0xFF161B22);
}

// ── Estilos de texto ─────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.5,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0,
  );
  static const TextStyle chipLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent,
  );
  static const TextStyle company = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.8,
  );
}

// ── Tema global ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.darkSurface,
      onPrimary: AppColors.darkBg,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      titleTextStyle: AppTextStyles.heading2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bottomBar,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
    fontFamily: 'Roboto',
  );
}