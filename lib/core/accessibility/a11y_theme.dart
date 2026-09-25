import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'a11y_colors.dart';

/// Centralized accessibility theme engine that hardens [ThemeData] to meet
/// strict WCAG 2.1 Level AAA contrast ratios across Light, Dark, and OLED modes.
abstract final class AccessibilityTheme {
  /// Hardens [base] theme with mathematically verified high-contrast tokens,
  /// minimum touch targets (>= 48dp), high-visibility focus borders,
  /// accessible form fields, dialogs, and date pickers.
  static ThemeData apply(
    ThemeData base, {
    required bool dark,
    bool isOled = false,
  }) {
    final bg = isOled
        ? A11yColors.oledBackground
        : (dark ? A11yColors.darkBackground : A11yColors.lightBackground);

    final surface = isOled
        ? A11yColors.oledSurface
        : (dark ? A11yColors.darkSurface : Colors.white);

    final textPrimary = dark
        ? A11yColors.darkTextPrimary
        : A11yColors.lightTextPrimary;
    final textSecondary = dark
        ? A11yColors.darkTextSecondary
        : A11yColors.lightTextSecondary;
    final textHint = dark ? A11yColors.darkTextHint : A11yColors.lightTextHint;
    final errorColor = dark ? A11yColors.darkError : A11yColors.lightError;
    final borderColor = isOled
        ? A11yColors.oledBorder
        : (dark ? A11yColors.darkBorder : A11yColors.lightBorder);
    final focusColor = dark
        ? A11yColors.darkFocusRing
        : A11yColors.lightFocusRing;

    // Hardened ColorScheme
    final colorScheme = base.colorScheme.copyWith(
      surface: surface,
      onSurface: textPrimary,
      error: errorColor,
      onError: dark ? Colors.black : Colors.white,
      outline: borderColor,
    );

    // Hardened TextTheme
    final textTheme = base.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    // Hardened Input Decoration Theme
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        borderSide: BorderSide(color: focusColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        borderSide: BorderSide(color: errorColor, width: 2.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      hintStyle: TextStyle(
        color: textHint,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: focusColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: TextStyle(
        color: textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: TextStyle(
        color: errorColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    );

    // Hardened Dialog Theme
    final dialogTheme = DialogThemeData(
      backgroundColor: surface,
      elevation: isOled ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius20),
        side: BorderSide(color: borderColor, width: isOled ? 1.0 : 0.5),
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: textSecondary,
        fontSize: 15,
        height: 1.45,
      ),
    );

    // Hardened DatePicker Theme
    final datePickerTheme = DatePickerThemeData(
      backgroundColor: surface,
      headerBackgroundColor: dark
          ? A11yColors.darkSurface
          : A11yColors.lightBlue,
      headerForegroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius24),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return textHint.withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return focusColor;
        }
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return focusColor;
      }),
      todayBorder: BorderSide(color: focusColor, width: 1.5),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return textHint.withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return textPrimary;
      }),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: textSecondary,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: focusColor,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );

    // Hardened Button Themes
    final textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: focusColor,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );

    final outlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: focusColor,
        side: BorderSide(color: borderColor, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space20,
          vertical: AppSpacing.space12,
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: textTheme,
      inputDecorationTheme: inputDecorationTheme,
      dialogTheme: dialogTheme,
      datePickerTheme: datePickerTheme,
      textButtonTheme: textButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      focusColor: focusColor.withValues(alpha: 0.2),
    );
  }
}
