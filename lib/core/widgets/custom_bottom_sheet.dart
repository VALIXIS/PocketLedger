import 'package:flutter/material.dart';
import 'package:pocketledger/core/theme/app_theme.dart';

/// Flagship modal bottom sheet wrapper for PocketLedger.
///
/// Features Material 3 rounded top corners, centered drag handle,
/// keyboard-aware padding, safe area compliance, theme-adaptive surfaces
/// (including OLED pitch black), and accessible dismiss actions.
class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final bool showCloseButton;
  final bool showDragHandle;
  final EdgeInsetsGeometry padding;
  final double maxHeightFraction;
  final Color? backgroundColor;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.showCloseButton = true,
    this.showDragHandle = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space20,
      vertical: AppSpacing.space16,
    ),
    this.maxHeightFraction = 0.85,
    this.backgroundColor,
  });

  /// Displays the flagship [CustomBottomSheet] via [showModalBottomSheet].
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool showCloseButton = true,
    bool showDragHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    double maxHeightFraction = 0.85,
    Color? backgroundColor,
    RouteSettings? routeSettings,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      routeSettings: routeSettings,
      builder: (modalContext) => CustomBottomSheet(
        title: title,
        trailing: trailing,
        showCloseButton: showCloseButton,
        showDragHandle: showDragHandle,
        maxHeightFraction: maxHeightFraction,
        backgroundColor: backgroundColor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark &&
        (theme.scaffoldBackgroundColor == AppColors.oledBackground ||
            theme.scaffoldBackgroundColor == Colors.black);

    // Surface color
    final effectiveBgColor =
        backgroundColor ??
        (isOled
            ? AppColors.oledCard
            : isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface);

    // Drag handle color
    final handleColor = isOled
        ? AppColors.oledBorder
        : isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.15);

    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * maxHeightFraction;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius24),
        ),
        border: isOled
            ? const Border(
                top: BorderSide(color: AppColors.oledBorder, width: 1.0),
                left: BorderSide(color: AppColors.oledBorder, width: 1.0),
                right: BorderSide(color: AppColors.oledBorder, width: 1.0),
              )
            : null,
        boxShadow: isOled
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              if (showDragHandle) ...[
                const SizedBox(height: AppSpacing.space12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
              ],

              // Header (if title, trailing, or close button present)
              if (title != null || trailing != null || showCloseButton) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space20,
                    vertical: AppSpacing.space8,
                  ),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style:
                                theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ) ??
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (trailing != null) ...[
                        trailing!,
                        const SizedBox(width: AppSpacing.space8),
                      ],
                      if (showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 20,
                        ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isOled
                      ? AppColors.oledBorder
                      : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ],

              // Sheet Body
              Flexible(
                child: SingleChildScrollView(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
