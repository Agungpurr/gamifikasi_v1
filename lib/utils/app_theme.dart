// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFFF6584);
  static const accent = Color(0xFFFFD166);
  static const success = Color(0xFF06D6A0);
  static const error = Color(0xFFEF476F);
  static const background = Color(0xFFF8F7FF);
  static const cardBg = Colors.white;

  // Subject colors
  static const math = Color(0xFF6C63FF);
  static const bahasa = Color(0xFFFF6584);
  static const ipa = Color(0xFF06D6A0);
  static const ips = Color(0xFFFFD166);

  // Level colors
  static const levelBronze = Color(0xFFCD7F32);
  static const levelSilver = Color(0xFFC0C0C0);
  static const levelGold = Color(0xFFFFD700);
  static const levelPlatinum = Color(0xFF00CED1);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.nunito(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D2D2D),
          ),
          headlineMedium: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
          bodyLarge: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4A4A4A),
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            textStyle: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
}

class AppConstants {
  static const List<Map<String, dynamic>> subjects = [
    {
      'id': 'matematika',
      'name': 'Matematika',
      'emoji': '🔢',
      'color': AppColors.math,
      'description': 'Belajar berhitung, penjumlahan, perkalian',
    },
    {
      'id': 'bahasa',
      'name': 'Bahasa Indonesia',
      'emoji': '📖',
      'color': AppColors.bahasa,
      'description': 'Membaca, menulis, dan tata bahasa',
    },
    {
      'id': 'ipa',
      'name': 'IPA',
      'emoji': '🔬',
      'color': AppColors.ipa,
      'description': 'Ilmu Pengetahuan Alam seru',
    },
    {
      'id': 'ips',
      'name': 'IPS',
      'emoji': '🌏',
      'color': AppColors.ips,
      'description': 'Sejarah, geografi, dan sosial',
    },
    {
      'id': 'bahasa_inggris',
      'name': 'Bahasa Inggris',
      'emoji': '🧩',
      'description': 'Belajar kosakata dan grammar',
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'seni_budaya',
      'name': 'Seni Budaya',
      'emoji': '🎨',
      'description': 'Eksplorasi seni dan budaya',
      'color': Color(0xFFE91E63),
    },
  ];

  static const List<String> grades = ['1', '2', '3', '4', '5', '6'];

  static const List<String> avatars = [
    'avatar_1',
    'avatar_2',
    'avatar_3',
    'avatar_4',
    'avatar_5',
    'avatar_6',
    'avatar_7',
    'avatar_8',
  ];

  static const Map<String, String> avatarEmojis = {
    'avatar_1': '🦁',
    'avatar_2': '🐯',
    'avatar_3': '🐻',
    'avatar_4': '🦊',
    'avatar_5': '🐸',
    'avatar_6': '🐼',
    'avatar_7': '🦄',
    'avatar_8': '🐲',
  };
}
