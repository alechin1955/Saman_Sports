import 'package:flutter/material.dart';

class UnimetTheme {
  // Colores principales (Design System)
  static const Color primaryOrange = Color(0xFFE85D04);
  static const Color navyBlue = Color(0xFF1D2D44);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  // Colores Semánticos (Cupos y Estados)
  static const Color statusAvailable = Color(0xFF2A9D8F); // Verde
  static const Color statusLimited = Color(0xFFE76F51);   // Naranja
  static const Color statusFull = Color(0xFFE63946);      // Rojo
  static const Color statusActive = Color(0xFF2A9D8F);    // Activo
  static const Color statusInactive = Color(0xFF6C757D);  // Inactivo

  // Superficies y Textos
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1D2D44);
  static const Color textSecondary = Color(0xFF6C757D);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: navyBlue,
        surface: cardBackground,
        error: statusFull,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}