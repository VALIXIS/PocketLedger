import 'package:flutter/material.dart';
import 'package:pocketledger/core/theme/app_theme.dart';

/// Flagship primary action button for PocketLedger.
///
/// Provides consistent touch target geometry (>= 48px), loading spinners
/// with zero layout-shift, Material 3 elevation, and full accessibility support.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color textColor;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final double height;
  final double? width;
  final bool isFullWidth;
  final double borderRadius;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.height = 52.0,
    this.width,
    this.isFullWidth = true,
    this.borderRadius = 14.0,
    this.elevation = 2.0,
    this.padding,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;

    final resolvedWidth = width ?? (isFullWidth ? double.infinity : null);

    final isInteractive = onPressed != null && !isLoading;

    final buttonContent = AnimatedSwitcher(
      duration: AppAnimations.fast,
      switchInCurve: AppAnimations.curveDecelerate,
      switchOutCurve: AppAnimations.curveAccelerate,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize:
                  isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: textColor),
                  const SizedBox(width: AppSpacing.space8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.2,
                        ) ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.space8),
                  Icon(trailingIcon, size: 20, color: textColor),
                ],
              ],
            ),
    );

    final button = ElevatedButton(
      onPressed: isInteractive ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        disabledBackgroundColor: disabledBackgroundColor ??
            (theme.brightness == Brightness.dark
                ? AppColors.darkSurfaceVariant
                : Colors.grey.shade300),
        disabledForegroundColor: disabledTextColor ??
            (theme.brightness == Brightness.dark
                ? AppColors.darkTextDisabled
                : Colors.grey.shade500),
        elevation: isInteractive ? (elevation ?? 2.0) : 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
        minimumSize: Size(resolvedWidth ?? 64.0, height),
      ),
      child: buttonContent,
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: resolvedWidth,
        height: height,
        child: button,
      ),
    );
  }
}
