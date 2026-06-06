import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TaskPriority { high, medium, low }

extension TaskPriorityExt on TaskPriority {
  String get label => ['High', 'Medium', 'Low'][index];
  Color get color => [AppColors.priorityHigh, AppColors.priorityMedium, AppColors.priorityLow][index];
  Color get lightColor => [AppColors.dangerLight, AppColors.warningLight, AppColors.successLight][index];
  IconData get icon => [
        Icons.keyboard_double_arrow_up_rounded,
        Icons.remove_rounded,
        Icons.keyboard_double_arrow_down_rounded,
      ][index];
}

enum TaskCategory { assignment, exam, project, reading, meeting, other }

extension TaskCategoryExt on TaskCategory {
  String get label => ['Assignment', 'Exam', 'Project', 'Reading', 'Meeting', 'Other'][index];
  Color get color => AppColors.categoryColors[index];
  IconData get icon => [
        Icons.assignment_rounded,
        Icons.school_rounded,
        Icons.folder_special_rounded,
        Icons.menu_book_rounded,
        Icons.groups_rounded,
        Icons.more_horiz_rounded,
      ][index];
}

// ─── Colors ───────────────────────────────────────────────────────────────────

class AppColors {
  static const primary      = Color(0xFF6C63FF);
  static const primaryDark  = Color(0xFF4B44CC);
  static const primaryLight = Color(0xFFEEEDFF);
  static const accent       = Color(0xFFFF6584);
  static const accentLight  = Color(0xFFFFEEF2);
  static const success      = Color(0xFF2EC4B6);
  static const successLight = Color(0xFFE8FAF9);
  static const warning      = Color(0xFFFFBF00);
  static const warningLight = Color(0xFFFFF8E1);
  static const danger       = Color(0xFFE63946);
  static const dangerLight  = Color(0xFFFFEBEC);
  static const priorityHigh   = Color(0xFFE63946);
  static const priorityMedium = Color(0xFFFFBF00);
  static const priorityLow    = Color(0xFF2EC4B6);
  static const background   = Color(0xFFF8F7FF);
  static const surface      = Color(0xFFFFFFFF);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textSecondary= Color(0xFF6B7280);
  static const textHint     = Color(0xFFB0B7C3);
  static const divider      = Color(0xFFEEEEF5);
  static const cardShadow   = Color(0x1A6C63FF);
  static const List<Color> categoryColors = [
    Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFF2EC4B6),
    Color(0xFFFFBF00), Color(0xFF4CAF50), Color(0xFFFF9800),
  ];
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold,  color: AppColors.textPrimary),
      headlineMedium:GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold,  color: AppColors.textPrimary),
      titleLarge:    GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
      titleMedium:   GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
      bodyLarge:     GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary),
      bodyMedium:    GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
      labelLarge:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600,  color: AppColors.surface),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 2)),
      hintStyle:  GoogleFonts.poppins(color: AppColors.textHint,      fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
  );
}
