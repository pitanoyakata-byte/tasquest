import 'package:flutter/material.dart';

/// 企画書12章のイメージカラー（黄緑・水色・白を中心とした明るく優しい配色）を
/// ベースにしたテーマ。
ThemeData buildAppTheme() {
  const seedColor = Color(0xFF8BC34A); // 黄緑
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    secondary: const Color(0xFF4FC3F7), // 水色
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF7FBF2),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
  );
}
