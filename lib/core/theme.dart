import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'skins.dart';

/// Clean Athletic Material 3 themes from the selected [AppSkin].
class AppTheme {
  AppTheme._();

  static ThemeData light(AppSkin skin) =>
      _build(skin: skin, brightness: Brightness.light);

  static ThemeData dark(AppSkin skin) =>
      _build(skin: skin, brightness: Brightness.dark);

  static ThemeData _build({
    required AppSkin skin,
    required Brightness brightness,
  }) {
    final palette = AppSkins.palette(skin, brightness);
    final look = AppSkins.look(skin);
    final colorScheme = palette.toColorScheme(brightness);
    final showGym =
        brightness == Brightness.dark && skin.backgroundAsset != null;
    final scaffoldBackground = showGym
        ? Colors.transparent
        : palette.background;
    final textTheme = _skinTextTheme(
      look: look,
      brightness: brightness,
      color: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      extensions: [look],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: _appBarTheme(scaffoldBackground, colorScheme, textTheme),
      cardTheme: _cardTheme(colorScheme, look, brightness),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),
      filledButtonTheme: _filledButtonTheme(look),
      outlinedButtonTheme: _outlinedButtonTheme(look),
      floatingActionButtonTheme: _fabTheme(colorScheme, look),
      segmentedButtonTheme: _segmentedTheme(colorScheme),
      inputDecorationTheme: _inputTheme(colorScheme, look),
      dialogTheme: _dialogTheme(colorScheme, look),
      snackBarTheme: _snackBarTheme(look),
      dividerTheme: _dividerTheme(colorScheme),
    );
  }
}

extension SkinLookContext on BuildContext {
  SkinLook get skinLook =>
      Theme.of(this).extension<SkinLook>() ?? AppSkins.look(AppSkin.classic);

  EdgeInsets pageGutter({double top = 0, double bottom = 0}) {
    final pad = skinLook.pagePadding;
    return EdgeInsets.fromLTRB(pad, top, pad, bottom);
  }
}

TextStyle _withFamily(SkinTypeface face, TextStyle base) {
  return switch (face) {
    SkinTypeface.plusJakartaSans => GoogleFonts.plusJakartaSans(
      textStyle: base,
    ),
    SkinTypeface.spaceGrotesk => GoogleFonts.spaceGrotesk(textStyle: base),
    SkinTypeface.nunito => GoogleFonts.nunito(textStyle: base),
    SkinTypeface.outfit => GoogleFonts.outfit(textStyle: base),
    SkinTypeface.inter => GoogleFonts.inter(textStyle: base),
    SkinTypeface.rajdhani => GoogleFonts.rajdhani(textStyle: base),
    SkinTypeface.orbitron => GoogleFonts.orbitron(textStyle: base),
  };
}

extension SkinTypefaceText on SkinTypeface {
  TextStyle style({
    TextStyle? textStyle,
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
    double? height,
  }) {
    final base = (textStyle ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: height,
    );
    return _withFamily(this, base);
  }

  TextTheme textTheme(TextTheme base) {
    return switch (this) {
      SkinTypeface.plusJakartaSans => GoogleFonts.plusJakartaSansTextTheme(
        base,
      ),
      SkinTypeface.spaceGrotesk => GoogleFonts.spaceGroteskTextTheme(base),
      SkinTypeface.nunito => GoogleFonts.nunitoTextTheme(base),
      SkinTypeface.outfit => GoogleFonts.outfitTextTheme(base),
      SkinTypeface.inter => GoogleFonts.interTextTheme(base),
      SkinTypeface.rajdhani => GoogleFonts.rajdhaniTextTheme(base),
      SkinTypeface.orbitron => GoogleFonts.orbitronTextTheme(base),
    };
  }
}

TextTheme _skinTextTheme({
  required SkinLook look,
  required Brightness brightness,
  required Color color,
}) {
  final base = look.bodyFont
      .textTheme(ThemeData(brightness: brightness).textTheme)
      .apply(bodyColor: color, displayColor: color);
  return base.copyWith(
    displayLarge: _displayStyle(look, color, letterSpacing: -2.2, height: 1),
    displaySmall: _displayStyle(look, color, letterSpacing: -1.2),
    headlineMedium: _displayStyle(
      look,
      color,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    ),
    titleLarge: _displayStyle(
      look,
      color,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: _bodyStyle(look, color, fontWeight: FontWeight.w600),
    bodyLarge: _bodyStyle(look, color, height: 1.4),
    bodyMedium: _bodyStyle(look, color, height: 1.4),
    labelLarge: _bodyStyle(
      look,
      color,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
}

TextStyle _displayStyle(
  SkinLook look,
  Color color, {
  FontWeight fontWeight = FontWeight.w800,
  double? letterSpacing,
  double? height,
}) {
  return look.displayFont.style(
    color: color,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle _bodyStyle(
  SkinLook look,
  Color color, {
  FontWeight fontWeight = FontWeight.w500,
  double? letterSpacing,
  double? height,
}) {
  return look.bodyFont.style(
    color: color,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

AppBarTheme _appBarTheme(
  Color background,
  ColorScheme colorScheme,
  TextTheme textTheme,
) {
  return AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: background,
    foregroundColor: colorScheme.onSurface,
    titleTextStyle: textTheme.titleLarge,
  );
}

CardThemeData _cardTheme(
  ColorScheme colorScheme,
  SkinLook look,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;
  final glass = look.cardOpacity < 1;
  return CardThemeData(
    elevation: glass ? 0 : (isDark ? 0 : 1.5),
    shadowColor: glass
        ? Colors.transparent
        : Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
    shape: RoundedRectangleBorder(
      borderRadius: look.cornerRadius,
      side: glass
          ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.32))
          : BorderSide.none,
    ),
    color: look.cardFill(colorScheme),
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
  );
}

FilledButtonThemeData _filledButtonTheme(SkinLook look) {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      minimumSize: Size(48, look.filledButtonHeight),
      padding: look.buttonPadding,
      shape: RoundedRectangleBorder(borderRadius: look.cornerRadiusSmall),
    ),
  );
}

OutlinedButtonThemeData _outlinedButtonTheme(SkinLook look) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: Size(48, look.outlinedButtonHeight),
      padding: look.outlinedButtonPadding,
      shape: RoundedRectangleBorder(borderRadius: look.cornerRadiusSmall),
    ),
  );
}

FloatingActionButtonThemeData _fabTheme(
  ColorScheme colorScheme,
  SkinLook look,
) {
  return FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: look.cornerRadius),
  );
}

SegmentedButtonThemeData _segmentedTheme(ColorScheme colorScheme) {
  return SegmentedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.onSurface;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
    ),
  );
}

InputDecorationTheme _inputTheme(ColorScheme colorScheme, SkinLook look) {
  final borderRadius = look.cornerRadiusSmall;
  final padding = EdgeInsets.symmetric(
    horizontal: look.pagePadding,
    vertical: look.pagePadding,
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surface,
    contentPadding: padding,
    border: OutlineInputBorder(borderRadius: borderRadius),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.8),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    ),
  );
}

DialogThemeData _dialogTheme(ColorScheme colorScheme, SkinLook look) {
  return DialogThemeData(
    backgroundColor: colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: look.cornerRadius),
  );
}

SnackBarThemeData _snackBarTheme(SkinLook look) {
  return SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: look.cornerRadiusSmall),
  );
}

DividerThemeData _dividerTheme(ColorScheme colorScheme) {
  return DividerThemeData(
    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
    thickness: 1,
    space: 1,
  );
}
