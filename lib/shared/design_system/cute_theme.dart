import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/transmute_palette.dart';

/// Palette sampled from the supplied pastel reference:
/// #F29191, #F7ADAD, #B1E5E6, and #CCFBFA.
abstract final class CuteColors {
  static const primary = Color(0xFFF29191);
  static const secondary = Color(0xFFF7ADAD);
  static const accent = Color(0xFFB1E5E6);
  static const surface = Color(0xFFCCFBFA);

  static const ink = Color(0xFF382D37);
  static const mutedInk = Color(0xFF705D69);
  static const onPastel = Color(0xFF4A2430);
  static const white = Color(0xFFFFFFFF);
  static const softWhite = Color(0xFFFFFAFB);
}

/// Red-green color-blind-safe palette sampled from the supplied reference:
/// #B3589A, #D091BB, #F6D3E8, #E7F7D5, #BBD4A6, and #9BBF85.
///
/// Violet remains the primary visual color. Blue and amber are reserved for
/// semantic status cues so a state is never communicated as red versus green.
abstract final class CuteColorBlindColors {
  static const primary = Color(0xFFB3589A);
  static const secondary = Color(0xFFD091BB);
  static const accent = Color(0xFFBBD4A6);
  static const surface = Color(0xFFE7F7D5);
  static const panel = Color(0xFFF6D3E8);
  static const tertiary = Color(0xFF9BBF85);

  static const ink = Color(0xFF302236);
  static const mutedInk = Color(0xFF655764);
  static const onPastel = Color(0xFF301D31);
  static const white = Color(0xFFFFFFFF);
  static const error = Color(0xFF75456F);
}

/// A light, high-legibility Material color scheme for the cute pastel style.
const cuteColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: CuteColors.primary,
  onPrimary: CuteColors.onPastel,
  primaryContainer: CuteColors.secondary,
  onPrimaryContainer: CuteColors.onPastel,
  secondary: CuteColors.secondary,
  onSecondary: CuteColors.onPastel,
  secondaryContainer: CuteColors.primary,
  onSecondaryContainer: CuteColors.onPastel,
  tertiary: CuteColors.accent,
  onTertiary: CuteColors.ink,
  tertiaryContainer: CuteColors.surface,
  onTertiaryContainer: CuteColors.ink,
  error: Color(0xFFC7566A),
  onError: CuteColors.white,
  errorContainer: Color(0xFFFFD9DE),
  onErrorContainer: Color(0xFF5B1020),
  surface: CuteColors.surface,
  onSurface: CuteColors.ink,
  onSurfaceVariant: CuteColors.mutedInk,
  outline: Color(0xFF91CED0),
  outlineVariant: Color(0xFFADE3E4),
  shadow: Color(0xFF5A4150),
  scrim: Color(0xFF231B22),
  inverseSurface: CuteColors.ink,
  onInverseSurface: CuteColors.softWhite,
  inversePrimary: Color(0xFFFFB7B7),
  surfaceTint: CuteColors.primary,
);

/// The color-blind-safe Cute Pastel scheme. Its primary colors come directly
/// from the supplied alternate palette, while semantic error/status colors are
/// violet, blue, and amber rather than red and green.
const cuteColorBlindColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: CuteColorBlindColors.primary,
  onPrimary: CuteColorBlindColors.onPastel,
  primaryContainer: CuteColorBlindColors.secondary,
  onPrimaryContainer: CuteColorBlindColors.onPastel,
  secondary: CuteColorBlindColors.secondary,
  onSecondary: CuteColorBlindColors.onPastel,
  secondaryContainer: CuteColorBlindColors.panel,
  onSecondaryContainer: CuteColorBlindColors.ink,
  tertiary: CuteColorBlindColors.tertiary,
  onTertiary: CuteColorBlindColors.ink,
  tertiaryContainer: CuteColorBlindColors.accent,
  onTertiaryContainer: CuteColorBlindColors.ink,
  error: CuteColorBlindColors.error,
  onError: CuteColorBlindColors.white,
  errorContainer: Color(0xFFF0DDF4),
  onErrorContainer: Color(0xFF3D2547),
  surface: CuteColorBlindColors.surface,
  onSurface: CuteColorBlindColors.ink,
  onSurfaceVariant: CuteColorBlindColors.mutedInk,
  outline: CuteColorBlindColors.accent,
  outlineVariant: Color(0xFFD4E7C6),
  shadow: Color(0xFF493846),
  scrim: Color(0xFF211722),
  inverseSurface: CuteColorBlindColors.ink,
  onInverseSurface: CuteColorBlindColors.panel,
  inversePrimary: CuteColorBlindColors.secondary,
  surfaceTint: CuteColorBlindColors.primary,
);

/// Non-Material styling tokens used by custom Transmute widgets.
@immutable
class CuteCustomStyles extends ThemeExtension<CuteCustomStyles> {
  const CuteCustomStyles({
    required this.softShadow,
    required this.pressedShadow,
    required this.extraLargeRadius,
    required this.containerGradient,
    required this.accentGradient,
  });

  factory CuteCustomStyles.defaults({bool colorBlindSafe = false}) =>
      colorBlindSafe ? _colorBlindDefaults : _defaults;

