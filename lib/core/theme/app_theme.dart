import 'package:flutter/material.dart';
import '../accessibility/a11y_theme.dart';

/// Centralized color tokens for PocketLedger.
///
/// Contains brand identity, financial semantics, light surfaces, dark charcoal
/// surfaces, and OLED pitch black surfaces.
abstract final class AppColors {
  // Brand Identity
  static const Color primary = Color(0xFF00796B); // Deep Fintech Teal
  static const Color primaryLight = Color(0xFF26A69A); // Teal 400
  static const Color primaryDark = Color(0xFF004D40); // Teal 900
  static const Color secondary = Color(0xFF0D9488); // Cyan Teal Accent
  static const Color secondaryLight = Color(0xFF5EEAD4); // Teal 300
  static const Color secondaryDark = Color(0xFF0F766E); // Teal 700

  // Financial Semantics
  static const Color success = Color(
    0xFF10B981,
  ); // Emerald 500 (Income/Positive)
  static const Color successDark = Color(0xFF059669); // Emerald 600
  static const Color warning = Color(0xFFF59E0B); // Amber 500 (Budget Warning)
  static const Color warningDark = Color(0xFFD97706); // Amber 600
  static const Color error = Color(0xFFEF4444); // Red 500 (Expense/Deficit)
  static const Color errorDark = Color(0xFFDC2626); // Red 600
  static const Color info = Color(0xFF3B82F6); // Blue 500 (Insights/Info)
  static const Color infoDark = Color(0xFF2563EB); // Blue 600

  // Light Surfaces & Content
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color lightCard = Color(0xFFFFFFFF); // Card Surface
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextDisabled = Color(0xFF94A3B8); // Slate 400
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Surfaces & Content (Charcoal)
  static const Color darkBackground = Color(0xFF0F1720); // Midnight Charcoal
  static const Color darkSurface = Color(0xFF161F28); // Elevated Charcoal
  static const Color darkSurfaceVariant = Color(0xFF1E293B); // Slate 800
  static const Color darkCard = Color(0xFF1A242D); // Dark Card Surface
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextDisabled = Color(0xFF64748B); // Slate 500
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  // OLED Pitch Black Surfaces & Content
  static const Color oledBackground = Color(
    0xFF000000,
  ); // True #000000 Pitch Black
  static const Color oledSurface = Color(0xFF0A0A0A); // Near-black Surface
  static const Color oledCard = Color(0xFF121212); // Subtle Card Separation
  static const Color oledSurfaceVariant = Color(0xFF18181B); // Zinc 900
  static const Color oledTextPrimary = Color(0xFFFFFFFF); // True White
  static const Color oledTextSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color oledTextDisabled = Color(0xFF52525B); // Zinc 600
  static const Color oledBorder = Color(0xFF27272A); // Zinc 800
}

/// 4/8-point spacing tokens for consistent financial UI layouts.
abstract final class AppSpacing {
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;
}

/// Geometric corner radius tokens.
abstract final class AppRadius {
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radiusFull = 9999.0;
}

/// Elevation tokens with restrained fintech elevation values.
abstract final class AppElevation {
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;
}

/// Micro-interaction and transition animation tokens.
abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);

  // Micro-interaction curves
  static const Curve curveDefault = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccelerate = Curves.easeInCubic;
  static const Curve curveSpring = Curves.easeOutBack;
}

/// Responsive layout breakpoints and content dimension constraints.
abstract final class AppBreakpoints {
  static const double phone = 0.0;
  static const double tablet = 600.0;
  static const double desktop = 1024.0;
  static const double wideDesktop = 1440.0;
  static const double maxContentWidth = 1280.0;
}

/// Centralized Material 3 reusable shape definitions.
abstract final class AppShapes {
  static final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.radius16),
  );

  static final RoundedRectangleBorder largeCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.radius24),
  );

  static final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.radius12),
  );

  static final RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.radius20),
  );

  static const RoundedRectangleBorder bottomSheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppRadius.radius24),
    ),
  );
}

/// Material 3 TextTheme generator providing strict financial-dashboard hierarchy.
abstract final class AppTypography {
  static TextTheme buildTextTheme({
    required Color primaryText,
    required Color secondaryText,
    required Color disabledText,
  }) {
    return TextTheme(
      // Display: High-impact financial statements, portfolio hero values
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: primaryText,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        height: 1.16,
        color: primaryText,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.22,
        color: primaryText,
      ),

      // Headline: Section hero metrics, screen headers
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.25,
        color: primaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.29,
        color: primaryText,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.33,
        color: primaryText,
      ),

      // Title: Card titles, modal headers, list section headers
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.27,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.50,
        color: primaryText,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: primaryText,
      ),

      // Body: General content, descriptions, transaction meta
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        color: primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: secondaryText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: disabledText,
      ),

      // Label: Button text, badges, input labels, captions
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: primaryText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: secondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: disabledText,
      ),
    );
  }
}

