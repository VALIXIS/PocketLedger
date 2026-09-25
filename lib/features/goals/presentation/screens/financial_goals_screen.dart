import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/financial_goal.dart';
import '../providers/goal_list_notifier.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_empty_state.dart';
import '../widgets/goal_form.dart';
import '../widgets/goal_progress_indicator.dart';

enum GoalFilter { all, active, completed }

class FinancialGoalsScreen extends ConsumerStatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  ConsumerState<FinancialGoalsScreen> createState() =>
      _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends ConsumerState<FinancialGoalsScreen> {
  GoalFilter _selectedFilter = GoalFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(settingsProvider).currency;
    final goalState = ref.watch(goalListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Savings Goals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Goal',
            onPressed: () => GoalForm.showAddGoal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(goalListNotifierProvider.notifier).refresh();
        },
        child: _buildBody(context, goalState, currency, isDark, theme),
      ),
      floatingActionButton: goalState.goals.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => GoalForm.showAddGoal(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Goal'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    GoalListState state,
    String currency,
    bool isDark,
    ThemeData theme,
  ) {
    if (state.isLoading && state.goals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Failed to load goals',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  ref.read(goalListNotifierProvider.notifier).loadGoals();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.goals.isEmpty) {
      return GoalEmptyState(
        onAddGoalPressed: () => GoalForm.showAddGoal(context),
      );
    }

    // Filter goals
    final filteredGoals = state.goals.where((g) {
      switch (_selectedFilter) {
        case GoalFilter.all:
          return true;
        case GoalFilter.active:
          return g.status == GoalStatus.active && !g.isCompleted;
        case GoalFilter.completed:
          return g.isCompleted || g.status == GoalStatus.completed;
      }
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final isExtraWide = constraints.maxWidth >= 1150;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Header Card
                    _buildSummaryHeader(state.goals, currency, isDark, theme),
                    const SizedBox(height: 16),

                    // Filter Chips
                    _buildFilterChips(state.goals, theme),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (filteredGoals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No goals in this category',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (!isWide)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final goal = filteredGoals[index];
                    return GoalCard(goal: goal);
                  }, childCount: filteredGoals.length),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isExtraWide ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 300,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final goal = filteredGoals[index];
                    return GoalCard(goal: goal);
                  }, childCount: filteredGoals.length),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(
    List<FinancialGoal> goals,
    String currency,
    bool isDark,
    ThemeData theme,
  ) {
    int totalTargetCents = 0;
    int totalSavedCents = 0;
    int completedCount = 0;

    for (final goal in goals) {
      totalTargetCents += goal.targetAmountInCents;
      totalSavedCents += goal.savedAmountInCents;
      if (goal.isCompleted) {
        completedCount++;
      }
    }

    final overallProgress = totalTargetCents > 0
        ? (totalSavedCents / totalTargetCents)
        : 0.0;
    final clampedProgress = overallProgress > 1.0
        ? 1.0
        : (overallProgress < 0.0 ? 0.0 : overallProgress);
    final percentage = (clampedProgress * 100).toStringAsFixed(1);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? const Color(0xFF1E1E1E)
          : theme.colorScheme.primaryContainer,
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
                      Icons.savings_outlined,
                      color: isDark
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOTAL SAVINGS PROGRESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark
                            ? Colors.grey.shade400
                            : theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.teal.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount of ${goals.length} Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.tealAccent
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.formatCents(totalSavedCents, currency),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${CurrencyFormatter.formatCents(totalTargetCents, currency)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.tealAccent
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GoalProgressIndicator(
              progress: clampedProgress,
              color: isDark ? Colors.tealAccent : theme.colorScheme.primary,
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<FinancialGoal> goals, ThemeData theme) {
    final activeCount = goals
        .where((g) => g.status == GoalStatus.active && !g.isCompleted)
        .length;
    final completedCount = goals
        .where((g) => g.isCompleted || g.status == GoalStatus.completed)
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: Text('All (${goals.length})'),
            selected: _selectedFilter == GoalFilter.all,
            onSelected: (selected) {
              if (selected) setState(() => _selectedFilter = GoalFilter.all);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Active ($activeCount)'),
            selected: _selectedFilter == GoalFilter.active,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = GoalFilter.active);
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Completed ($completedCount)'),
            selected: _selectedFilter == GoalFilter.completed,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = GoalFilter.completed);
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
