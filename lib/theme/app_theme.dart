import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Orange + White palette
  static const Color primary = Color(0xFFE67E22);        // Warm orange
  static const Color primaryDark = Color(0xFFD35400);     // Deep orange
  static const Color primaryLight = Color(0xFFF39C12);    // Light amber
  static const Color accent = Color(0xFF2C3E50);          // Dark charcoal (contrast)
  static const Color surface = Color(0xFFFFFFFE);         // Pure white
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFFDF6EE);         // Warm off-white
  static const Color textDark = Color(0xFF2C3E50);        // Charcoal
  static const Color textMuted = Color(0xFF7F8C8D);       // Muted grey
  static const Color positive = Color(0xFF27AE60);        // Green
  static const Color negative = Color(0xFFE74C3C);        // Red
  static const Color border = Color(0xFFE8E0D8);          // Warm grey border

  // Legacy aliases
  static const Color primaryBlue = primary;
  static const Color darkBlue = primaryDark;
  static const Color lightBlue = primaryLight;
  static const Color accentOrange = primaryLight;
  static const Color successGreen = positive;
  static const Color errorRed = negative;
  static const Color backgroundWhite = surface;
  static const Color cardGrey = cardAlt;
  static const Color textPrimary = textDark;
  static const Color textSecondary = textMuted;
}

class AppGradients {
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryLight],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryDark, AppColors.primary],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        error: AppColors.negative,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.negative),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }
}