/// Principal design system theme provider for PocketLedger.
///
/// Exposes complete, accessible Material 3 [light], [dark], and [oled] themes
/// alongside direct access to all design tokens.
class AppTheme {
  // Legacy constants for backwards compatibility
  static const Color primaryTeal = AppColors.primary;
  static const Color primaryTealLight = AppColors.primaryLight;
  static const Color darkScaffoldBg = AppColors.darkBackground;
  static const Color darkCardBg = AppColors.darkCard;
  static const Color lightScaffoldBg = AppColors.lightBackground;

  // Color tokens
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color secondary = AppColors.secondary;
  static const Color secondaryLight = AppColors.secondaryLight;
  static const Color secondaryDark = AppColors.secondaryDark;

  static const Color success = AppColors.success;
  static const Color successDark = AppColors.successDark;
  static const Color warning = AppColors.warning;
  static const Color warningDark = AppColors.warningDark;
  static const Color error = AppColors.error;
  static const Color errorDark = AppColors.errorDark;
  static const Color info = AppColors.info;
  static const Color infoDark = AppColors.infoDark;

  // Spacing tokens
  static const double space2 = AppSpacing.space2;
  static const double space4 = AppSpacing.space4;
  static const double space6 = AppSpacing.space6;
  static const double space8 = AppSpacing.space8;
  static const double space12 = AppSpacing.space12;
  static const double space16 = AppSpacing.space16;
  static const double space20 = AppSpacing.space20;
  static const double space24 = AppSpacing.space24;
  static const double space32 = AppSpacing.space32;
  static const double space40 = AppSpacing.space40;
  static const double space48 = AppSpacing.space48;
  static const double space64 = AppSpacing.space64;

  // Radius tokens
  static const double radius4 = AppRadius.radius4;
  static const double radius8 = AppRadius.radius8;
  static const double radius12 = AppRadius.radius12;
  static const double radius16 = AppRadius.radius16;
  static const double radius20 = AppRadius.radius20;
  static const double radius24 = AppRadius.radius24;
  static const double radius28 = AppRadius.radius28;
  static const double radiusFull = AppRadius.radiusFull;

  // Elevation tokens
  static const double elevation0 = AppElevation.elevation0;
  static const double elevation1 = AppElevation.elevation1;
  static const double elevation2 = AppElevation.elevation2;
  static const double elevation4 = AppElevation.elevation4;
  static const double elevation8 = AppElevation.elevation8;

  // Animation tokens
  static const Duration animationFast = AppAnimations.fast;
  static const Duration animationNormal = AppAnimations.normal;
  static const Duration animationMedium = AppAnimations.medium;
  static const Duration animationSlow = AppAnimations.slow;
  static const Curve curveDefault = AppAnimations.curveDefault;
  static const Curve curveDecelerate = AppAnimations.curveDecelerate;
  static const Curve curveAccelerate = AppAnimations.curveAccelerate;
  static const Curve curveSpring = AppAnimations.curveSpring;

  // Responsive breakpoints
  static const double breakpointPhone = AppBreakpoints.phone;
  static const double breakpointTablet = AppBreakpoints.tablet;
  static const double breakpointDesktop = AppBreakpoints.desktop;
  static const double breakpointWideDesktop = AppBreakpoints.wideDesktop;
  static const double maxContentWidth = AppBreakpoints.maxContentWidth;

  // Reusable shapes
  static final ShapeBorder cardShape = AppShapes.cardShape;
  static final ShapeBorder largeCardShape = AppShapes.largeCardShape;
  static final ShapeBorder buttonShape = AppShapes.buttonShape;
  static final ShapeBorder dialogShape = AppShapes.dialogShape;
  static const ShapeBorder bottomSheetShape = AppShapes.bottomSheetShape;

  // Backwards compatible getters
  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;
  static ThemeData get oledTheme => oled;

