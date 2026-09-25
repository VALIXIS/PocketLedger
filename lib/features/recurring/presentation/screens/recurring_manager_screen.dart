import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/recurring_transaction.dart';
import '../providers/recurring_list_notifier.dart';
import '../providers/upcoming_payment_countdown.dart';
import '../widgets/cancellation_reminder_card.dart';
import '../widgets/recurrence_cycle_chip.dart';
import '../widgets/recurring_empty_state.dart';
import '../widgets/recurring_filter_bar.dart';
import '../widgets/recurring_form.dart';
import '../widgets/recurring_summary.dart';
import '../widgets/recurring_transaction_card.dart';
import '../widgets/renewal_alert_card.dart';

class RecurringManagerScreen extends ConsumerStatefulWidget {
  const RecurringManagerScreen({super.key});

  @override
  ConsumerState<RecurringManagerScreen> createState() =>
      _RecurringManagerScreenState();
}

class _RecurringManagerScreenState
    extends ConsumerState<RecurringManagerScreen> {
  CycleFilter _selectedCycle = CycleFilter.all;
  StatusFilter _selectedStatus = StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(settingsProvider).currency;
    final recurringState = ref.watch(recurringListNotifierProvider);
    final countdownState = ref.watch(upcomingPaymentCountdownProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscriptions & Recurring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Recurring Payment',
            onPressed: () => RecurringForm.showAdd(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(recurringListNotifierProvider.notifier).refresh();
          await ref.read(upcomingPaymentCountdownProvider.notifier).refresh();
        },
        child: _buildBody(
          context,
          recurringState,
          countdownState,
          currency,
          isDark,
          theme,
        ),
      ),
      floatingActionButton: recurringState.transactions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => RecurringForm.showAdd(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Subscription'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecurringListState state,
    CountdownState countdownState,
    String currency,
    bool isDark,
    ThemeData theme,
  ) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Couldn\'t load recurring payments.',
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
                  ref
                      .read(recurringListNotifierProvider.notifier)
                      .loadRecurringTransactions();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return RecurringEmptyState(
        onAddPressed: () => RecurringForm.showAdd(context),
      );
    }

    // Filter transactions
    final filtered = state.transactions.where((tx) {
      // Cycle Filter
      if (_selectedCycle == CycleFilter.weekly &&
          tx.recurrenceType != RecurrenceType.weekly) {
        return false;
      }
      if (_selectedCycle == CycleFilter.monthly &&
          tx.recurrenceType != RecurrenceType.monthly) {
        return false;
      }
      if (_selectedCycle == CycleFilter.yearly &&
          tx.recurrenceType != RecurrenceType.yearly) {
        return false;
      }

      // Status Filter
      if (_selectedStatus == StatusFilter.active &&
          tx.status != RecurringTransactionStatus.active) {
        return false;
      }
      if (_selectedStatus == StatusFilter.paused &&
          tx.status != RecurringTransactionStatus.paused) {
        return false;
      }
      if (_selectedStatus == StatusFilter.cancelled &&
          tx.status != RecurringTransactionStatus.cancelled) {
        return false;
      }

      return true;
    }).toList();

    // Map countdowns to transactions
    final countdownMap = <String, UpcomingPaymentCountdown>{};
    for (final cd in countdownState.upcomingPayments) {
      countdownMap[cd.recurringTransaction.id] = cd;
    }

    // Counts for filters
    final weeklyCount = state.transactions
        .where((t) => t.recurrenceType == RecurrenceType.weekly)
        .length;
    final monthlyCount = state.transactions
        .where((t) => t.recurrenceType == RecurrenceType.monthly)
        .length;
    final annualCount = state.transactions
        .where((t) => t.recurrenceType == RecurrenceType.yearly)
        .length;
    final activeCount = state.transactions
        .where((t) => t.status == RecurringTransactionStatus.active)
        .length;
    final pausedCount = state.transactions
        .where((t) => t.status == RecurringTransactionStatus.paused)
        .length;
    final cancelledCount = state.transactions
        .where((t) => t.status == RecurringTransactionStatus.cancelled)
        .length;

    final isFiltered =
        _selectedCycle != CycleFilter.all ||
        _selectedStatus != StatusFilter.all;

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
                    // Top Summary Card
                    RecurringSummary(
                      transactions: state.transactions,
                      currency: currency,
                      nearestPayment: countdownState.nearestPayment,
                    ),
                    const SizedBox(height: 16),

                    // Imminent Renewal Alert (if any active upcoming payment)
                    if (countdownState.nearestPayment != null &&
                        countdownState
                            .nearestPayment!
                            .recurringTransaction
                            .isActive)
                      RenewalAlertCard(
                        countdown: countdownState.nearestPayment!,
                        currency: currency,
                      ),

                    // Subscription / Cancellation Reminders
                    CancellationReminderCard(
                      transactions: state.transactions,
                      currency: currency,
                    ),

                    // Filter Bar
                    RecurringFilterBar(
                      selectedCycle: _selectedCycle,
                      selectedStatus: _selectedStatus,
                      totalCount: state.transactions.length,
                      weeklyCount: weeklyCount,
                      monthlyCount: monthlyCount,
                      annualCount: annualCount,
                      activeCount: activeCount,
                      pausedCount: pausedCount,
                      cancelledCount: cancelledCount,
                      onCycleChanged: (cycle) {
                        setState(() => _selectedCycle = cycle);
                      },
                      onStatusChanged: (status) {
                        setState(() => _selectedStatus = status);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: RecurringEmptyState(
                  isFiltered: isFiltered,
                  filterName: _selectedCycle != CycleFilter.all
                      ? RecurrenceCycleChip.getLabel(
                          _selectedCycle == CycleFilter.weekly
                              ? RecurrenceType.weekly
                              : (_selectedCycle == CycleFilter.monthly
                                    ? RecurrenceType.monthly
                                    : RecurrenceType.yearly),
                        )
                      : _selectedStatus.name.toUpperCase(),
                  onClearFilterPressed: () {
                    setState(() {
                      _selectedCycle = CycleFilter.all;
                      _selectedStatus = StatusFilter.all;
                    });
                  },
                ),
              )
            else if (!isWide)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tx = filtered[index];
                    return RecurringTransactionCard(
                      transaction: tx,
                      countdown: countdownMap[tx.id],
                    );
                  }, childCount: filtered.length),
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
                    mainAxisExtent: 240,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tx = filtered[index];
                    return RecurringTransactionCard(
                      transaction: tx,
                      countdown: countdownMap[tx.id],
                    );
                  }, childCount: filtered.length),
                ),
              ),
          ],
        );
      },
    );
  }
}
