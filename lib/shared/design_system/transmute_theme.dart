import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../theme/transmute_palette.dart';
import 'design_tokens.dart';

/// Shared by the application and catalog. Palette = color; style = geometry.
ThemeData buildTransmuteTheme(
  ThemePreference preference, {
  DesignStyle style = DesignStyle.ledger,
}) {
  final palette = TransmutePalette.forPreference(preference);
  final tokens = DesignTokens.forStyle(style);
  final colors = ColorScheme.fromSeed(
    seedColor: palette.oxide,
    brightness: preference.brightness == PreferenceBrightness.dark
        ? Brightness.dark
        : Brightness.light,
    surface: palette.surface,
    onSurface: palette.ink,
    onSurfaceVariant: palette.muted,
    outline: palette.divider,
    primary: palette.oxide,
    secondary: palette.gold,
    error: palette.rest,
  );
  const serif = TextStyle(fontFamily: 'Spectral', fontWeight: FontWeight.bold);
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    useMaterial3: true,
    extensions: [palette, tokens],
    cardTheme: CardThemeData(
      color: palette.raised,
      shape: tokens.shape(palette.divider),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.raised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: tokens.shape(),
        minimumSize: Size(tokens.controlHeight, tokens.controlHeight),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: serif,
      displayMedium: serif,
      displaySmall: TextStyle(
        fontFamily: 'Spectral',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: serif,
      headlineMedium: serif,
      headlineSmall: serif,
      titleLarge: serif,
    ),
  );
}
