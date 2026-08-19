import 'package:flutter/material.dart';

/// Default Transmute palette mirrored from the Expo client. Components use it
/// instead of pinning light-mode colors so contrast survives a mode change.
class TransmutePalette {
  const TransmutePalette._({
    required this.surface,
    required this.raised,
    required this.ink,
    required this.body,
    required this.muted,
    required this.divider,
    required this.oxide,
    required this.steel,
    required this.gold,
    required this.rest,
    required this.recovering,
    required this.ready,
  });

  factory TransmutePalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final Color surface;
  final Color raised;
  final Color ink;
  final Color body;
  final Color muted;
  final Color divider;
  final Color oxide;
  final Color steel;
  final Color gold;
  final Color rest;
  final Color recovering;
  final Color ready;

  static const light = TransmutePalette._(
    surface: Color(0xffF4EBD8),
    raised: Color(0xffFCF7EC),
    ink: Color(0xff171821),
    body: Color(0xff292B35),
    muted: Color(0xff605D63),
    divider: Color(0xffD9CEB9),
    oxide: Color(0xff6D79A0),
    steel: Color(0xff6D79A0),
    gold: Color(0xffD1A742),
    rest: Color(0xffA33B36),
    recovering: Color(0xff65419E),
    ready: Color(0xff2867A1),
  );

  static const dark = TransmutePalette._(
    surface: Color(0xff14131A),
    raised: Color(0xff201E29),
    ink: Color(0xffF4F0E6),
    body: Color(0xffE5E0D7),
    muted: Color(0xffBDB7B2),
    divider: Color(0xff413D50),
    oxide: Color(0xff8B95B8),
    steel: Color(0xff8B95B8),
    gold: Color(0xffD9B653),
    rest: Color(0xffE0756E),
    recovering: Color(0xffA3AAC4),
    ready: Color(0xff8B95B8),
  );
}
