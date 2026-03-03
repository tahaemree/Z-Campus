import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ───
  static const Color _brandPrimary = Color(0xFF8B2232); // IZU Bordo
  static const Color _brandPrimaryLight = Color(0xFFB5485A); // Lighter variant

  // ─── Light Theme ───
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandPrimary,
      primary: _brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFDADE),
      onPrimaryContainer: const Color(0xFF3F0015),
      secondary: const Color(0xFF765659),
      secondaryContainer: const Color(0xFFFFD9DC),
      tertiary: const Color(0xFF7B5733),
      tertiaryContainer: const Color(0xFFFFDCC3),
      surface: Colors.white,
      onSurface: const Color(0xFF201A1B),
      onSurfaceVariant: const Color(0xFF534344),
      outline: const Color(0xFF857374),
      surfaceContainerLow: const Color(0xFFF8F0F1),
      surfaceContainerHighest: const Color(0xFFEDE0E1),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _brandPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _brandPrimary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: _brandPrimary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _brandPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandPrimary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _brandPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: _brandPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _brandPrimary,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─── Dark Theme ───
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandPrimary,
      brightness: Brightness.dark,
      primary: _brandPrimaryLight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF73192A),
      onPrimaryContainer: const Color(0xFFFFDADE),
      secondary: const Color(0xFFE5BDC0),
      secondaryContainer: const Color(0xFF5C3F42),
      tertiary: const Color(0xFFE6BF9C),
      tertiaryContainer: const Color(0xFF5F401E),
      surface: const Color(0xFF1A1113),
      onSurface: const Color(0xFFF0DEE0),
      onSurfaceVariant: const Color(0xFFD6C2C3),
      outline: const Color(0xFF9E8C8E),
      surfaceContainerLow: const Color(0xFF221A1B),
      surfaceContainerHighest: const Color(0xFF372E2F),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1A1113),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _brandPrimaryLight,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1113),
        indicatorColor: _brandPrimaryLight.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: _brandPrimaryLight,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _brandPrimaryLight,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brandPrimaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _brandPrimaryLight, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF251C1D),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _brandPrimaryLight,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: _brandPrimaryLight,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D2E2F),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _brandPrimaryLight,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandPrimaryLight,
        foregroundColor: Colors.white,
      ),
    );
  }
}
