import 'package:flutter/material.dart';
import 'package:pocketledger/core/theme/app_theme.dart';
import 'package:pocketledger/core/widgets/custom_card.dart';

/// Animated statistic metric tile for PocketLedger financial dashboards.
///
/// Features smooth number rollup counter animations via [TweenAnimationBuilder],
/// trend percentage indicators (with customizable polarity), icon badges,
/// reduced-motion accessibility overrides, and full Light/Dark/OLED support.
class AnimatedStatTile extends StatelessWidget {
  final String title;
  final double value;
  final String prefix;
  final String suffix;
  final int decimalDigits;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? trendPercentage;
  final String? trendLabel;
  final bool isPositiveGood;
  final VoidCallback? onTap;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final String? semanticLabel;

  const AnimatedStatTile({
    super.key,
    required this.title,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimalDigits = 2,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trendPercentage,
    this.trendLabel,
    this.isPositiveGood = true,
    this.onTap,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.curveDecelerate,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.margin = const EdgeInsets.only(bottom: AppSpacing.space12),
    this.color,
    this.semanticLabel,
  });

  String _formatNumber(double val) {
    final isNegative = val < 0;
    final absVal = val.abs();
    final fixed = absVal.toStringAsFixed(decimalDigits);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formatted = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    return '${isNegative ? '-' : ''}$prefix$formatted$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Trend styling
    final hasTrend = trendPercentage != null;
    final isUp = (trendPercentage ?? 0.0) >= 0;
    final bool isBeneficial = isPositiveGood ? isUp : !isUp;

    final Color trendColor = isBeneficial
        ? (isDark ? AppColors.success : AppColors.successDark)
        : (isDark ? AppColors.error : AppColors.errorDark);

    final trendBgColor = trendColor.withValues(alpha: isDark ? 0.16 : 0.10);

    // Primary Text colors
    final titleStyle =
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          fontSize: 13,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        );

    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveIconBg =
        iconBackgroundColor ??
        effectiveIconColor.withValues(alpha: isDark ? 0.16 : 0.10);

    return CustomCard(
      padding: padding,
      margin: margin,
      color: color,
      onTap: onTap,
      semanticLabel:
          semanticLabel ??
          '$title: ${_formatNumber(value)}${hasTrend ? ", trend: ${trendPercentage! >= 0 ? "up" : "down"} ${trendPercentage!.abs().toStringAsFixed(1)}%" : ""}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Title & Optional Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space8),
                  decoration: BoxDecoration(
                    color: effectiveIconBg,
                    borderRadius: BorderRadius.circular(AppRadius.radius12),
                  ),
                  child: Icon(icon, size: 18, color: effectiveIconColor),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),

          // Rollup Numeric Value Counter
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: value),
            duration: disableAnimations ? Duration.zero : duration,
            curve: curve,
            builder: (context, animValue, _) {
              return Text(
                _formatNumber(animValue),
                style:
                    theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ) ??
                    const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),

          // Optional Trend Indicator Row
          if (hasTrend) ...[
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space8,
                    vertical: AppSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: trendBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: trendColor,
                      ),
                      const SizedBox(width: AppSpacing.space4),
                      Text(
                        '${trendPercentage!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trendLabel != null) ...[
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      trendLabel!,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.65,
                            ),
                          ) ??
                          const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
