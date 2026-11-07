import 'package:flutter/material.dart';

/// Allô Coursier colors — same tokens as the Next.js web app (`globals.css`).
class AppColors {
  static const Color brand = Color(0xFF6D4C41);
  static const Color brandDark = Color(0xFF5D4037);
  static const Color tan = Color(0xFFD2B48C);
  static const Color beige = Color(0xFFF5F5DC);
  static const Color cream = Color(0xFFF5F1E7);
  static const Color field = Color(0xFFEDE0C8);
  static const Color espresso = Color(0xFF3E2723);
  static const Color mocha = Color(0xFF4E342E);
  static const Color copper = Color(0xFFB87333);
  static const Color border = Color(0xFFE3D5BD);

  static const Color primary = brand;
  static const Color primaryLight = tan;
  static const Color primaryDark = brandDark;

  static const Color accent = espresso;
  static const Color accentLight = mocha;
  static const Color accentDark = espresso;

  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color updateBlue = Color(0xFF2563EB);
  static const Color avatarFill = Color(0xFFD7CCC8);
  static const Color info = Color(0xFF8E24AA);
  static const Color depot = Color(0xFF1E88E5);
  static const Color relivrer = Color(0xFFFF5252);

  static const Color bgLight = beige;
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color surface = cream;

  static const Color textDark = espresso;
  static const Color textMedium = Color(0xFF6D5F57);
  static const Color textLight = Color(0xFFB0A398);

  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [brand, brandDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAccent = LinearGradient(
    colors: [espresso, mocha],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class WebSurfaces {
  static BoxDecoration card({double radius = 12}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      tertiary: AppColors.primaryLight,
      surface: AppColors.bgLight,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgLight,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      // Tabs in AppBars: selected primary would match brand bg.
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.tan,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.bgWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: const TextStyle(color: AppColors.textMedium),
        hintStyle: const TextStyle(color: AppColors.textLight),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.tan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.textMedium,
        elevation: 0,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMedium,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.textLight,
        thickness: 1,
        space: 16,
      ),
    );
  }

  // Status to color mapping
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en route':
      case 'en_route':
        return AppColors.info;
      case 'livré':
      case 'livre':
      case 'livrer':
      case 'delivered':
      case 'payé':
      case 'paye':
        return AppColors.success;
      case 'en cours':
      case 'en_cours':
      case 'pending':
        return AppColors.warning;
      case 'en dépôt':
      case 'en_depot':
      case 'at_depot':
        return AppColors.depot;
      case 'relivrer':
      case 're_delivery':
        return AppColors.relivrer;
      case 'annulé':
      case 'annuler':
      case 'annule':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }
}
