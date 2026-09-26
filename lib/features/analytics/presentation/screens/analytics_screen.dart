import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../features/transactions/domain/models/transaction.dart';
import '../../../../features/transactions/presentation/providers/transaction_providers.dart';
import '../providers/analytics_providers.dart';
import '../widgets/category_spending_pie_chart.dart';
import '../widgets/monthly_cashflow_bar_chart.dart';
import '../widgets/spending_trend_line_chart.dart';

/// The full Day 5 Analytics Dashboard Screen for PocketLedger.
///
/// Integrates Net Worth Summary, Income vs Expense Visualization,
/// Top Merchants, and Category Spending Velocity.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionListProvider);
    final currency = ref.watch(settingsProvider).currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Telemetry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
            onPressed: () {
              ref.read(transactionListProvider.notifier).loadTransactions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: transactionState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading analytics data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$err',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildGlobalEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(transactionListProvider.notifier)
                    .loadTransactions();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Net Worth Summary
                    _buildNetWorthSummary(context, ref, currency),
                    const SizedBox(height: 16),

                    // SECTION 2: Income vs Expense Visualization
                    const MonthlyCashflowBarChart(),
                    const SizedBox(height: 16),
                    const CategorySpendingPieChart(),
                    const SizedBox(height: 16),
                    const SpendingTrendLineChart(),
                    const SizedBox(height: 16),

                    // SECTION 3: Top Merchants
                    _buildTopMerchantsSection(context, ref, currency),
                    const SizedBox(height: 16),

                    // SECTION 4: Category Velocity
                    _buildCategoryVelocitySection(context, ref, currency),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// SECTION 1: Net Worth Summary Card
  Widget _buildNetWorthSummary(
    BuildContext context,
    WidgetRef ref,
    String currency,
  ) {
    final report = ref.watch(analyticsReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      color: isDark
          ? const Color(0xFF1E262B)
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Worth & Financial Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Net Position',
                  amount: CurrencyFormatter.formatCents(
                    Transaction.doubleToCents(report.netCashflow),
                    currency,
                  ),
                  color: report.netCashflow >= 0 ? Colors.teal : Colors.red,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Savings Rate',
                  amount: '${report.savingsRate.toStringAsFixed(1)}%',
                  color: report.savingsRate >= 0
                      ? Colors.indigo
                      : Colors.orange,
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Total Income',
                  amount: CurrencyFormatter.formatCents(
                    Transaction.doubleToCents(report.totalIncome),
                    currency,
                  ),
                  color: Colors.green.shade700,
                  icon: Icons.arrow_downward,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Total Expenses',
                  amount: CurrencyFormatter.formatCents(
                    Transaction.doubleToCents(report.totalExpenses),
                    currency,
                  ),
                  color: Colors.red.shade700,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// SECTION 3: Top Merchants
  Widget _buildTopMerchantsSection(
    BuildContext context,
    WidgetRef ref,
    String currency,
  ) {
    final merchants = ref.watch(topMerchantsProvider);

    if (merchants.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top Merchants & Destinations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.store_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'No Merchant Data Available',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add expense notes/destinations to see top merchants.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final maxSpending = merchants.first.totalSpending;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Merchants & Outlets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'Top ${merchants.length}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: merchants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              final ratio = maxSpending > 0
                  ? (merchant.totalSpending / maxSpending).clamp(0.05, 1.0)
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          merchant.merchantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatCents(
                              Transaction.doubleToCents(merchant.totalSpending),
                              currency,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${merchant.transactionCount} ${merchant.transactionCount == 1 ? 'tx' : 'txs'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// SECTION 4: Category Velocity
  Widget _buildCategoryVelocitySection(
    BuildContext context,
    WidgetRef ref,
    String currency,
  ) {
    final velocities = ref.watch(categoryVelocityProvider);

    if (velocities.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Category Spending Velocity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.speed_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'No Category Velocity Data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add expense transactions to view category daily burn rate.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final maxVelocity = velocities.first.dailyVelocity;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Spending Velocity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Text(
                'Daily Burn Rate',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: velocities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final vel = velocities[index];
              final ratio = maxVelocity > 0
                  ? (vel.dailyVelocity / maxVelocity).clamp(0.05, 1.0)
                  : 0.0;
              final catIcon = CategoryUiHelper.getIcon(vel.category);
              final catColor = CategoryUiHelper.getColor(vel.category);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Icon(catIcon, color: catColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vel.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.formatCents(Transaction.doubleToCents(vel.totalSpending), currency)} total (${vel.transactionCount} txs)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${CurrencyFormatter.formatCents(Transaction.doubleToCents(vel.dailyVelocity), currency)} / day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: catColor,
                            ),
                          ),
                          Text(
                            '${vel.periodDays} days period',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Global empty state when no transactions exist at all
  Widget _buildGlobalEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 72,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No Analytics Data Available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add income and expense transactions to generate your complete financial telemetry suite.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
