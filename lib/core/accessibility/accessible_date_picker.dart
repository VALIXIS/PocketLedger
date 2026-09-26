import 'package:flutter/material.dart';
import 'a11y_theme.dart';

/// Shows a WCAG AAA hardened [DatePickerDialog] applying deliberate high-contrast
/// date selections, accessible cancellation/confirmation targets, and semantic labels.
Future<DateTime?> showAccessibleDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  SelectableDayPredicate? selectableDayPredicate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  TextDirection? textDirection,
  TransitionBuilder? builder,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
  String? errorFormatText,
  String? errorInvalidText,
  String? fieldHintText,
  String? fieldLabelText,
}) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isOled = theme.scaffoldBackgroundColor == Colors.black;

  final accessibleTheme = AccessibilityTheme.apply(
    theme,
    dark: isDark,
    isOled: isOled,
  );

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    initialEntryMode: initialEntryMode,
    selectableDayPredicate: selectableDayPredicate,
    helpText: helpText ?? 'Select Date',
    cancelText: cancelText ?? 'Cancel',
    confirmText: confirmText ?? 'Select',
    locale: locale,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    textDirection: textDirection,
    initialDatePickerMode: initialDatePickerMode,
    errorFormatText: errorFormatText,
    errorInvalidText: errorInvalidText,
    fieldHintText: fieldHintText,
    fieldLabelText: fieldLabelText,
    barrierLabel: 'Date selection dialog',
    builder: (context, child) {
      final customizedChild = Theme(
        data: accessibleTheme,
        child: child ?? const SizedBox.shrink(),
      );
      if (builder != null) {
        return builder(context, customizedChild);
      }
      return customizedChild;
    },
  );
}

/// Shows a WCAG AAA hardened [DateRangePickerDialog].
Future<DateTimeRange?> showAccessibleDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? saveText,
  String? errorFormatText,
  String? errorInvalidText,
  String? errorInvalidRangeText,
  String? fieldStartHintText,
  String? fieldEndHintText,
  String? fieldStartLabelText,
  String? fieldEndLabelText,
  Locale? locale,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  TextDirection? textDirection,
  TransitionBuilder? builder,
}) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isOled = theme.scaffoldBackgroundColor == Colors.black;

  final accessibleTheme = AccessibilityTheme.apply(
    theme,
    dark: isDark,
    isOled: isOled,
  );

  return showDateRangePicker(
    context: context,
    initialDateRange: initialDateRange,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    initialEntryMode: initialEntryMode,
    helpText: helpText ?? 'Select Date Range',
    cancelText: cancelText ?? 'Cancel',
    confirmText: confirmText ?? 'Select',
    saveText: saveText ?? 'Save',
    errorFormatText: errorFormatText,
    errorInvalidText: errorInvalidText,
    errorInvalidRangeText: errorInvalidRangeText,
    fieldStartHintText: fieldStartHintText,
    fieldEndHintText: fieldEndHintText,
    fieldStartLabelText: fieldStartLabelText,
    fieldEndLabelText: fieldEndLabelText,
    locale: locale,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    textDirection: textDirection,
    barrierLabel: 'Date range selection dialog',
    builder: (context, child) {
      final customizedChild = Theme(
        data: accessibleTheme,
        child: child ?? const SizedBox.shrink(),
      );
      if (builder != null) {
        return builder(context, customizedChild);
      }
      return customizedChild;
    },
  );
}
