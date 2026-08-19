import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/shared/theme/transmute_palette.dart';

void main() {
  testWidgets('dark palette mirrors the Expo Transmute dark tokens', (
    tester,
  ) async {
    late TransmutePalette palette;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            palette = TransmutePalette.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(palette.surface, const Color(0xff14131A));
    expect(palette.raised, const Color(0xff201E29));
    expect(palette.ink, const Color(0xffF4F0E6));
    expect(palette.muted, const Color(0xffBDB7B2));
    expect(palette.divider, const Color(0xff413D50));
  });
}
