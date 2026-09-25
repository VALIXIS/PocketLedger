import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pocketledger/core/theme/app_theme.dart';

/// Premium glassmorphic (frosted glass) card container for PocketLedger.
///
/// Combines [BackdropFilter] background blur, translucent theme-adaptive tints,
/// and frosted borders while maintaining high 60/120fps scrolling performance.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? borderGradient;
  final BoxBorder? border;
  final double? elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final Clip clipBehavior;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AppRadius.radius16,
    this.blur = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderGradient,
    this.border,
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

    // Theme-adaptive translucent background tint
    final Color defaultBgColor;
    if (isOled) {
      defaultBgColor = AppColors.oledCard.withValues(alpha: 0.85);
    } else if (isDark) {
      defaultBgColor = AppColors.darkSurface.withValues(alpha: 0.65);
    } else {
      defaultBgColor = Colors.white.withValues(alpha: 0.72);
    }
    final effectiveBgColor = backgroundColor ?? defaultBgColor;

    // Default border color when no gradient or custom border provided
    final Color defaultBorderColor = isOled
        ? AppColors.oledBorder
        : isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.40);

    // Subtle elevation shadow
    final List<BoxShadow> shadows;
    if (isOled || (elevation != null && elevation == 0)) {
      shadows = const [];
    } else if (elevation != null) {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
          blurRadius: elevation! * 4,
          offset: Offset(0, elevation! * 1.5),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // Inner blurred container
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      color: effectiveBgColor,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    Widget blurredWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: cardContent,
      ),
    );

    // Build border and shadow wrapper
    Widget styledCard;
    if (borderGradient != null) {
      styledCard = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
          gradient: borderGradient,
        ),
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (borderRadius - borderWidth).clamp(0.0, double.infinity),
          ),
          clipBehavior: clipBehavior,
          child: blurredWidget,
        ),
      );
    } else {
      final resolvedBorder =
          border ??
          Border.all(
            color: borderColor ?? defaultBorderColor,
            width: borderWidth,
          );

      styledCard = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: resolvedBorder,
          boxShadow: shadows,
        ),
        child: blurredWidget,
      );
    }

    if (margin != null) {
      styledCard = Padding(padding: margin!, child: styledCard);
    }

    if (semanticLabel != null || onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        container: true,
        child: styledCard,
      );
    }

    return styledCard;
  }
}
