import 'package:flutter/material.dart';

// ============================================================
// RISING ARMY — DESIGN SYSTEM
// Dark medieval strategy.
// Theme, design tokens, typography and semantic game colors.
// No gameplay logic or external dependencies.
// ============================================================

// ------------------------------------------------------------
// 1. COLOR PALETTE
// ------------------------------------------------------------

abstract final class Pal {
  Pal._();

  // Environment
  static const bg = Color(0xFF15110D);
  static const bgElevated = Color(0xFF1C1610);
  static const bgDeep = Color(0xFF100D09);

  // Wood / panels
  static const panel = Color(0xFF261D15);
  static const panelHi = Color(0xFF34271B);
  static const panelPressed = Color(0xFF20170F);
  static const panelRaised = Color(0xFF3D2D1E);

  // Borders
  static const line = Color(0xFF493726);
  static const lineStrong = Color(0xFF705335);
  static const lineSubtle = Color(0xFF36291D);

  // Brass / gold
  static const gold = Color(0xFFD9A441);
  static const goldDim = Color(0xFF9C7A32);
  static const goldLight = Color(0xFFF0C96B);
  static const goldDark = Color(0xFF705020);
  static const goldDeep = Color(0xFF493416);

  // Semantic colors
  static const blood = Color(0xFFC0503E);
  static const bloodDark = Color(0xFF7E3026);
  static const moss = Color(0xFF7BA05B);
  static const mossDark = Color(0xFF49663A);
  static const steel = Color(0xFF8FA3B3);
  static const steelDark = Color(0xFF526675);

  // Text
  static const text = Color(0xFFF1E7D2);
  static const dim = Color(0xFFA99B84);
  static const muted = Color(0xFF796B59);
  static const parchment = Color(0xFFD8C39A);
  static const ink = Color(0xFF2B2016);
  static const pureWhite = Color(0xFFFFFFFF);

  // Overlays
  static const overlay = Color(0xB8000000);
  static const scrim = Color(0x99000000);
  static const vignette = Color(0x66000000);

  // State surfaces
  static const successSurface = Color(0xFF253321);
  static const warningSurface = Color(0xFF392B18);
  static const dangerSurface = Color(0xFF3A211C);
  static const infoSurface = Color(0xFF202D35);

  // Accessibility / disabled
  static const disabledText = Color(0xFF796E5D);
  static const disabledSurface = Color(0xFF292119);
  static const focus = goldLight;
}

// ------------------------------------------------------------
// 2. SEMANTIC COLOR ROLES
// ------------------------------------------------------------

abstract final class GameColors {
  GameColors._();

  static const background = Pal.bg;
  static const backgroundDeep = Pal.bgDeep;
  static const backgroundElevated = Pal.bgElevated;

  static const surface = Pal.panel;
  static const surfaceRaised = Pal.panelHi;
  static const surfaceHighest = Pal.panelRaised;
  static const surfacePressed = Pal.panelPressed;

  static const primary = Pal.gold;
  static const primaryHover = Pal.goldLight;
  static const primaryMuted = Pal.goldDim;
  static const primaryDeep = Pal.goldDark;

  static const positive = Pal.moss;
  static const positiveSurface = Pal.successSurface;
  static const negative = Pal.blood;
  static const negativeSurface = Pal.dangerSurface;
  static const warning = Pal.gold;
  static const warningSurface = Pal.warningSurface;
  static const neutral = Pal.steel;
  static const neutralSurface = Pal.infoSurface;

  static const textPrimary = Pal.text;
  static const textSecondary = Pal.dim;
  static const textMuted = Pal.muted;
  static const textOnPrimary = Pal.ink;

  static const border = Pal.line;
  static const borderEmphasis = Pal.lineStrong;
  static const focus = Pal.focus;
}

// ------------------------------------------------------------
// 3. SPACING
// ------------------------------------------------------------

abstract final class GameSpace {
  GameSpace._();

