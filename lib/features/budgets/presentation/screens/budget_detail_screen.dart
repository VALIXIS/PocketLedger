import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_list_notifier.dart';
import '../services/budget_pacing_engine.dart';
import '../widgets/budget_form_modal.dart';
import '../widgets/budget_recalibration_card.dart';
import '../widgets/budget_stress_test_section.dart';
import '../widgets/category_budget_bar.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  static Route<void> route(String budgetId) {
    return MaterialPageRoute(
      builder: (context) => BudgetDetailScreen(budgetId: budgetId),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete "${budget.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(budgetListNotifierProvider.notifier)
                  .deleteBudget(budget.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget "${budget.name}" deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _calculateSpentInCents(Budget budget, WidgetRef ref) {
    final txState = ref.watch(transactionListProvider);
    return txState.maybeWhen(
      data: (transactions) {
        final range = BudgetPacingEngine.getActivePeriodRange(
          budget,
          DateTime.now(),
        );
        int total = 0;
        for (var tx in transactions) {
          if (tx.type.name == 'expense') {
            if (budget.categoryId.isNotEmpty &&
                tx.category != budget.categoryId) {
              continue;
            }
            if (tx.date.isAfter(
                  range.start.subtract(const Duration(seconds: 1)),
                ) &&
                tx.date.isBefore(range.end)) {
              total += tx.amountInCents;
            }
          }
        }
        return total;
      },
      orElse: () => 0,
    );
  }

  Color _getStatusColor(BudgetPacingStatus status, ColorScheme colorScheme) {
    switch (status) {
      case BudgetPacingStatus.onTrack:
        return colorScheme.primary;
      case BudgetPacingStatus.warning:
        return colorScheme.tertiary;
      case BudgetPacingStatus.projectedToExceed:
        return colorScheme.errorContainer;
      case BudgetPacingStatus.exceeded:
        return colorScheme.error;
    }
  }

  String _getStatusLabel(BudgetPacingStatus status) {
    switch (status) {
      case BudgetPacingStatus.onTrack:
        return 'ON TRACK';
      case BudgetPacingStatus.warning:
        return 'WARNING';
      case BudgetPacingStatus.projectedToExceed:
        return 'PROJECTED TO EXCEED';
      case BudgetPacingStatus.exceeded:
        return 'EXCEEDED';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetState = ref.watch(budgetListNotifierProvider);

    return budgetState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Budget Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Budget Details')),
        body: Center(child: Text('Error loading budget: $err')),
      ),
      data: (budgets) {
        final budget = budgets.firstWhere(
          (b) => b.id == budgetId,
          orElse: () => Budget(
            id: '',
            name: 'Not Found',
            amountInCents: 0,
            period: BudgetPeriod.monthly,
            startDate: DateTime.now(),
          ),
        );

        if (budget.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Budget Details')),
            body: const Center(child: Text('Budget not found')),
          );
        }

        final spentInCents = _calculateSpentInCents(budget, ref);
        final notifier = ref.read(budgetListNotifierProvider.notifier);
        final pacing = notifier.calculatePacing(
          budget: budget,
          spentInCents: spentInCents,
        );

        final statusColor = _getStatusColor(pacing.status, theme.colorScheme);
        final statusLabel = _getStatusLabel(pacing.status);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Budget Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Budget',
                onPressed: () {
                  BudgetFormModal.show(context, existingBudget: budget);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Budget',
                onPressed: () => _confirmDelete(context, ref, budget),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                budget.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                statusLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(
                                Icons.calendar_month,
                                size: 16,
                              ),
                              label: Text(budget.period.name.toUpperCase()),
                            ),
                            if (budget.categoryId.isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.category, size: 16),
                                label: Text(budget.categoryId),
                              ),
                            Chip(
                              avatar: Icon(
                                budget.rolloverEnabled
                                    ? Icons.published_with_changes
                                    : Icons.do_not_disturb,
                                size: 16,
                              ),
                              label: Text(
                                budget.rolloverEnabled
                                    ? 'Rollover Enabled'
                                    : 'No Rollover',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CategoryBudgetBar(
                          title: 'Spending Overview',
                          spentInCents: spentInCents,
                          allocatedInCents: budget.amountInCents,
                          progressColor: statusColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pacing & Projections',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          context,
                          label: 'Projected Total Spend',
                          value:
                              '\$${(pacing.projectedSpendInCents / 100.0).toStringAsFixed(2)}',
                          isBold: true,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          context,
                          label: 'Projected Remaining',
                          value: pacing.projectedRemainingInCents >= 0
                              ? '\$${(pacing.projectedRemainingInCents / 100.0).toStringAsFixed(2)}'
                              : 'Over by \$${(-pacing.projectedRemainingInCents / 100.0).toStringAsFixed(2)}',
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          context,
                          label: 'Daily Spend Rate',
                          value:
                              '\$${(pacing.dailySpendRateInCents / 100.0).toStringAsFixed(2)} / day',
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          context,
                          label: 'Days Remaining in Period',
                          value: '${pacing.daysRemaining} days',
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          context,
                          label: 'Period Start Date',
                          value: DateFormat.yMMMd().format(budget.startDate),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BudgetStressTestSection(
                  allocationInCents: budget.amountInCents,
                  currentSpendingInCents: spentInCents,
                ),
                const SizedBox(height: 16),
                BudgetRecalibrationCard(
                  budget: budget,
                  currentPeriodSpendingInCents: spentInCents,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
