import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Principios de Nordic Glassmorphism (Modo Oscuro)
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const surfaceVariant = Color(0xFF334155);
  static const glassBorder = Color(0x3394A3B8);
  static const glassBorderBright = Color(0x6694A3B8);
  
  // Modo Claro (Refinado)
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Colors.white;
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
  static const lightGlassBorder = Color(0xFFE2E8F0);
  
  // Identidad
  static const primaryBlue = Color(0xFF6366F1);
  static const primaryBlueGlow = Color(0x666366F1);
  static const accentSage = Color(0xFF10B981);
  static const accentAmber = Color(0xFFF59E0B);
  
  // Texto
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextMuted = Color(0xFF94A3B8);

  // Aliases para compatibilidad
  static const neonBlue = primaryBlue;
  static const neonBlueGlow = primaryBlueGlow;
}

class AppTheme {
  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseBackground = isDark ? AppColors.background : AppColors.lightBackground;
    final baseSurface = isDark ? AppColors.surface : AppColors.lightSurface;
    final baseText = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final baseSecondaryText = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: baseBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: brightness,
        surface: baseSurface,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayMedium: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: baseText),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: baseText),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: baseText),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: baseSecondaryText),
      ),
      cardTheme: CardTheme(
        color: baseSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariant.withOpacity(0.3) : AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 13),
        labelStyle: monoTextStyle.copyWith(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: baseSurface,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.textMuted : AppColors.lightTextMuted),
          );
        }),
      ),
    );
  }

  static TextStyle get monoTextStyle => GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.w500,
  );
}
