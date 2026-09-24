import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_list_notifier.dart';
import '../services/budget_pacing_engine.dart';
import '../widgets/budget_alert_banner.dart';
import '../widgets/budget_form_modal.dart';
import '../widgets/category_budget_bar.dart';
import 'budget_detail_screen.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  int _calculateSpentInCents(Budget budget, WidgetRef ref) {
    final txState = ref.watch(transactionListProvider);
    return txState.maybeWhen(
      data: (transactions) {
        final range = BudgetPacingEngine.getActivePeriodRange(budget, DateTime.now());
        int total = 0;
        for (var tx in transactions) {
          if (tx.type.name == 'expense') {
            if (budget.categoryId.isNotEmpty && tx.category != budget.categoryId) {
              continue;
            }
            if (tx.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
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
    final activeAlerts = ref.watch(activeBudgetAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Budget',
            onPressed: () => BudgetFormModal.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BudgetFormModal.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
      body: budgetState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load budgets',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(budgetListNotifierProvider.notifier).loadBudgets();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Budgets Set Yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a weekly, monthly, or yearly budget to track your spending and prevent blowouts.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => BudgetFormModal.show(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Budget'),
                    ),
                  ],
                ),
              ),
            );
          }

          final hasAlerts = activeAlerts.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(budgetListNotifierProvider.notifier).refreshBudgets();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: budgets.length + (hasAlerts ? 1 : 0),
              itemBuilder: (context, index) {
                if (hasAlerts && index == 0) {
                  return BudgetAlertSection(alerts: activeAlerts);
                }

                final budgetIndex = hasAlerts ? index - 1 : index;
                final budget = budgets[budgetIndex];
                final spentInCents = _calculateSpentInCents(budget, ref);
                final notifier = ref.read(budgetListNotifierProvider.notifier);
                final pacing = notifier.calculatePacing(
                  budget: budget,
                  spentInCents: spentInCents,
                );

                final statusColor = _getStatusColor(pacing.status, theme.colorScheme);
                final statusLabel = _getStatusLabel(pacing.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(context, BudgetDetailScreen.route(budget.id));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  budget.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                labelPadding: EdgeInsets.zero,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                label: Text(
                                  budget.period.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              if (budget.categoryId.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  labelPadding: EdgeInsets.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  label: Text(
                                    budget.categoryId,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          CategoryBudgetBar(
                            title: budget.name,
                            spentInCents: spentInCents,
                            allocatedInCents: budget.amountInCents,
                            progressColor: statusColor,
                            subtitle: 'Pacing: ${(pacing.elapsedFraction * 100).round()}% elapsed',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