  /// Enterprise Light Theme for PocketLedger.
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0F2F1), // Teal 50
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFCCFBF1), // Teal 100
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDBEAFE),
      onTertiaryContainer: AppColors.infoDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      outlineVariant: Color(0xFFCBD5E1),
      shadow: Color(0x0D000000), // Subtle 5% shadow
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.lightBackground,
      cardBg: AppColors.lightCard,
      surfaceVariant: AppColors.lightSurfaceVariant,
      border: AppColors.lightBorder,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      disabledText: AppColors.lightTextDisabled,
      elevation: AppElevation.elevation1,
      isOled: false,
    );
  }

  /// Enterprise Dark Theme (Midnight Charcoal) for PocketLedger.
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Color(0xFF003730),
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Color(0xFFE0F2F1),
      secondary: AppColors.secondaryLight,
      onSecondary: Color(0xFF003831),
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: Color(0xFFCCFBF1),
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF1E3A8A),
      onTertiaryContainer: Color(0xFFDBEAFE),
      error: AppColors.error,
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: Color(0xFF475569),
      shadow: Color(0x40000000), // 25% shadow
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.darkBackground,
      cardBg: AppColors.darkCard,
      surfaceVariant: AppColors.darkSurfaceVariant,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      disabledText: AppColors.darkTextDisabled,
      elevation: AppElevation.elevation1,
      isOled: false,
    );
  }

  /// Enterprise OLED Pitch Black Theme for PocketLedger.
  ///
  /// Optimized for maximum power efficiency on OLED displays with true #000000
  /// scaffold background, flat surfaces, and sharp accessible 1px borders.
  static ThemeData get oled {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.black,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Color(0xFFE0F2F1),
      secondary: AppColors.secondaryLight,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: Color(0xFFCCFBF1),
      tertiary: AppColors.info,
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFF172554),
      onTertiaryContainer: Color(0xFFDBEAFE),
      error: AppColors.error,
      onError: Colors.black,
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: AppColors.oledSurface,
      onSurface: AppColors.oledTextPrimary,
      surfaceContainerHighest: AppColors.oledSurfaceVariant,
      onSurfaceVariant: AppColors.oledTextSecondary,
      outline: AppColors.oledBorder,
      outlineVariant: Color(0xFF3F3F46),
      shadow: Colors.transparent,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.oledBackground,
      cardBg: AppColors.oledCard,
      surfaceVariant: AppColors.oledSurfaceVariant,
      border: AppColors.oledBorder,
      textPrimary: AppColors.oledTextPrimary,
      textSecondary: AppColors.oledTextSecondary,
      disabledText: AppColors.oledTextDisabled,
      elevation: AppElevation.elevation0,
      isOled: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardBg,
    required Color surfaceVariant,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color disabledText,
    required double elevation,
    required bool isOled,
  }) {
    final textTheme = AppTypography.buildTextTheme(
      primaryText: textPrimary,
      secondaryText: textSecondary,
      disabledText: disabledText,
    );

    final isLight = colorScheme.brightness == Brightness.light;

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: elevation,
        shadowColor: colorScheme.shadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius16),
          side: BorderSide(
            color: isOled ? border : border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: AppElevation.elevation0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
      ),

      // Navigation Bar Theme (for 5-tab shell)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isOled
            ? Colors.black
            : (isLight ? colorScheme.surface : cardBg),
        elevation: isOled ? AppElevation.elevation0 : AppElevation.elevation2,
        shadowColor: colorScheme.shadow,
        height: 68,
        indicatorColor: colorScheme.primary.withValues(
          alpha: isLight ? 0.12 : (isOled ? 0.25 : 0.20),
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius16),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isOled
            ? AppColors.oledSurface
            : (isLight ? Colors.white : cardBg),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          borderSide: BorderSide(
            color: border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        hintStyle: TextStyle(
          color: disabledText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: disabledText.withValues(alpha: 0.2),
          disabledForegroundColor: disabledText,
          elevation: isOled ? AppElevation.elevation0 : AppElevation.elevation1,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space20,
            vertical: AppSpacing.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: disabledText,
          side: BorderSide(color: border, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space20,
            vertical: AppSpacing.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: disabledText,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: isOled ? AppElevation.elevation0 : AppElevation.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius20),
          side: isOled ? BorderSide(color: border, width: 1) : BorderSide.none,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 15,
          height: 1.4,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        modalBackgroundColor: cardBg,
        elevation: isOled ? AppElevation.elevation0 : AppElevation.elevation4,
        modalElevation: isOled
            ? AppElevation.elevation0
            : AppElevation.elevation4,
        shape: AppShapes.bottomSheetShape,
        showDragHandle: true,
        dragHandleColor: disabledText,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        contentTextStyle: TextStyle(
          color: isLight ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: isLight ? AppColors.primaryLight : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
        elevation: AppElevation.elevation4,
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledText.withValues(alpha: 0.3);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius4),
        ),
        side: BorderSide(color: border, width: 1.5),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledText.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledText.withValues(alpha: 0.2);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return border;
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        disabledColor: surfaceVariant.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
        side: BorderSide(color: border, width: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
      ),

      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        color: cardBg,
        elevation: isOled ? AppElevation.elevation0 : AppElevation.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          side: BorderSide(color: border, width: 1),
        ),
        textStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space4,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 13),
        iconColor: textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.15),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.15),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(AppRadius.radius8),
        ),
        textStyle: TextStyle(
          color: isLight ? Colors.white : const Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space6,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isOled ? AppElevation.elevation0 : AppElevation.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius16),
        ),
      ),
    );

    return AccessibilityTheme.apply(baseTheme, dark: !isLight, isOled: isOled);
  }
}
