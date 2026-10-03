import 'package:flutter/material.dart';

/// Presentation, independent of the account's color palette and brightness.
enum DesignStyle { ledger, soft }

abstract final class DesignSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Shared timing for brief, interruptible feedback. Longer choreography stays
/// with the feature that owns the interaction.
abstract final class DesignMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration standard = Duration(milliseconds: 180);
  static const Duration deliberate = Duration(milliseconds: 260);
  static const Curve curve = Curves.easeOutCubic;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// One place for component geometry. New styles do not need feature forks.
class DesignTokens extends ThemeExtension<DesignTokens> {
  const DesignTokens({
    this.radius = 0,
    this.panelPadding = 16,
    this.controlHeight = 44,
    this.borderWidth = 1,
    this.rowMinHeight = 56,
    this.panelElevation = 0,
    this.focusWidth = 2,
  });

  static const ledger = DesignTokens();
  static const soft = DesignTokens(
    radius: 16,
    panelPadding: 20,
    controlHeight: 48,
    rowMinHeight: 60,
    panelElevation: 2,
  );

  static DesignTokens forStyle(DesignStyle style) => switch (style) {
    DesignStyle.ledger => ledger,
    DesignStyle.soft => soft,
  };

  static DesignTokens of(BuildContext context) =>
      Theme.of(context).extension<DesignTokens>() ?? ledger;

  final double radius;
  final double panelPadding;
  final double controlHeight;
  final double borderWidth;
  final double rowMinHeight;
  final double panelElevation;
  final double focusWidth;

  RoundedRectangleBorder shape([Color? border]) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: border == null
        ? BorderSide.none
        : BorderSide(color: border, width: borderWidth),
  );

  @override
  DesignTokens copyWith({
    double? radius,
    double? panelPadding,
    double? controlHeight,
    double? borderWidth,
    double? rowMinHeight,
    double? panelElevation,
    double? focusWidth,
  }) => DesignTokens(
    radius: radius ?? this.radius,
    panelPadding: panelPadding ?? this.panelPadding,
    controlHeight: controlHeight ?? this.controlHeight,
    borderWidth: borderWidth ?? this.borderWidth,
    rowMinHeight: rowMinHeight ?? this.rowMinHeight,
    panelElevation: panelElevation ?? this.panelElevation,
    focusWidth: focusWidth ?? this.focusWidth,
  );

  @override
  DesignTokens lerp(covariant DesignTokens? other, double t) {
    if (other == null) return this;
    double mix(double a, double b) => a + (b - a) * t;
    return DesignTokens(
      radius: mix(radius, other.radius),
      panelPadding: mix(panelPadding, other.panelPadding),
      controlHeight: mix(controlHeight, other.controlHeight),
      borderWidth: mix(borderWidth, other.borderWidth),
      rowMinHeight: mix(rowMinHeight, other.rowMinHeight),
      panelElevation: mix(panelElevation, other.panelElevation),
      focusWidth: mix(focusWidth, other.focusWidth),
    );
  }
}
