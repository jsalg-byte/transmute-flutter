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
  final brightness = preference.brightness == PreferenceBrightness.dark
      ? Brightness.dark
      : Brightness.light;
  final colors =
      ColorScheme.fromSeed(
        seedColor: palette.oxide,
        brightness: brightness,
        surface: palette.surface,
      ).copyWith(
        primary: palette.oxide,
        onPrimary: _onColor(palette.oxide, brightness),
        primaryContainer: _tint(palette.oxide, palette.surface, brightness),
        onPrimaryContainer: palette.ink,
        secondary: palette.gold,
        onSecondary: _onColor(palette.gold, brightness),
        secondaryContainer: _tint(palette.gold, palette.surface, brightness),
        onSecondaryContainer: palette.ink,
        tertiary: palette.steel,
        onTertiary: _onColor(palette.steel, brightness),
        tertiaryContainer: _tint(palette.steel, palette.surface, brightness),
        onTertiaryContainer: palette.ink,
        error: palette.rest,
        onError: _onColor(palette.rest, brightness),
        surface: palette.surface,
        onSurface: palette.ink,
        onSurfaceVariant: palette.muted,
        surfaceContainerLowest: palette.raised,
        surfaceContainerLow: palette.raised,
        surfaceContainer: _tint(palette.divider, palette.surface, brightness),
        surfaceContainerHigh: _tint(
          palette.divider,
          palette.raised,
          brightness,
        ),
        surfaceContainerHighest: palette.divider,
        outline: palette.divider,
        outlineVariant: _tint(palette.divider, palette.surface, brightness),
        inverseSurface: palette.ink,
        onInverseSurface: palette.surface,
        shadow: palette.ink,
        surfaceTint: palette.oxide,
      );
  final textTheme = _transmuteTextTheme(palette);
  final shape = tokens.shape(palette.divider);
  final buttonShape = tokens.shape();

  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: palette.surface,
    useMaterial3: true,
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    cardTheme: CardThemeData(
      color: palette.raised,
      surfaceTintColor: Colors.transparent,
      shadowColor: palette.oxide.withValues(alpha: .16),
      elevation: tokens.panelElevation,
      margin: EdgeInsets.zero,
      shape: shape,
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(
      color: palette.divider,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(color: palette.muted, size: 22),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        shape: WidgetStatePropertyAll(tokens.shape()),
        animationDuration: DesignMotion.standard,
        overlayColor: WidgetStatePropertyAll(
          colors.primary.withValues(alpha: .10),
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: .24),
      selectionHandleColor: colors.primary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.raised,
      indicatorColor: colors.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          color: selected ? colors.primary : palette.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colors.primary : palette.muted,
          size: 24,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: colors.primaryContainer,
      selectedIconTheme: IconThemeData(color: colors.primary, size: 24),
      unselectedIconTheme: IconThemeData(color: palette.muted, size: 24),
      selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: colors.primary,
      ),
      unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: palette.muted,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return palette.muted;
        return states.contains(WidgetState.selected)
            ? colors.onPrimary
            : palette.raised;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.divider.withValues(alpha: .5);
        }
        return states.contains(WidgetState.selected)
            ? colors.primary
            : palette.divider;
      }),
      trackOutlineColor: WidgetStatePropertyAll(palette.divider),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.raised,
      labelStyle: TextStyle(color: palette.muted),
      hintStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignSpace.lg,
        vertical: DesignSpace.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        borderSide: BorderSide(color: palette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        borderSide: BorderSide(color: palette.oxide, width: tokens.focusWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        borderSide: BorderSide(color: colors.error, width: tokens.focusWidth),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        borderSide: BorderSide(color: palette.divider.withValues(alpha: .55)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _buttonStyle(
        shape: buttonShape,
        colors: colors,
        height: tokens.controlHeight,
        background: colors.primary,
        foreground: colors.onPrimary,
        elevation: tokens.panelElevation,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle(
        shape: buttonShape,
        colors: colors,
        height: tokens.controlHeight,
        background: Colors.transparent,
        foreground: colors.primary,
        border: palette.divider,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _buttonStyle(
        shape: buttonShape,
        colors: colors,
        height: tokens.controlHeight,
        background: Colors.transparent,
        foreground: colors.primary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: tokens.panelElevation,
      shape: buttonShape,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.raised,
      selectedColor: colors.primaryContainer,
      disabledColor: palette.divider.withValues(alpha: .4),
      secondarySelectedColor: colors.secondaryContainer,
      labelStyle: textTheme.labelLarge!,
      secondaryLabelStyle: textTheme.labelLarge!.copyWith(
        color: colors.onSecondaryContainer,
      ),
      side: BorderSide(color: palette.divider),
      shape: buttonShape,
      padding: const EdgeInsets.symmetric(horizontal: DesignSpace.sm),
      showCheckmark: true,
      checkmarkColor: colors.onPrimaryContainer,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: palette.divider,
      circularTrackColor: palette.divider,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: tokens.shape(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.raised,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radius == 0 ? 0 : tokens.radius * 1.5),
        ),
      ),
    ),
    extensions: [palette, tokens],
  );
}

TextTheme _transmuteTextTheme(TransmutePalette palette) {
  final primary = palette.ink;
  const display = TextStyle(
    fontFamily: 'Spectral',
    fontWeight: FontWeight.bold,
    height: 1.12,
    letterSpacing: -.25,
  );
  const title = TextStyle(fontWeight: FontWeight.w700, height: 1.2);
  const body = TextStyle(height: 1.45, letterSpacing: .05);
  const label = TextStyle(fontWeight: FontWeight.w600, height: 1.2);
  return TextTheme(
    displayLarge: display.copyWith(fontSize: 57, color: primary),
    displayMedium: display.copyWith(fontSize: 45, color: primary),
    displaySmall: display.copyWith(fontSize: 36, color: primary),
    headlineLarge: display.copyWith(fontSize: 32, color: primary),
    headlineMedium: display.copyWith(fontSize: 28, color: primary),
    headlineSmall: display.copyWith(fontSize: 24, color: primary),
    titleLarge: display.copyWith(fontSize: 22, color: primary),
    titleMedium: title.copyWith(fontSize: 16, color: primary),
    titleSmall: title.copyWith(fontSize: 14, color: primary),
    bodyLarge: body.copyWith(fontSize: 16, color: primary),
    bodyMedium: body.copyWith(fontSize: 14, color: primary),
    bodySmall: body.copyWith(fontSize: 12, color: primary),
    labelLarge: label.copyWith(fontSize: 14, color: primary),
    labelMedium: label.copyWith(fontSize: 12, color: primary),
    labelSmall: label.copyWith(fontSize: 11, color: primary),
  );
}

ButtonStyle _buttonStyle({
  required OutlinedBorder shape,
  required ColorScheme colors,
  required double height,
  required Color background,
  required Color foreground,
  Color? border,
  double elevation = 0,
}) => ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(height, height)),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: DesignSpace.lg, vertical: DesignSpace.sm),
  ),
  shape: WidgetStatePropertyAll(shape),
  animationDuration: DesignMotion.standard,
  enableFeedback: true,
  backgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return colors.onSurface.withValues(alpha: .08);
    }
    if (states.contains(WidgetState.pressed) &&
        background != Colors.transparent) {
      return Color.alphaBlend(
        colors.onSurface.withValues(alpha: .08),
        background,
      );
    }
    return background;
  }),
  foregroundColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.disabled)
        ? colors.onSurface.withValues(alpha: .38)
        : foreground,
  ),
  side: border == null
      ? null
      : WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? border.withValues(alpha: .4)
                : states.contains(WidgetState.focused)
                ? colors.primary
                : border,
            width: states.contains(WidgetState.focused) ? 2 : 1,
          ),
        ),
  elevation: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.disabled) ? 0 : elevation,
  ),
  overlayColor: WidgetStatePropertyAll(colors.primary.withValues(alpha: .10)),
  shadowColor: WidgetStatePropertyAll(colors.primary.withValues(alpha: .18)),
  tapTargetSize: MaterialTapTargetSize.padded,
);

Color _onColor(Color color, Brightness _) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
    ? Colors.white
    : const Color(0xFF171821);

Color _tint(Color tint, Color base, Brightness brightness) => Color.alphaBlend(
  tint.withValues(alpha: brightness == Brightness.dark ? .18 : .14),
  base,
);
