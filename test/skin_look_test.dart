import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('anime skins are part of the phone skin list', () {
    expect(AppSkin.proSkins, isEmpty);
    expect(AppSkin.standardSkins, [
      AppSkin.classic,
      AppSkin.midnight,
      AppSkin.forest,
      AppSkin.sunset,
      AppSkin.minimal,
      AppSkin.synthwave,
      AppSkin.boldSports,
      AppSkin.chibi,
      AppSkin.cyberpunk,
      AppSkin.dumbbell,
    ]);
    expect(AppSkin.standardSkins.every((skin) => !skin.pro), isTrue);
  });

  test('anime skins keep their names and neon colours', () {
    expect(AppSkin.boldSports.displayName, 'Bold Sports');
    expect(AppSkin.chibi.description, 'Soft pastel cute anime');
    expect(AppSkin.cyberpunk.description, 'Neon cyan and magenta night city');
    expect(AppSkin.dumbbell.displayName, 'Dumbbell');

    expect(
      AppSkins.palette(AppSkin.boldSports, Brightness.dark).primary,
      const Color(0xFFFF2D95),
    );
    expect(
      AppSkins.palette(AppSkin.boldSports, Brightness.light).primary,
      const Color(0xFFE0187A),
    );
    final cyberpunk = AppSkins.palette(AppSkin.cyberpunk, Brightness.dark);
    expect(cyberpunk.primary, const Color(0xFF00E5FF));
    expect(cyberpunk.secondary, const Color(0xFFFF2D95));
    expect(
      AppSkins.palette(AppSkin.chibi, Brightness.light).background,
      isNot(
        AppSkins.palette(AppSkin.chibi, Brightness.dark).background,
      ),
    );
    expect(AppSkins.look(AppSkin.chibi).radius, 28);
    expect(AppSkins.look(AppSkin.dumbbell).bodyFont, SkinTypeface.outfit);
    expect(AppSkin.boldSports.previewAsset, contains('bold-sports'));
    expect(AppSkin.chibi.previewAsset, contains('chibi'));
    expect(AppSkin.cyberpunk.previewAsset, contains('cyberpunk'));
    expect(AppSkin.dumbbell.previewAsset, contains('banner-home'));
    expect(AppSkin.classic.previewAsset, isNull);
  });

  test('classic keeps the original corners and page padding', () {
    final look = AppSkins.look(AppSkin.classic);
    expect(look.radius, 18);
    expect(look.radiusSmall, 14);
    expect(look.pagePadding, 16);
    expect(look.listGap, 12);
    expect(look.buttonPaddingHorizontal, 24);
    expect(look.buttonPaddingVertical, 14);
    expect(look.bodyFont, SkinTypeface.plusJakartaSans);
    expect(look.displayFont, SkinTypeface.plusJakartaSans);
  });

  test('each skin has its own corners, spacing, and typeface', () {
    final midnight = AppSkins.look(AppSkin.midnight);
    expect(midnight.radius, 10);
    expect(midnight.radiusSmall, 8);
    expect(midnight.pagePadding, 12);
    expect(midnight.listGap, 8);
    expect(midnight.bodyFont, SkinTypeface.spaceGrotesk);

    final forest = AppSkins.look(AppSkin.forest);
    expect(forest.radius, 28);
    expect(forest.radiusSmall, 20);
    expect(forest.pagePadding, 22);
    expect(forest.listGap, 16);
    expect(forest.bodyFont, SkinTypeface.nunito);

    final sunset = AppSkins.look(AppSkin.sunset);
    expect(sunset.radius, 20);
    expect(sunset.radiusSmall, 16);
    expect(sunset.pagePadding, 16);
    expect(sunset.listGap, 12);
    expect(sunset.bodyFont, SkinTypeface.outfit);

    final minimal = AppSkins.look(AppSkin.minimal);
    expect(minimal.radius, 4);
    expect(minimal.radiusSmall, 4);
    expect(minimal.pagePadding, 12);
    expect(minimal.listGap, 8);
    expect(minimal.bodyFont, SkinTypeface.inter);

    final synthwave = AppSkins.look(AppSkin.synthwave);
    expect(synthwave.radius, 6);
    expect(synthwave.radiusSmall, 4);
    expect(synthwave.pagePadding, 12);
    expect(synthwave.listGap, 8);
    expect(synthwave.bodyFont, SkinTypeface.rajdhani);
    expect(synthwave.displayFont, SkinTypeface.orbitron);
  });

  testWidgets('the theme carries the selected skin look', (tester) async {
    late SkinLook look;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppSkin.forest),
        home: Builder(
          builder: (context) {
            look = context.skinLook;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(look.radius, 28);
    expect(look.pagePadding, 22);
    expect(look.bodyFont, SkinTypeface.nunito);
  });
}
