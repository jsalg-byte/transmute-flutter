import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  factory CuteCustomStyles.defaults() => const CuteCustomStyles(
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

ThemeData _buildCuteTheme() {
  const pill = StadiumBorder();
  const roundedRectangle = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );
  const inputRadius = BorderRadius.all(Radius.circular(30));
  final customStyles = CuteCustomStyles.defaults();
  final textTheme = GoogleFonts.fredokaTextTheme(ThemeData.light().textTheme)
      .copyWith(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: CuteColors.ink,
          letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: CuteColors.ink,
          letterSpacing: -0.8,
        ),
        displaySmall: GoogleFonts.fredoka(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: CuteColors.ink,
          letterSpacing: -0.6,
        ),
        headlineLarge: GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        headlineSmall: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        titleLarge: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        titleMedium: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        titleSmall: GoogleFonts.fredoka(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: CuteColors.ink,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: CuteColors.ink,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.quicksand(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CuteColors.mutedInk,
          height: 1.35,
        ),
        labelLarge: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        labelMedium: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CuteColors.ink,
        ),
        labelSmall: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CuteColors.mutedInk,
        ),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cuteColorScheme,
    scaffoldBackgroundColor: CuteColors.surface,
    canvasColor: CuteColors.surface,
    textTheme: textTheme,
    extensions: [customStyles],
    appBarTheme: AppBarTheme(
      backgroundColor: CuteColors.surface,
      foregroundColor: CuteColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: CuteColors.ink),
    ),
    cardTheme: CardThemeData(
      color: CuteColors.softWhite,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.all(8),
      shape: roundedRectangle.copyWith(
        side: const BorderSide(color: CuteColors.secondary, width: 1.25),
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
        shadowColor: const WidgetStatePropertyAll(Color(0x33F29191)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: const WidgetStatePropertyAll(CuteColors.onPastel),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return CuteColors.secondary.withValues(alpha: 0.5);
          }
          return CuteColors.primary;
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
              ? CuteColors.accent.withValues(alpha: 0.45)
              : CuteColors.accent;
          return BorderSide(color: color, width: 1.5);
        }),
        foregroundColor: const WidgetStatePropertyAll(CuteColors.ink),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: CuteColors.softWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      hintStyle: textTheme.bodyMedium?.copyWith(color: CuteColors.mutedInk),
      labelStyle: textTheme.bodyMedium?.copyWith(color: CuteColors.mutedInk),
      floatingLabelStyle: textTheme.labelMedium?.copyWith(
        color: CuteColors.onPastel,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: CuteColors.accent, width: 1.25),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: CuteColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: Color(0xFFC7566A), width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: Color(0xFFC7566A), width: 2),
      ),
      disabledBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: Color(0xFFCCFBFA), width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: CuteColors.primary,
      foregroundColor: CuteColors.onPastel,
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 1,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CuteColors.softWhite,
      selectedColor: CuteColors.secondary,
      disabledColor: CuteColors.surface,
      deleteIconColor: CuteColors.mutedInk,
      checkmarkColor: CuteColors.onPastel,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pressElevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      side: const BorderSide(color: CuteColors.accent, width: 1.25),
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelMedium!,
      secondaryLabelStyle: textTheme.labelMedium!,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CuteColors.softWhite,
      elevation: 4,
      shadowColor: const Color(0x26F29191),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CuteColors.softWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: CuteColors.accent,
      thickness: 1,
      space: 1,
    ),
  );
}
