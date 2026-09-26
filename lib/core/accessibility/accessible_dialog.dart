import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'a11y_colors.dart';
import 'a11y_theme.dart';

/// Displays a WCAG AAA compliant alert dialog with high-contrast text,
/// accessible action buttons, scrollable content for large text scalers,
/// and screen reader semantics.
Future<T?> showAccessibleAlertDialog<T>({
  required BuildContext context,
  required String title,
  Widget? content,
  String? contentText,
  List<Widget>? actions,
  bool barrierDismissible = true,
  String? barrierLabel,
  String? semanticLabel,
  bool isDestructive = false,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isOled = theme.scaffoldBackgroundColor == Colors.black;

  final accessibleTheme = AccessibilityTheme.apply(
    theme,
    dark: isDark,
    isOled: isOled,
  );

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'Alert dialog',
    builder: (dialogContext) {
      final dialogContent =
          content ??
          (contentText != null
              ? Text(
                  contentText,
                  style: TextStyle(
                    color: isDark
                        ? A11yColors.darkTextSecondary
                        : A11yColors.lightTextSecondary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                )
              : null);

      return Theme(
        data: accessibleTheme,
        child: Semantics(
          label: semanticLabel ?? title,
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          container: true,
          child: AlertDialog(
            title: Row(
              children: [
                if (isDestructive) ...[
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isDark
                        ? A11yColors.darkError
                        : A11yColors.lightError,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark
                          ? A11yColors.darkTextPrimary
                          : A11yColors.lightTextPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: dialogContent != null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: dialogContent,
                    ),
                  )
                : null,
            actions: actions,
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
          ),
        ),
      );
    },
  );
}
