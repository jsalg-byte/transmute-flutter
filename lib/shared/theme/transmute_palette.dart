import 'package:flutter/material.dart';

import '../../core/domain/models.dart';

/// Semantic color tokens for a saved Transmute palette and brightness mode.
///
/// Keeping these as a [ThemeExtension] means components that use the shared
/// palette update with the selected account theme rather than only changing a
/// Material seed color.
class TransmutePalette extends ThemeExtension<TransmutePalette> {
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
      Theme.of(context).extension<TransmutePalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

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

  static TransmutePalette forPreference(ThemePreference preference) =>
      forPalette(preference.palette, preference.brightness);

  static TransmutePalette forPalette(
    ThemePalette palette,
    PreferenceBrightness brightness,
  ) => switch ((palette, brightness)) {
    (ThemePalette.transmute, PreferenceBrightness.light) => light,
    (ThemePalette.transmute, PreferenceBrightness.dark) => dark,
    (ThemePalette.flameAlchemist, PreferenceBrightness.light) => _flameLight,
    (ThemePalette.flameAlchemist, PreferenceBrightness.dark) => _flameDark,
    (ThemePalette.hawkeye, PreferenceBrightness.light) => _hawkeyeLight,
    (ThemePalette.hawkeye, PreferenceBrightness.dark) => _hawkeyeDark,
    (ThemePalette.automailMechanic, PreferenceBrightness.light) =>
      _automailLight,
    (ThemePalette.automailMechanic, PreferenceBrightness.dark) => _automailDark,
    (ThemePalette.avarice, PreferenceBrightness.light) => _avariceLight,
    (ThemePalette.avarice, PreferenceBrightness.dark) => _avariceDark,
    (ThemePalette.scarredMan, PreferenceBrightness.light) => _scarredLight,
    (ThemePalette.scarredMan, PreferenceBrightness.dark) => _scarredDark,
    (ThemePalette.armorBoundSoul, PreferenceBrightness.light) => _armorLight,
    (ThemePalette.armorBoundSoul, PreferenceBrightness.dark) => _armorDark,
  };

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

  static const _flameLight = TransmutePalette._(
    surface: Color(0xffFFF1E5),
    raised: Color(0xffFFF9F3),
    ink: Color(0xff261612),
    body: Color(0xff3A2721),
    muted: Color(0xff775B51),
    divider: Color(0xffE6C7B6),
    oxide: Color(0xffB64732),
    steel: Color(0xff9F6B65),
    gold: Color(0xffD98A35),
    rest: Color(0xffBE3B30),
    recovering: Color(0xff8D5F8E),
    ready: Color(0xffB85B32),
  );
  static const _flameDark = TransmutePalette._(
    surface: Color(0xff1C1110),
    raised: Color(0xff291917),
    ink: Color(0xffFFEDE3),
    body: Color(0xffF5D8CB),
    muted: Color(0xffD4ADA0),
    divider: Color(0xff52332E),
    oxide: Color(0xffF17850),
    steel: Color(0xffD38475),
    gold: Color(0xffE9A94A),
    rest: Color(0xffFF7664),
    recovering: Color(0xffC591C4),
    ready: Color(0xffF28C5B),
  );

  static const _hawkeyeLight = TransmutePalette._(
    surface: Color(0xffF1F0E5),
    raised: Color(0xffFAFAF2),
    ink: Color(0xff293028),
    body: Color(0xff3F493B),
    muted: Color(0xff64705D),
    divider: Color(0xffD6D5C2),
    oxide: Color(0xff65705B),
    steel: Color(0xff6E806E),
    gold: Color(0xffAF864A),
    rest: Color(0xffA65443),
    recovering: Color(0xff706B91),
    ready: Color(0xff547964),
  );
  static const _hawkeyeDark = TransmutePalette._(
    surface: Color(0xff161A16),
    raised: Color(0xff222820),
    ink: Color(0xffEEF0E6),
    body: Color(0xffD5DBC9),
    muted: Color(0xffB2BCA4),
    divider: Color(0xff424A3D),
    oxide: Color(0xffA1AE8B),
    steel: Color(0xff9CA787),
    gold: Color(0xffD0A661),
    rest: Color(0xffDF7965),
    recovering: Color(0xffA9A3CD),
    ready: Color(0xff88B58D),
  );

  static const _automailLight = TransmutePalette._(
    surface: Color(0xffEAF4F7),
    raised: Color(0xffF8FCFD),
    ink: Color(0xff162830),
    body: Color(0xff29404B),
    muted: Color(0xff5B7480),
    divider: Color(0xffC6DCE4),
    oxide: Color(0xff3980A2),
    steel: Color(0xff588DA5),
    gold: Color(0xffB8893C),
    rest: Color(0xffB8513C),
    recovering: Color(0xff737CB1),
    ready: Color(0xff287B94),
  );
  static const _automailDark = TransmutePalette._(
    surface: Color(0xff101C22),
    raised: Color(0xff182932),
    ink: Color(0xffE7F3F7),
    body: Color(0xffCEE3E9),
    muted: Color(0xffA4C0CA),
    divider: Color(0xff334E5A),
    oxide: Color(0xff70B9D7),
    steel: Color(0xff8DB9C8),
    gold: Color(0xffDAAA54),
    rest: Color(0xffE17861),
    recovering: Color(0xffA6ABDD),
    ready: Color(0xff62BDD0),
  );

