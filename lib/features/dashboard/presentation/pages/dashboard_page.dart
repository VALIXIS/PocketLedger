import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/responsive_breakpoints.dart';
import '../../../../core/widgets/micro_interaction.dart';
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
/// Features responsive phone, foldable, tablet, and multi-column desktop layouts,
/// a CustomScrollView sliver architecture, layered gradient mesh balance card,
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

    final balanceCard = GradientBalanceCard(
      balanceInCents: currentBalance,
      previousBalanceInCents: prevBalance,
      currency: settings.currency,
      title: 'Net Balance',
      period: 'This Month',
      onTap: () {
        // Quick refresh on balance card tap
        ref.read(transactionListProvider.notifier).loadTransactions();
      },
    );

    final summaryCard = IncomeExpenseSummaryCard(
      incomeInCents: stats.totalIncomeInCents,
      expensesInCents: stats.totalExpensesInCents,
      currency: settings.currency,
    );

    final recentActivity = transactionsAsync.when(
      data: (transactions) => RecentActivitySection(
        transactions: transactions,
        currency: settings.currency,
        maxItems: 6,
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.space40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
        child: Text(
          'Failed to load transactions: $error',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: DashboardRefreshIndicator(
          onRefresh: () async {
            await ref.read(transactionListProvider.notifier).loadTransactions();
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveBreakpoints.maxContentWidth,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isDesktopOrLarge =
                      width >= ResponsiveBreakpoints.largeTablet;
                  final isFoldableOrMedium =
                      width >= ResponsiveBreakpoints.foldable &&
                      width < ResponsiveBreakpoints.largeTablet;

                  return CustomScrollView(
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
                            const SizedBox(height: AppSpacing.space16),

                            // 2. Responsive Content Body
                            if (isDesktopOrLarge) ...[
                              // Desktop / Large Tablet: Balanced 2-Column Composition
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        balanceCard,
                                        const SizedBox(
                                          height: AppSpacing.space16,
                                        ),
                                        summaryCard,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space24),
                                  Expanded(flex: 6, child: recentActivity),
                                ],
                              ),
                            ] else if (isFoldableOrMedium) ...[
                              // Foldable / Intermediate: Side-by-side Top Row, Full Width Activity
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: balanceCard),
                                  const SizedBox(width: AppSpacing.space16),
                                  Expanded(flex: 2, child: summaryCard),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.space24),
                              recentActivity,
                            ] else ...[
                              // Phone: Vertical Single-Column
                              balanceCard,
                              const SizedBox(height: AppSpacing.space16),
                              summaryCard,
                              const SizedBox(height: AppSpacing.space24),
                              recentActivity,
                            ],

                            // Bottom breathing room
                            const SizedBox(height: AppSpacing.space64),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: InteractiveScale(
        enableHaptic: true,
        semanticLabel: 'Add Transaction',
        child: FloatingActionButton(
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
      ),
    );
  }
}