  static const double zero = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
  static const double screen = 24;
  static const double screenCompact = 12;
}

// ------------------------------------------------------------
// 4. RADII
// ------------------------------------------------------------

abstract final class GameRadius {
  GameRadius._();

  static const double xs = 3;
  static const double sm = 5;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;

  static const BorderRadius button = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));

  static const BorderRadius dialog = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius tooltip = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius menu = BorderRadius.all(Radius.circular(md));
}

// ------------------------------------------------------------
// 5. BORDERS
// ------------------------------------------------------------

abstract final class GameBorders {
  GameBorders._();

  static const thin = BorderSide(color: Pal.line, width: 1);

  static const normal = BorderSide(color: Pal.lineStrong, width: 1);

  static const accent = BorderSide(color: Pal.goldDim, width: 1.5);

  static const focus = BorderSide(color: Pal.goldLight, width: 2);

  static const danger = BorderSide(color: Pal.blood, width: 1.5);

  static const selected = BorderSide(color: Pal.gold, width: 1.5);

  static const panel = Border.fromBorderSide(normal);

  static const selectedPanel = Border.fromBorderSide(accent);
}

// ------------------------------------------------------------
// 6. ELEVATION / SHADOWS
// ------------------------------------------------------------

abstract final class GameElevation {
  GameElevation._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> panel = [
    BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x77000000), blurRadius: 14, offset: Offset(0, 5)),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(color: Color(0x33D9A441), blurRadius: 12, spreadRadius: 1),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

// ------------------------------------------------------------
// 7. TYPOGRAPHY
// ------------------------------------------------------------

// Georgia is a system serif font.
// Verify fallback behavior on supported platforms before release.
const String serif = 'Georgia';

abstract final class GameText {
  GameText._();

  // Display titles
  static const display = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    height: 1.12,
    fontWeight: FontWeight.w700,
    color: Pal.text,
    letterSpacing: 0.3,
  );

  static const displayLarge = TextStyle(
    fontFamily: serif,
    fontSize: 38,
    height: 1.08,
    fontWeight: FontWeight.w800,
    color: Pal.parchment,
    letterSpacing: 1.2,
  );

  static const h1 = TextStyle(
    fontFamily: serif,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: Pal.text,
  );

  static const h2 = TextStyle(
    fontFamily: serif,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: Pal.text,
  );

  static const h3 = TextStyle(
    fontFamily: serif,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: Pal.text,
  );

  static const section = TextStyle(
    fontFamily: serif,
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: Pal.parchment,
  );

  // General UI
  static const body = TextStyle(fontSize: 14, height: 1.4, color: Pal.text);

  static const bodySmall = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: Pal.dim,
  );

  static const caption = TextStyle(fontSize: 11, height: 1.3, color: Pal.dim);

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Pal.parchment,
  );

  static const button = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: Pal.dim,
  );

  static const buttonLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.7,
  );

  // HUD / numerical information
  static const hudValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: Pal.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const resourceValue = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Pal.parchment,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const statValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Pal.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const combatValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: Pal.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const numberLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: Pal.goldLight,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

// ------------------------------------------------------------
// 8. GAME STATUS COLORS
// ------------------------------------------------------------

abstract final class GameStatus {
  GameStatus._();

  // Army health / wellbeing
  static const healthy = Pal.moss;
  static const wounded = Pal.gold;
  static const critical = Pal.blood;
  static const exhausted = Pal.steel;

  // Item rarity
  static const common = Pal.dim;
  static const uncommon = Pal.moss;
  static const rare = Pal.steel;
  static const epic = Color(0xFFB38AE0);
  static const legendary = Pal.goldLight;

  // Quest states
  static const available = Pal.parchment;
  static const active = Pal.gold;
  static const completed = Pal.moss;
  static const failed = Pal.blood;

  // Notifications
  static const success = Pal.moss;
  static const warning = Pal.gold;
  static const danger = Pal.blood;
  static const info = Pal.steel;
}