  static const _avariceLight = TransmutePalette._(
    surface: Color(0xffEFF7F1),
    raised: Color(0xffFAFDFB),
    ink: Color(0xff102C24),
    body: Color(0xff254339),
    muted: Color(0xff55756A),
    divider: Color(0xffC9DED4),
    oxide: Color(0xff257B67),
    steel: Color(0xff4D9B82),
    gold: Color(0xffC69925),
    rest: Color(0xffAF4C45),
    recovering: Color(0xff6C6DA6),
    ready: Color(0xff2C896D),
  );
  static const _avariceDark = TransmutePalette._(
    surface: Color(0xff0D211B),
    raised: Color(0xff143128),
    ink: Color(0xffE6F4EC),
    body: Color(0xffC8E2D4),
    muted: Color(0xff9CC3B0),
    divider: Color(0xff315444),
    oxide: Color(0xff67B99A),
    steel: Color(0xff74C2A5),
    gold: Color(0xffDAB54B),
    rest: Color(0xffE2746B),
    recovering: Color(0xffA4A2D4),
    ready: Color(0xff6FC99C),
  );

  static const _scarredLight = TransmutePalette._(
    surface: Color(0xffF7ECE8),
    raised: Color(0xffFFF9F7),
    ink: Color(0xff35201E),
    body: Color(0xff513431),
    muted: Color(0xff80605B),
    divider: Color(0xffE4C9C1),
    oxide: Color(0xffA84940),
    steel: Color(0xffA16A5F),
    gold: Color(0xffB89B74),
    rest: Color(0xffB53D35),
    recovering: Color(0xff84698E),
    ready: Color(0xff9B5947),
  );
  static const _scarredDark = TransmutePalette._(
    surface: Color(0xff221211),
    raised: Color(0xff321B19),
    ink: Color(0xffF9EAE5),
    body: Color(0xffEACDC4),
    muted: Color(0xffCDA69C),
    divider: Color(0xff593532),
    oxide: Color(0xffDC7569),
    steel: Color(0xffD68A7D),
    gold: Color(0xffD0B28A),
    rest: Color(0xffF1766B),
    recovering: Color(0xffB69ABE),
    ready: Color(0xffDC8D73),
  );

  static const _armorLight = TransmutePalette._(
    surface: Color(0xffEEF3F4),
    raised: Color(0xffFAFCFC),
    ink: Color(0xff1D2B30),
    body: Color(0xff31444B),
    muted: Color(0xff627980),
    divider: Color(0xffCBD9DC),
    oxide: Color(0xff4C91AF),
    steel: Color(0xff78949E),
    gold: Color(0xff9C834F),
    rest: Color(0xffA7514E),
    recovering: Color(0xff697C99),
    ready: Color(0xff4F9BB8),
  );
  static const _armorDark = TransmutePalette._(
    surface: Color(0xff101B1F),
    raised: Color(0xff1A2A2F),
    ink: Color(0xffE8F0F2),
    body: Color(0xffD0E0E4),
    muted: Color(0xffA9C0C6),
    divider: Color(0xff3A5057),
    oxide: Color(0xff73BAD7),
    steel: Color(0xff9ABAC3),
    gold: Color(0xffC6AA70),
    rest: Color(0xffDB7771),
    recovering: Color(0xff9FB5D1),
    ready: Color(0xff71C3D5),
  );

  @override
  TransmutePalette copyWith({
    Color? surface,
    Color? raised,
    Color? ink,
    Color? body,
    Color? muted,
    Color? divider,
    Color? oxide,
    Color? steel,
    Color? gold,
    Color? rest,
    Color? recovering,
    Color? ready,
  }) => TransmutePalette._(
    surface: surface ?? this.surface,
    raised: raised ?? this.raised,
    ink: ink ?? this.ink,
    body: body ?? this.body,
    muted: muted ?? this.muted,
    divider: divider ?? this.divider,
    oxide: oxide ?? this.oxide,
    steel: steel ?? this.steel,
    gold: gold ?? this.gold,
    rest: rest ?? this.rest,
    recovering: recovering ?? this.recovering,
    ready: ready ?? this.ready,
  );

  @override
  TransmutePalette lerp(covariant TransmutePalette? other, double t) {
    if (other == null) return this;
    return TransmutePalette._(
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      body: Color.lerp(body, other.body, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      oxide: Color.lerp(oxide, other.oxide, t)!,
      steel: Color.lerp(steel, other.steel, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      rest: Color.lerp(rest, other.rest, t)!,
      recovering: Color.lerp(recovering, other.recovering, t)!,
      ready: Color.lerp(ready, other.ready, t)!,
    );
  }
}
