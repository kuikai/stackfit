import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackfit/core/page_transition.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';
import 'package:stackfit/widgets/chibi_run.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('anime skins are part of the phone skin list', () {
    expect(AppSkin.standardSkins, [
      AppSkin.classic,
      AppSkin.midnight,
      AppSkin.forest,
      AppSkin.sunset,
      AppSkin.minimal,
      AppSkin.synthwave,
    ]);
    expect(AppSkin.proSkins, [
      AppSkin.boldSports,
      AppSkin.chibi,
      AppSkin.cyberpunk,
      AppSkin.dumbbell,
    ]);
    expect(AppSkin.standardSkins.every((skin) => !skin.pro), isTrue);
    expect(AppSkin.proSkins.every((skin) => skin.pro), isTrue);
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
      isNot(AppSkins.palette(AppSkin.chibi, Brightness.dark).background),
    );
    expect(AppSkins.look(AppSkin.chibi).radius, 28);
    expect(AppSkins.look(AppSkin.dumbbell).bodyFont, SkinTypeface.outfit);
    expect(AppSkin.boldSports.previewAsset, contains('bold-sports'));
    expect(AppSkin.chibi.previewAsset, contains('chibi'));
    expect(AppSkin.cyberpunk.previewAsset, contains('cyberpunk'));
    expect(AppSkin.boldSports.backgroundAsset, contains('bold-sports/background'));
    expect(AppSkin.chibi.backgroundAsset, contains('chibi/background'));
    expect(AppSkin.cyberpunk.backgroundAsset, contains('background.jpg'));
    expect(AppSkin.dumbbell.backgroundAsset, contains('dumbbell/background'));
    expect(AppSkin.classic.backgroundAsset, isNull);
    expect(AppSkin.boldSports.mascotAsset, contains('mascot-power.png'));
    expect(AppSkin.chibi.mascotAsset, contains('mascot-pastel.png'));
    expect(AppSkin.cyberpunk.mascotAsset, contains('mascot-chibi.png'));
    expect(AppSkin.dumbbell.mascotAsset, contains('mascot-companion.png'));
    expect(AppSkin.boldSports.mascotSeatAsset, contains('mascot-power-sit'));
    expect(AppSkin.chibi.mascotSeatAsset, contains('mascot-pastel-sit'));
    expect(AppSkin.cyberpunk.mascotSeatAsset, contains('mascot-chibi-sit'));
    expect(AppSkin.dumbbell.mascotSeatAsset, contains('mascot-companion-sit'));
    expect(AppSkin.boldSports.mascotRestAsset, contains('mascot-power-rest'));
    expect(AppSkin.chibi.mascotRestAsset, contains('mascot-pastel-rest'));
    expect(AppSkin.cyberpunk.mascotRestAsset, contains('mascot-chibi-rest'));
    expect(AppSkin.dumbbell.mascotRestAsset, contains('mascot-companion-rest'));
    expect(AppSkin.boldSports.mascotRunFrames, hasLength(8));
    expect(AppSkin.chibi.mascotRunFrames, hasLength(8));
    expect(AppSkin.cyberpunk.mascotRunFrames, hasLength(13));
    expect(AppSkin.dumbbell.mascotRunFrames, hasLength(8));
    expect(AppSkin.classic.mascotRunFrames, isEmpty);
    expect(runFrameIndex(elapsedSeconds: 0, frameCount: 6), 0);
    expect(runFrameIndex(elapsedSeconds: 0.5, frameCount: 6), 4);
    expect(runFrameIndex(elapsedSeconds: 0.75, frameCount: 6), 0);
    expect(runFrameIndex(elapsedSeconds: 1, frameCount: 0), 0);
    expect(AppSkin.classic.mascotAsset, isNull);
    expect(AppSkin.classic.mascotSeatAsset, isNull);
    expect(AppSkin.classic.mascotRestAsset, isNull);
    expect(AppSkin.boldSports.heroAsset, contains('girl-standing'));
    expect(AppSkin.chibi.heroAsset, contains('girl-standing'));
    expect(AppSkin.cyberpunk.heroAsset, contains('girl-standing'));
    expect(AppSkin.dumbbell.heroAsset, contains('girl-standing'));
    expect(AppSkin.cyberpunk.homePlateAsset, contains('girl-standing'));
    expect(AppSkin.classic.heroAsset, isNull);
    expect(AppSkin.classic.homePlateAsset, isNull);
    expect(AppSkins.look(AppSkin.boldSports).cardOpacity, 0.12);
    expect(AppSkins.look(AppSkin.chibi).cardOpacity, 0.14);
    expect(AppSkins.look(AppSkin.cyberpunk).cardOpacity, 0.12);
    expect(AppSkins.look(AppSkin.dumbbell).cardOpacity, 0.14);
    expect(AppSkins.look(AppSkin.classic).cardOpacity, 1);
    final cyberpunkFill = AppSkins.look(
      AppSkin.cyberpunk,
    ).cardFill(const ColorScheme.dark());
    expect(cyberpunkFill.a, closeTo(0.72, 0.01));
    final portraitFill = AppSkins.look(
      AppSkin.cyberpunk,
    ).cardFill(const ColorScheme.dark(), overPortrait: true);
    expect(portraitFill.a, closeTo(0.72, 0.01));
    expect(
      AppSkins.look(AppSkin.classic).cardFill(const ColorScheme.dark()).a,
      1,
    );
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
    final transitions = Theme.of(
      tester.element(find.byType(SizedBox)),
    ).pageTransitionsTheme.builders[TargetPlatform.windows];
    expect(transitions, isA<SoftPageTransitionsBuilder>());
    expect(transitions!.transitionDuration, const Duration(milliseconds: 420));
  });
}
