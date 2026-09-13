import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transmute_flutter/app/app.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/design_library/presentation/design_library_screen.dart';
import 'package:transmute_flutter/shared/design_system/design_system.dart';
import 'package:transmute_flutter/shared/theme/transmute_palette.dart';

const preference = ThemePreference(
  palette: ThemePalette.transmute,
  brightness: PreferenceBrightness.light,
);

Widget host(Widget child) => MaterialApp(
  theme: buildTransmuteTheme(preference),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('debug catalog route is available without signing in', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/design-library';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await tester.pumpWidget(const ProviderScope(child: TransmuteApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DesignLibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('palette and geometry are independent in every theme combination', () {
    for (final palette in ThemePalette.values) {
      for (final brightness in PreferenceBrightness.values) {
        for (final style in DesignStyle.values) {
          final theme = buildTransmuteTheme(
            ThemePreference(palette: palette, brightness: brightness),
            style: style,
          );
          expect(
            theme.extension<TransmutePalette>()!.ink,
            TransmutePalette.forPalette(palette, brightness).ink,
          );
          expect(
            theme.extension<DesignTokens>()!.radius,
            style == DesignStyle.ledger ? 0 : 16,
          );
          expect(
            theme.extension<DesignTokens>()!.controlHeight,
            greaterThanOrEqualTo(44),
          );
          expect(theme.textTheme.titleLarge!.fontFamily, 'Spectral');
        }
      }
    }
    expect(DesignTokens.ledger.lerp(DesignTokens.soft, .5).radius, 8);
  });

  test('cute custom style tokens retain the sampled pastel language', () {
    final styles = CuteCustomStyles.defaults();
    final colorBlindStyles = CuteCustomStyles.defaults(colorBlindSafe: true);

    expect(cuteColorScheme.primary, CuteColors.primary);
    expect(cuteColorScheme.secondary, CuteColors.secondary);
    expect(cuteColorScheme.tertiary, CuteColors.accent);
    expect(cuteColorScheme.surface, CuteColors.surface);
    expect(styles.extraLargeRadius.topLeft.x, 32);
    expect(styles.softShadow.single.color, const Color(0x1FF29191));

    final larger = styles.copyWith(extraLargeRadius: BorderRadius.circular(40));
    expect(styles.lerp(larger, .5).extraLargeRadius.topLeft.x, 36);
    expect(cuteColorBlindColorScheme.primary, CuteColorBlindColors.primary);
    expect(cuteColorBlindColorScheme.surface, CuteColorBlindColors.surface);
    expect(
      TransmutePalette.cutePastel(colorBlindSafe: true).rest,
      isNot(TransmutePalette.cutePastel(colorBlindSafe: true).ready),
    );
    expect(
      colorBlindStyles.accentGradient.colors.first,
      CuteColorBlindColors.secondary,
    );
  });

  test(
    'cute theme toggle persists separately from the account palette',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = ProviderContainer();
      addTearDown(first.dispose);
      expect(await first.read(cuteThemeEnabledProvider.future), isFalse);

      await first.read(cuteThemeEnabledProvider.notifier).setEnabled(true);
      expect(first.read(cuteThemeEnabledProvider).asData?.value, isTrue);
      expect(await first.read(cuteColorBlindModeProvider.future), isFalse);
      await first.read(cuteColorBlindModeProvider.notifier).setEnabled(true);
      expect(first.read(cuteColorBlindModeProvider).asData?.value, isTrue);

      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      expect(await restored.read(cuteThemeEnabledProvider.future), isTrue);
      expect(await restored.read(cuteColorBlindModeProvider.future), isTrue);
    },
  );

  testWidgets('loading preserves button bounds and disables taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(TransmuteButton(label: 'Save Set', onPressed: () => taps++)),
    );
    final size = tester.getSize(find.byType(ElevatedButton));
    await tester.tap(find.text('Save Set'));
    expect(taps, 1);
    await tester.pumpWidget(
      host(
        TransmuteButton(
          label: 'Save Set',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(ElevatedButton)), size);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('stepper retains full title and disables boundary navigation', (
    tester,
  ) async {
    const name = 'Dumbbell Posterior Delt Row With a Long Movement Name';
    var index = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 280,
            child: TransmuteStepper(
              title: name,
              currentIndex: index,
              stepCount: 2,
              onPrevious: index == 0 ? null : () => setState(() => index--),
              onNext: index == 1 ? null : () => setState(() => index++),
            ),
          ),
        ),
      ),
    );
    expect(find.text(name), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Previous Step',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Next Step'));
    await tester.pump();
    expect(index, 1);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Next Step',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(1200, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('catalog lays out at $size with text scale $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const DesignLibraryScreen(),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byType(Switch));
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'catalog preview switches style and logs only local sample state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: DesignLibraryScreen()));
      await tester.pump();
      await tester.tap(find.text('Ledger · Current'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Soft · Prototype').last);
      await tester.pump(const Duration(milliseconds: 300));
      final panelContext = tester.element(find.byType(TransmutePanel).first);
      expect(DesignTokens.of(panelContext).radius, 16);
      final log = find.widgetWithText(TransmuteButton, 'Log Set');
      await tester.ensureVisible(log);
      await tester.tap(log);
      await tester.pump();
      final other = find.widgetWithText(TransmuteButton, 'Other Log');
      expect(tester.widget<TransmuteButton>(other).onPressed, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('Sample Set Saved · No data was uploaded.'),
        findsOneWidget,
      );
      Finder field(String label) => find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is TransmuteTextField && widget.semanticLabel == label,
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(field('Preview Weight (lb)'), '0');
      await tester.enterText(field('Preview Reps'), '0');
      await tester.tap(log);
      await tester.pump();
      expect(
        find.text('Use a nonnegative weight and at least 1 rep.'),
        findsOneWidget,
      );
      await tester.enterText(field('Preview Reps'), '1');
      await tester.tap(log);
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('Sample Set Saved · No data was uploaded.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
