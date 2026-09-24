import 'package:flutter/material.dart';

class CategoryBudgetBar extends StatelessWidget {
  final String title;
  final int spentInCents;
  final int allocatedInCents;
  final Color? progressColor;
  final String? subtitle;

  const CategoryBudgetBar({
    super.key,
    required this.title,
    required this.spentInCents,
    required this.allocatedInCents,
    this.progressColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spentAmount = spentInCents / 100.0;
    final allocatedAmount = allocatedInCents / 100.0;

    double progress = 0.0;
    if (allocatedInCents > 0) {
      progress = spentInCents / allocatedInCents;
      if (progress > 1.0) progress = 1.0;
      if (progress < 0.0) progress = 0.0;
    }

    final isExceeded = spentInCents > allocatedInCents;
    final activeColor =
        progressColor ??
        (isExceeded
            ? theme.colorScheme.error
            : (progress > 0.85
                  ? Colors.orange.shade700
                  : theme.colorScheme.primary));

    final remainingCents = allocatedInCents - spentInCents;
    final remainingAmount = remainingCents / 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₹${spentAmount.toStringAsFixed(2)} / ₹${allocatedAmount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isExceeded ? theme.colorScheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Text(
                remainingCents >= 0
                    ? '₹${remainingAmount.toStringAsFixed(2)} left'
                    : 'Over by ₹${(-remainingAmount).toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: remainingCents >= 0
                      ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                      : theme.colorScheme.error,
                  fontWeight: remainingCents < 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
