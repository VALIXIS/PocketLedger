import 'package:flutter/material.dart';
import 'package:pocketledger/core/theme/app_theme.dart';

/// Flagship reusable card container for PocketLedger.
///
/// Supports Light, Dark, and OLED pitch-black themes, custom borders,
/// elevation shadows, gradient backgrounds, and accessible tap/long-press interactions.
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final double? radius;
  final Border? border;
  final Color? borderColor;
  final double? borderWidth;
  final double? elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final Clip clipBehavior;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.margin = const EdgeInsets.only(bottom: AppSpacing.space12),
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.borderRadius = 18.0,
    this.radius,
    this.border,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark &&
        (theme.scaffoldBackgroundColor == AppColors.oledBackground ||
            theme.scaffoldBackgroundColor == Colors.black);

    final effectiveRadius = radius ?? borderRadius;

    // Theme-adaptive surface color
    final cardColor =
        color ??
        (isOled
            ? AppColors.oledCard
            : isDark
            ? AppColors.darkCard
            : AppColors.lightCard);

    // Border determination
    final Border resolvedBorder;
    if (border != null) {
      resolvedBorder = border!;
    } else {
      final defaultBorderColor = isOled
          ? AppColors.oledBorder
          : isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);

      resolvedBorder = Border.all(
        color: borderColor ?? defaultBorderColor,
        width: borderWidth ?? 1.0,
      );
    }

    // Elevation shadows: OLED displays suppress shadows in favor of 1px border separation
    final List<BoxShadow> shadows;
    if (isOled || (elevation != null && elevation == 0)) {
      shadows = const [];
    } else if (elevation != null) {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
          blurRadius: elevation! * 4,
          offset: Offset(0, elevation! * 1.5),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: resolvedBorder,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveRadius),
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: content,
        ),
      );
    } else if (clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (semanticLabel != null || onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        container: true,
        child: content,
      );
    }

    return content;
  }
}
