import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/currency_formatter.dart';

/// Compact, accessible income and expense summary presentation.
///
/// Employs semantic financial tokens ([AppTheme.success] and [AppTheme.error]),
/// high-contrast visual cues, and responsive horizontal or vertical flow.
class IncomeExpenseSummaryCard extends StatelessWidget {
  /// Total income in integer cents.
  final int incomeInCents;

  /// Total expenses in integer cents.
  final int expensesInCents;

  /// Currency code (e.g. 'INR', 'USD').
  final String currency;

  const IncomeExpenseSummaryCard({
    super.key,
    required this.incomeInCents,
    required this.expensesInCents,
    this.currency = 'INR',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark && theme.scaffoldBackgroundColor == AppColors.oledBackground;

    final formattedIncome = CurrencyFormatter.formatCents(
      incomeInCents,
      currency,
    );
    final formattedExpenses = CurrencyFormatter.formatCents(
      expensesInCents,
      currency,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;

        final incomeItem = _buildSummaryTile(
          context: context,
          label: 'Income',
          valueText: '+ $formattedIncome',
          semanticText: 'Income, $formattedIncome',
          icon: Icons.arrow_downward_rounded,
          color: isDark ? AppColors.success : AppColors.successDark,
          isDark: isDark,
          isOled: isOled,
        );

        final expenseItem = _buildSummaryTile(
          context: context,
          label: 'Expenses',
          valueText: '− $formattedExpenses',
          semanticText: 'Expenses, $formattedExpenses',
          icon: Icons.arrow_upward_rounded,
          color: isDark ? AppColors.error : AppColors.errorDark,
          isDark: isDark,
          isOled: isOled,
        );

        if (isCompact) {
          return Column(
            children: [
              incomeItem,
              const SizedBox(height: AppSpacing.space12),
              expenseItem,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: incomeItem),
            const SizedBox(width: AppSpacing.space12),
            Expanded(child: expenseItem),
          ],
        );
      },
    );
  }

  Widget _buildSummaryTile({
    required BuildContext context,
    required String label,
    required String valueText,
    required String semanticText,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isOled,
  }) {
    final cardBg = isOled
        ? AppColors.oledCard
        : (isDark ? AppColors.darkCard : AppColors.lightCard);

    final borderColor = isOled
        ? AppColors.oledBorder
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Semantics(
      label: semanticText,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.radius16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isOled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: AppSpacing.space8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOled
                          ? AppColors.oledTextSecondary
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              valueText,
              style: TextStyle(
                color: isOled
                    ? AppColors.oledTextPrimary
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
