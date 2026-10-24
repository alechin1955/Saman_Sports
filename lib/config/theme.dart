import 'package:flutter/material.dart';

class UnimetTheme {
  // Colores principales (Design System UNIMET)
  static const Color primaryOrange = Color(0xFFE85D04);
  static const Color secondaryNavy = Color(0xFF1D2D44);
  static const Color background = Color(0xFFF8F9FA);
  
  // Colores semánticos (Estados de disponibilidad)
  static const Color statusAvailable = Color(0xFF2A9D8F);
  static const Color statusLimited = Color(0xFFE76F51);
  static const Color statusFull = Color(0xFFE63946);

  // Configuración global del tema para la aplicación (main.dart)
  static ThemeData get themeData {
    return ThemeData(
      // Tipografía institucional
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
      primaryColor: primaryOrange,
      
      // Esquema de colores
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: secondaryNavy,
        background: background,
      ),
      
      // Estilo global de la barra de navegación superior (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryNavy,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      
      // Estilo global de los botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Estilo global del botón flotante
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}