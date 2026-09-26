import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/currency_formatter.dart';
import 'animated_balance_counter.dart';

/// The flagship gradient mesh balance card for PocketLedger.
///
/// Features a layered, shader-free gradient mesh treatment using Flutter-native
/// [LinearGradient] and [RadialGradient], distinct styling across Light, Dark,
/// and true OLED Pitch Black themes, and integrated animated balance counters.
class GradientBalanceCard extends StatelessWidget {
  /// Net balance in integer cents.
  final int balanceInCents;

  /// Optional previous balance in cents for smooth interpolation.
  final int? previousBalanceInCents;

  /// Currency code (e.g. 'INR', 'USD').
  final String currency;

  /// Main card title. Defaults to 'Net Balance'.
  final String title;

  /// Financial period descriptor (e.g. 'This Month', 'All Time').
  final String period;

  /// Optional percentage change (e.g. 12.4 for +12.4%, -3.2 for -3.2%).
  final double? changePercentage;

  /// Optional tap handler for opening balance breakdown or account modal.
  final VoidCallback? onTap;

  const GradientBalanceCard({
    super.key,
    required this.balanceInCents,
    this.previousBalanceInCents,
    this.currency = 'INR',
    this.title = 'Net Balance',
    this.period = 'This Month',
    this.changePercentage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark && theme.scaffoldBackgroundColor == AppColors.oledBackground;

    final formattedAmount = CurrencyFormatter.formatCents(
      balanceInCents,
      currency,
    );
    final semanticLabel = '$title, $formattedAmount';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.radius24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radius24),
          child: Container(
            width: double.infinity,
            decoration: _buildCardDecoration(context, isDark, isOled),
            padding: const EdgeInsets.all(AppSpacing.space24),
            child: Stack(
              children: [
                // Mesh accent layer (purely decorative, excluded from semantics)
                if (!isOled)
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Container(decoration: _buildMeshOverlay(isDark)),
                    ),
                  ),

                // Card Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Title & Period Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            color: isOled
                                ? AppColors.oledTextSecondary
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : Colors.white.withValues(alpha: 0.85)),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space12,
                            vertical: AppSpacing.space4,
                          ),
                          decoration: BoxDecoration(
                            color: isOled
                                ? AppColors.oledSurfaceVariant
                                : Colors.white.withValues(
                                    alpha: isDark ? 0.12 : 0.20,
                                  ),
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusFull,
                            ),
                            border: Border.all(
                              color: isOled
                                  ? AppColors.oledBorder
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            period,
                            style: TextStyle(
                              color: isOled
                                  ? AppColors.oledTextPrimary
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // Main Net Balance Counter
                    AnimatedBalanceCounter(
                      balanceInCents: balanceInCents,
                      previousBalanceInCents: previousBalanceInCents,
                      currency: currency,
                      style: TextStyle(
                        color: isOled
                            ? AppColors.oledTextPrimary
                            : Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // Bottom Row: Trend Direction & Change Percentage
                    if (changePercentage != null) ...[
                      _buildTrendIndicator(changePercentage!, isOled),
                    ] else ...[
                      // Subtle status indicator
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: isOled
                                ? AppColors.success
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: AppSpacing.space6),
                          Text(
                            'Updated Live',
                            style: TextStyle(
                              color: isOled
                                  ? AppColors.oledTextSecondary
                                  : Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(
    BuildContext context,
    bool isDark,
    bool isOled,
  ) {
    if (isOled) {
      // OLED Theme: Near-black surface with subtle 1px border and very restrained accent
      return BoxDecoration(
        color: AppColors.oledCard,
        borderRadius: BorderRadius.circular(AppRadius.radius24),
        border: Border.all(color: AppColors.oledBorder, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF141A18), // Subtle dark teal tint
            Color(0xFF0F1214), // Charcoal black
            Color(0xFF0A0A0A), // Near black
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );
    }

    if (isDark) {
      // Dark Theme: Midnight teal & charcoal depth with subtle glow
      return BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radius24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004D40), // Deep Teal
            Color(0xFF00332C),
            Color(0xFF0F1720), // Charcoal background anchor
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    // Light Theme: Rich flagship teal gradient with bright energetic accents
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.radius24),
      border: Border.all(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        width: 1,
      ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00796B), // Primary Deep Teal
          Color(0xFF00695C),
          Color(0xFF004D40), // Anchor
        ],
        stops: [0.0, 0.6, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.22),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _buildMeshOverlay(bool isDark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.radius24),
      gradient: RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 0.9,
        colors: [
          isDark
              ? AppColors.primaryLight.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double percentage, bool isOled) {
    final isPositive = percentage >= 0;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final trendColor = isOled
        ? (isPositive ? AppColors.success : AppColors.error)
        : Colors.white;

    final sign = isPositive ? '+' : '';
    final label = '$sign${percentage.toStringAsFixed(1)}% vs last month';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: isOled
            ? (isPositive
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.15))
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: trendColor),
          const SizedBox(width: AppSpacing.space4),
          Text(
            label,
            style: TextStyle(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