// ------------------------------------------------------------
// 9. HUD TOKENS
// ------------------------------------------------------------

abstract final class GameHud {
  GameHud._();

  static const double barHeight = 48;
  static const double resourceCellMinWidth = 68;
  static const double iconSize = 20;
  static const double compactIconSize = 16;
  static const double portraitSize = 44;
  static const double unitPortraitSize = 52;
  static const double progressHeight = 6;

  static const double compactBarHeight = 40;
  static const double menuButtonSize = 44;
}

// ------------------------------------------------------------
// 10. MOTION
// ------------------------------------------------------------

abstract final class GameMotion {
  GameMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}

// ------------------------------------------------------------
// 11. COMMON DECORATIONS
// ------------------------------------------------------------

abstract final class GameDecorations {
  GameDecorations._();

  static BoxDecoration panel({
    Color color = Pal.panel,
    bool selected = false,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: GameRadius.card,
      border: selected ? GameBorders.selectedPanel : GameBorders.panel,
      boxShadow: elevated ? GameElevation.panel : GameElevation.none,
    );
  }

  static BoxDecoration inset({Color color = Pal.panelPressed}) {
    return BoxDecoration(
      color: color,
      borderRadius: GameRadius.button,
      border: const Border.fromBorderSide(GameBorders.thin),
    );
  }

  static BoxDecoration primaryAction() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8A672A), Pal.goldDark],
      ),
      borderRadius: GameRadius.button,
      border: const Border.fromBorderSide(GameBorders.accent),
      boxShadow: GameElevation.panel,
    );
  }

  static BoxDecoration dangerAction() {
    return BoxDecoration(
      color: Pal.bloodDark,
      borderRadius: GameRadius.button,
      border: const Border.fromBorderSide(GameBorders.danger),
      boxShadow: GameElevation.panel,
    );
  }

  static BoxDecoration menuSurface({bool highlighted = false}) {
    return BoxDecoration(
      color: highlighted ? Pal.panelHi : Pal.panel,
      borderRadius: GameRadius.card,
      border: Border.all(
        color: highlighted ? Pal.goldDim : Pal.line,
        width: highlighted ? 1.5 : 1,
      ),
      boxShadow: highlighted ? GameElevation.panel : GameElevation.none,
    );
  }
}

