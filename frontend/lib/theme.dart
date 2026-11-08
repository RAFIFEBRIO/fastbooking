import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const brown = Color(0xFF5C3D2E);
  static const brownDark = Color(0xFF2B1E16);
  static const textMuted = Color(0xFF7A6A5E);
  static const cream = Color(0xFFF7F2EB);
  static const creamSoft = Color(0xFFFBF8F4);
  static const border = Color(0xFFEADFD3);
  static const green = Color(0xFF1E8E4E);
  static const red = Color(0xFFB3261E);
}

/// Gaya judul (serif)
TextStyle heading(double size, {Color color = AppColors.brownDark}) =>
    GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
    );

/// Gaya tulisan tangan (halaman sambutan)
TextStyle script(double size) =>
    GoogleFonts.sacramento(fontSize: size, color: AppColors.brownDark);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brown,
      primary: AppColors.brown,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.brownDark,
      displayColor: AppColors.brownDark,
    ),
  );
}