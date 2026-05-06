import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF1A8FE3);
  static const primaryDark = Color(0xFF0D6EBF);
  static const secondary = Color(0xFF26D0CE);
  static const accent = Color(0xFFFF6B6B);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const background = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF718096);

  static final List<Color> pillColors = [
    const Color(0xFF1A8FE3),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFF26D0CE),
    const Color(0xFFFF6B6B),
    const Color(0xFF3F51B5),
  ];

  static Color colorFromHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
          headlineMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary),
          titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
          titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
          bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
          labelLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: surface),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 2,
          centerTitle: false,
          titleTextStyle: GoogleFonts.nunito(
            fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: surface,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: GoogleFonts.nunito(fontSize: 16, color: textSecondary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}