  static const _defaults = CuteCustomStyles(
    softShadow: [
      BoxShadow(
        color: Color(0x1FF29191),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
    pressedShadow: [
      BoxShadow(color: Color(0x18B1E5E6), blurRadius: 10, offset: Offset(0, 4)),
    ],
    extraLargeRadius: BorderRadius.all(Radius.circular(32)),
    containerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFAFB), Color(0xFFCCFBFA)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF7ADAD), Color(0xFFF29191)],
    ),
  );

  static const _colorBlindDefaults = CuteCustomStyles(
    softShadow: [
      BoxShadow(
        color: Color(0x1FB3589A),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
    pressedShadow: [
      BoxShadow(color: Color(0x189BBF85), blurRadius: 10, offset: Offset(0, 4)),
    ],
    extraLargeRadius: BorderRadius.all(Radius.circular(32)),
    containerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF6D3E8), Color(0xFFE7F7D5)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD091BB), Color(0xFFB3589A)],
    ),
  );

  final List<BoxShadow> softShadow;
  final List<BoxShadow> pressedShadow;
  final BorderRadius extraLargeRadius;
  final LinearGradient containerGradient;
  final LinearGradient accentGradient;

  @override
  CuteCustomStyles copyWith({
    List<BoxShadow>? softShadow,
    List<BoxShadow>? pressedShadow,
    BorderRadius? extraLargeRadius,
    LinearGradient? containerGradient,
    LinearGradient? accentGradient,
  }) => CuteCustomStyles(
    softShadow: softShadow ?? this.softShadow,
    pressedShadow: pressedShadow ?? this.pressedShadow,
    extraLargeRadius: extraLargeRadius ?? this.extraLargeRadius,
    containerGradient: containerGradient ?? this.containerGradient,
    accentGradient: accentGradient ?? this.accentGradient,
  );

  @override
  CuteCustomStyles lerp(covariant CuteCustomStyles? other, double t) {
    if (other == null) return this;
    return CuteCustomStyles(
      softShadow: _lerpShadows(softShadow, other.softShadow, t),
      pressedShadow: _lerpShadows(pressedShadow, other.pressedShadow, t),
      extraLargeRadius: BorderRadius.lerp(
        extraLargeRadius,
        other.extraLargeRadius,
        t,
      )!,
      containerGradient: LinearGradient.lerp(
        containerGradient,
        other.containerGradient,
        t,
      )!,
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
    );
  }

  static List<BoxShadow> _lerpShadows(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final length = a.length > b.length ? a.length : b.length;
    return List<BoxShadow>.generate(length, (index) {
      final from = index < a.length ? a[index] : const BoxShadow();
      final to = index < b.length ? b[index] : const BoxShadow();
      return BoxShadow.lerp(from, to, t)!;
    });
  }
}

/// A drop-in, tactile pastel theme that is intentionally distinct from the
/// existing ledger-style Transmute theme.
final ThemeData cuteTheme = _buildCuteTheme();
final ThemeData cuteColorBlindTheme = _buildCuteTheme(colorBlindSafe: true);

ThemeData _buildCuteTheme({bool colorBlindSafe = false}) {
  const pill = StadiumBorder();
  const roundedRectangle = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );
  const inputRadius = BorderRadius.all(Radius.circular(30));
  final scheme = colorBlindSafe ? cuteColorBlindColorScheme : cuteColorScheme;
  final primary = scheme.primary;
  final secondary = scheme.secondary;
  final accent = colorBlindSafe
      ? CuteColorBlindColors.accent
      : CuteColors.accent;
  final surface = scheme.surface;
  final panel = colorBlindSafe
      ? CuteColorBlindColors.panel
      : CuteColors.softWhite;
  final ink = scheme.onSurface;
  final mutedInk = scheme.onSurfaceVariant;
  final onPastel = scheme.onPrimary;
  final customStyles = CuteCustomStyles.defaults(
    colorBlindSafe: colorBlindSafe,
  );
  final textTheme = GoogleFonts.fredokaTextTheme(ThemeData.light().textTheme)
      .copyWith(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.8,
        ),
        displaySmall: GoogleFonts.fredoka(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.6,
        ),
        headlineLarge: GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        headlineSmall: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleLarge: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleMedium: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleSmall: GoogleFonts.fredoka(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.quicksand(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: mutedInk,
          height: 1.35,
        ),
        labelLarge: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        labelMedium: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        labelSmall: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: mutedInk,
        ),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    canvasColor: surface,
    textTheme: textTheme,
    extensions: [
      customStyles,
      TransmutePalette.cutePastel(colorBlindSafe: colorBlindSafe),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: ink),
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.all(8),
      shape: roundedRectangle.copyWith(
        side: BorderSide(color: secondary, width: 1.25),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        ),
        shape: const WidgetStatePropertyAll(pill),
        elevation: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? 1 : 3,
        ),
        shadowColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.2)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStatePropertyAll(onPastel),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return secondary.withValues(alpha: 0.5);
          }
          return primary;
        }),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
        shape: const WidgetStatePropertyAll(pill),
        side: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.disabled)
              ? accent.withValues(alpha: 0.45)
              : accent;
          return BorderSide(color: color, width: 1.5);
        }),
        foregroundColor: WidgetStatePropertyAll(ink),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      hintStyle: textTheme.bodyMedium?.copyWith(color: mutedInk),
      labelStyle: textTheme.bodyMedium?.copyWith(color: mutedInk),
      floatingLabelStyle: textTheme.labelMedium?.copyWith(color: onPastel),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: accent, width: 1.25),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: surface, width: 1),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPastel,
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 1,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: panel,
      selectedColor: secondary,
      disabledColor: surface,
      deleteIconColor: mutedInk,
      checkmarkColor: onPastel,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pressElevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      side: BorderSide(color: accent, width: 1.25),
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelMedium!,
      secondaryLabelStyle: textTheme.labelMedium!,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: panel,
      elevation: 4,
      shadowColor: primary.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dividerTheme: DividerThemeData(color: accent, thickness: 1, space: 1),
  );
}