// ------------------------------------------------------------
// 12. THEME BUILDER
// ------------------------------------------------------------

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Pal.gold,
    onPrimary: Pal.ink,
    primaryContainer: Pal.goldDark,
    onPrimaryContainer: Pal.text,
    secondary: Pal.moss,
    onSecondary: Pal.ink,
    secondaryContainer: Pal.mossDark,
    onSecondaryContainer: Pal.text,
    tertiary: Pal.steel,
    onTertiary: Pal.ink,
    tertiaryContainer: Pal.steelDark,
    onTertiaryContainer: Pal.text,
    error: Pal.blood,
    onError: Pal.pureWhite,
    errorContainer: Pal.bloodDark,
    onErrorContainer: Pal.text,
    surface: Pal.panel,
    onSurface: Pal.text,
    surfaceContainerLowest: Pal.bg,
    surfaceContainerLow: Pal.bgElevated,
    surfaceContainer: Pal.panel,
    surfaceContainerHigh: Pal.panelHi,
    surfaceContainerHighest: Pal.panelRaised,
    onSurfaceVariant: Pal.dim,
    outline: Pal.lineStrong,
    outlineVariant: Pal.line,
    shadow: Colors.black,
    scrim: Pal.scrim,
    inverseSurface: Pal.parchment,
    onInverseSurface: Pal.ink,
    inversePrimary: Pal.goldDark,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Pal.bg,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    dividerColor: Pal.line,
    disabledColor: Pal.disabledText,
    fontFamily: null,
  );

  return base.copyWith(
    // TEXT
    textTheme: base.textTheme
        .copyWith(
          displayLarge: GameText.display,
          headlineLarge: GameText.h1,
          headlineMedium: GameText.h2,
          headlineSmall: GameText.h3,
          titleLarge: GameText.h2,
          titleMedium: GameText.section,
          titleSmall: GameText.label,
          bodyLarge: GameText.body.copyWith(fontSize: 15),
          bodyMedium: GameText.body,
          bodySmall: GameText.bodySmall,
          labelLarge: GameText.button,
          labelMedium: GameText.label,
          labelSmall: GameText.caption,
        )
        .apply(bodyColor: Pal.text, displayColor: Pal.text),

    // APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: Pal.bg,
      foregroundColor: Pal.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GameText.h2,
      toolbarHeight: 56,
      iconTheme: IconThemeData(color: Pal.parchment, size: 22),
    ),

    // CARDS
    cardTheme: CardThemeData(
      color: Pal.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: GameRadius.card,
        side: GameBorders.normal,
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // DIALOGS
    dialogTheme: DialogThemeData(
      backgroundColor: Pal.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: GameRadius.dialog,
        side: const BorderSide(color: Pal.lineStrong, width: 1.5),
      ),
      titleTextStyle: GameText.h2,
      contentTextStyle: GameText.body,
    ),

    // BUTTONS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Pal.disabledSurface;
          }
          if (states.contains(WidgetState.pressed)) {
            return Pal.goldDark;
          }
          return Pal.gold;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Pal.disabledText;
          }
          return Pal.ink;
        }),
        textStyle: const WidgetStatePropertyAll(GameText.button),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: GameRadius.button,
            side: const BorderSide(color: Pal.goldDim),
          ),
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Pal.disabledSurface;
          }
          if (states.contains(WidgetState.pressed)) {
            return Pal.goldDark;
          }
          return Pal.gold;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Pal.disabledText;
          }
          return Pal.ink;
        }),
        textStyle: const WidgetStatePropertyAll(GameText.button),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: GameRadius.button,
            side: const BorderSide(color: Pal.goldDim),
          ),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 42)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        foregroundColor: const WidgetStatePropertyAll(Pal.parchment),
        textStyle: const WidgetStatePropertyAll(GameText.button),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: Pal.line);
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused)) {
            return const BorderSide(color: Pal.gold, width: 1.5);
          }
          return const BorderSide(color: Pal.lineStrong);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: GameRadius.button),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        foregroundColor: const WidgetStatePropertyAll(Pal.goldLight),
        textStyle: const WidgetStatePropertyAll(GameText.button),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: GameRadius.button),
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Pal.parchment),
        iconSize: const WidgetStatePropertyAll(22),
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: GameRadius.button,
            side: const BorderSide(color: Pal.line),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Pal.panelHi;
          }
          return Pal.panel;
        }),
      ),
    ),

    // INPUTS
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Pal.panelPressed,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: GameText.bodySmall.copyWith(color: Pal.muted),
      labelStyle: GameText.label,
      floatingLabelStyle: GameText.label.copyWith(color: Pal.goldLight),
      errorStyle: GameText.caption.copyWith(color: Pal.blood),
      helperStyle: GameText.caption,
      prefixIconColor: Pal.dim,
      suffixIconColor: Pal.dim,
      border: OutlineInputBorder(
        borderRadius: GameRadius.button,
        borderSide: GameBorders.thin,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: GameRadius.button,
        borderSide: GameBorders.normal,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: GameRadius.button,
        borderSide: GameBorders.focus,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: GameRadius.button,
        borderSide: GameBorders.danger,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: GameRadius.button,
        borderSide: GameBorders.danger,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: GameRadius.button,
        borderSide: GameBorders.thin,
      ),
    ),

    // NAVIGATION / MENUS
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Pal.panel,
      indicatorColor: Pal.goldDark,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GameText.caption.copyWith(
          color: states.contains(WidgetState.selected)
              ? Pal.goldLight
              : Pal.dim,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Pal.goldLight
              : Pal.dim,
          size: 22,
        );
      }),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: Pal.panelHi,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      textStyle: GameText.body,
      shape: RoundedRectangleBorder(
        borderRadius: GameRadius.button,
        side: GameBorders.normal,
      ),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Pal.panelHi),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: GameRadius.button,
            side: GameBorders.normal,
          ),
        ),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Pal.panel,
      modalBackgroundColor: Pal.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      showDragHandle: true,
      dragHandleColor: Pal.lineStrong,
      modalBarrierColor: Pal.scrim,
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: Pal.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Pal.line),
      ),
    ),

    // LISTS / TABS / CHIPS
    listTileTheme: const ListTileThemeData(
      iconColor: Pal.parchment,
      textColor: Pal.text,
      tileColor: Colors.transparent,
      selectedTileColor: Pal.warningSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      minLeadingWidth: 28,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(GameRadius.sm)),
      ),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: Pal.goldLight,
      unselectedLabelColor: Pal.dim,
      indicatorColor: Pal.gold,
      dividerColor: Pal.line,
      labelStyle: GameText.label,
      unselectedLabelStyle: GameText.bodySmall,
      indicatorSize: TabBarIndicatorSize.label,
    ),

    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Pal.panelHi,
      selectedColor: Pal.goldDark,
      disabledColor: Pal.disabledSurface,
      secondarySelectedColor: Pal.mossDark,
      labelStyle: GameText.label,
      secondaryLabelStyle: GameText.label.copyWith(color: Pal.text),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      side: const BorderSide(color: Pal.line),
      shape: RoundedRectangleBorder(borderRadius: GameRadius.button),
    ),

    // PROGRESS / DIVIDERS
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Pal.gold,
      linearTrackColor: Pal.panelHi,
      circularTrackColor: Pal.panelHi,
      linearMinHeight: 5,
      refreshBackgroundColor: Pal.panel,
    ),

    dividerTheme: const DividerThemeData(
      color: Pal.line,
      thickness: 1,
      space: 16,
    ),

    // CONTROLS
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Pal.disabledSurface;
        }
        if (states.contains(WidgetState.selected)) {
          return Pal.gold;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Pal.ink),
      side: const BorderSide(color: Pal.lineStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Pal.disabledText;
        }
        if (states.contains(WidgetState.selected)) {
          return Pal.gold;
        }
        return Pal.dim;
      }),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Pal.goldLight;
        }
        return Pal.dim;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Pal.goldDark;
        }
        return Pal.panelHi;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Pal.lineStrong),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: Pal.gold,
      inactiveTrackColor: Pal.panelHi,
      thumbColor: Pal.goldLight,
      overlayColor: Color(0x22D9A441),
      valueIndicatorColor: Pal.goldDark,
      valueIndicatorTextStyle: GameText.label,
    ),

    // TOOLTIP / FEEDBACK
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8),
      textStyle: GameText.bodySmall.copyWith(color: Pal.text),
      decoration: BoxDecoration(
        color: Pal.panelHi,
        borderRadius: GameRadius.tooltip,
        border: const Border.fromBorderSide(GameBorders.accent),
        boxShadow: GameElevation.panel,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Pal.panelHi,
      elevation: 8,
      contentTextStyle: GameText.body,
      shape: RoundedRectangleBorder(
        borderRadius: GameRadius.button,
        side: GameBorders.accent,
      ),
    ),

    // SELECTION / SCROLLING / FOCUS
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Pal.goldLight,
      selectionColor: Color(0x66D9A441),
      selectionHandleColor: Pal.gold,
    ),

    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        Pal.lineStrong.withValues(alpha: 0.85),
      ),
      trackColor: const WidgetStatePropertyAll(Pal.bgElevated),
      radius: const Radius.circular(GameRadius.pill),
      thickness: const WidgetStatePropertyAll(5),
    ),

    focusColor: const Color(0x22D9A441),
    hoverColor: const Color(0x18D9A441),
    highlightColor: const Color(0x22D9A441),
    splashColor: const Color(0x22D9A441),
  );
}
