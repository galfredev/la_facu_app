import 'package:flutter/material.dart';
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

  // Colores para Materias y Tareas (Pastel Premium)
  static const pastelBlue = Color(0xFF4DAAFF);
  static const pastelBlueGlow = Color(0x664DAAFF);
  static const pastelPurple = Color(0xFF9B6DFF);
  static const pastelPurpleGlow = Color(0x669B6DFF);
  static const pastelGreen = Color(0xFF00E5FF);
  static const pastelGreenGlow = Color(0x6600E5FF);
  static const pastelPink = Color(0xFFFF6B9D);
  static const pastelPinkGlow = Color(0x66FF6B9D);
  static const pastelOrange = Color(0xFFFFB347);
  static const pastelOrangeGlow = Color(0x66FFB347);
  static const accentRed = Color(0xFFFF4B4B);

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
  static const neonPurple = pastelPurple;
  static const neonPurpleGlow = pastelPurpleGlow;
  static const neonGreen = pastelGreen;
  static const neonGreenGlow = pastelGreenGlow;
  static const neonAmber = accentAmber;

  // Listas de colores para selectores
  static const subjectColors = [
    pastelBlue,
    pastelPurple,
    pastelGreen,
    pastelPink,
    pastelOrange,
    accentSage,
  ];

  static const lightSubjectColors = [
    pastelBlue,
    pastelPurple,
    pastelGreen,
    pastelPink,
    pastelOrange,
    accentSage,
  ];
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
      textTheme: GoogleFonts.outfitTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: baseText, letterSpacing: -1),
        displayMedium: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: baseText, letterSpacing: -0.5),
        displaySmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: baseText),
        headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: baseText),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: baseText),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: baseText),
        titleSmall: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: baseText),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: baseText),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: baseSecondaryText),
        labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: baseText),
      ),
      cardTheme: CardThemeData(
        color: baseSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariant.withValues(alpha: 0.3) : AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.outfit(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIconColor: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: baseSurface,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.15),
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
