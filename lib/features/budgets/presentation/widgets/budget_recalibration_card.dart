import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_recalibration_recommendation.dart';
import '../../domain/services/budget_recalibration_engine.dart';
import '../providers/budget_list_notifier.dart';

/// Interactive Material 3 card widget for AI-assisted budget cap recommendations.
class BudgetRecalibrationCard extends ConsumerWidget {
  final Budget budget;
  final int currentPeriodSpendingInCents;
  final List<int> historicalSpendingInCents;
  final BudgetRecalibrationEngine engine;
  final VoidCallback? onApplied;

  const BudgetRecalibrationCard({
    super.key,
    required this.budget,
    required this.currentPeriodSpendingInCents,
    this.historicalSpendingInCents = const [],
    this.engine = const BudgetRecalibrationEngine(),
    this.onApplied,
  });

  void _showReviewModal(
    BuildContext context,
    WidgetRef ref,
    BudgetRecalibrationRecommendation recommendation,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final diffFormatted = (recommendation.differenceInCents.abs() / 100.0)
        .toStringAsFixed(2);
    final isIncrease = recommendation.differenceInCents > 0;
    final isDecrease = recommendation.differenceInCents < 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('recalibration_review_modal'),
        title: const Text('Review Budget Recommendation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on your spending patterns and stress buffers, we suggest adjusting your "${budget.name}" budget.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Budget:'),
                      Text(
                        '\$${(recommendation.currentBudgetInCents / 100.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Suggested Budget:'),
                      Text(
                        '\$${(recommendation.recommendedBudgetInCents / 100.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Difference:'),
                      Text(
                        isIncrease
                            ? '+\$$diffFormatted'
                            : isDecrease
                            ? '-\$$diffFormatted'
                            : '\$0.00',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncrease
                              ? colorScheme.tertiary
                              : isDecrease
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will not change your budget until you confirm.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('cancel_recommendation_button'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            key: const Key('apply_recommendation_button'),
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedBudget = budget.copyWith(
                amountInCents: recommendation.recommendedBudgetInCents,
              );
              await ref
                  .read(budgetListNotifierProvider.notifier)
                  .updateBudget(updatedBudget);
              if (onApplied != null) {
                onApplied!();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Updated budget cap for "${budget.name}" to \$${(recommendation.recommendedBudgetInCents / 100.0).toStringAsFixed(2)}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Apply Recommendation'),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(
    RecommendationConfidence confidence,
    ColorScheme colorScheme,
  ) {
    switch (confidence) {
      case RecommendationConfidence.low:
        return colorScheme.tertiary;
      case RecommendationConfidence.medium:
        return colorScheme.secondary;
      case RecommendationConfidence.high:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final recommendation = engine.recommend(
      currentBudgetInCents: budget.amountInCents,
      historicalSpendingInCents: historicalSpendingInCents,
      currentPeriodSpendingInCents: currentPeriodSpendingInCents,
    );

    final confidenceColor = _getConfidenceColor(
      recommendation.confidence,
      colorScheme,
    );

    return Card(
      key: const Key('budget_recalibration_card'),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Recalibration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  key: const Key('confidence_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: confidenceColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    recommendation.confidence.label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: confidenceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'AI-assisted budget cap recommendations based on historical spending and pacing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCapTile(
                    context,
                    label: 'Current Cap',
                    amountInCents: recommendation.currentBudgetInCents,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCapTile(
                    context,
                    label: 'Recommended Cap',
                    amountInCents: recommendation.recommendedBudgetInCents,
                    isHighlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('review_recommendation_button'),
                onPressed: () => _showReviewModal(context, ref, recommendation),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Review Recommendation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapTile(
    BuildContext context, {
    required String label,
    required int amountInCents,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? colorScheme.primary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${(amountInCents / 100.0).toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? colorScheme.primary
                  : theme.textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
