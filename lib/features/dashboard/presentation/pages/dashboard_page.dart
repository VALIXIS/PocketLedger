import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_refresh_indicator.dart';
import '../widgets/gradient_balance_card.dart';
import '../widgets/income_expense_summary_card.dart';
import '../widgets/recent_activity_section.dart';

/// The flagship PocketLedger Dashboard visual experience.
///
/// Features a CustomScrollView sliver architecture, layered gradient mesh balance card,
/// animated numerical counters, semantic income/expense indicators, and styled
/// pull-to-refresh interactions.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int? _previousBalanceInCents;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Keep track of balance changes for animation
    final currentBalance = stats.balanceInCents;
    final prevBalance = _previousBalanceInCents;
    if (_previousBalanceInCents != currentBalance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _previousBalanceInCents = currentBalance;
          });
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: DashboardRefreshIndicator(
          onRefresh: () async {
            await ref.read(transactionListProvider.notifier).loadTransactions();
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.maxContentWidth,
              ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        // 1. Greeting & Header
                        const DashboardHeader(),
                        const SizedBox(height: AppSpacing.space12),

                        // 2. Flagship Gradient Mesh Balance Card
                        GradientBalanceCard(
                          balanceInCents: currentBalance,
                          previousBalanceInCents: prevBalance,
                          currency: settings.currency,
                          title: 'Net Balance',
                          period: 'This Month',
                          onTap: () {
                            // Quick refresh on balance card tap
                            ref
                                .read(transactionListProvider.notifier)
                                .loadTransactions();
                          },
                        ),
                        const SizedBox(height: AppSpacing.space16),

                        // 3. Compact Income & Expense Summary
                        IncomeExpenseSummaryCard(
                          incomeInCents: stats.totalIncomeInCents,
                          expensesInCents: stats.totalExpensesInCents,
                          currency: settings.currency,
                        ),
                        const SizedBox(height: AppSpacing.space24),

                        // 4. Recent Transactions Section
                        transactionsAsync.when(
                          data: (transactions) => RecentActivitySection(
                            transactions: transactions,
                            currency: settings.currency,
                            maxItems: 6,
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.space40,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) => Container(
                            padding: const EdgeInsets.all(AppSpacing.space16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.radius12,
                              ),
                            ),
                            child: Text(
                              'Failed to load transactions: $error',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        // Bottom breathing room
                        const SizedBox(height: AppSpacing.space64),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
        },
        tooltip: 'Add Transaction',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
