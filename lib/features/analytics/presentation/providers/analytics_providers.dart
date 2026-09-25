import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/analytics_helper.dart';
import '../../domain/models/analytics_report.dart';
import '../../domain/models/category_velocity.dart';
import '../../domain/models/monthly_trend.dart';
import '../../domain/models/top_merchant.dart';

/// Provider for expense spending grouped by category (`Map<String, double>`).
///
/// Reactively derives category expense totals from [transactionListProvider].
final categorySpendingProvider = Provider<Map<String, double>>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  final transactions = transactionState.valueOrNull ?? [];
  return AnalyticsHelper.calculateCategoryExpenseTotals(transactions);
});

/// Provider for monthly financial trends (`List<MonthlyTrend>`).
///
/// Reactively derives monthly income, expense, and net cashflow totals from [transactionListProvider],
/// sorted chronologically.
final monthlyTrendProvider = Provider<List<MonthlyTrend>>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  final transactions = transactionState.valueOrNull ?? [];
  return AnalyticsHelper.calculateMonthlyTrends(transactions);
});

/// Provider for total net worth position (`double`).
///
/// Reactively calculates `total income - total expenses` from [transactionListProvider].
final netWorthProvider = Provider<double>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  final transactions = transactionState.valueOrNull ?? [];
  return AnalyticsHelper.calculateNetCashflow(transactions);
});

/// Provider for Top 5 Merchants by expense spending (`List<TopMerchant>`).
///
/// Reactively derives top spending destinations from [transactionListProvider].
final topMerchantsProvider = Provider<List<TopMerchant>>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  final transactions = transactionState.valueOrNull ?? [];
  return AnalyticsHelper.calculateTopMerchants(transactions, limit: 5);
});

/// Provider for Category Spending Velocities (`List<CategoryVelocity>`).
///
/// Reactively derives category daily burn rates from [transactionListProvider].
final categoryVelocityProvider = Provider<List<CategoryVelocity>>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  final transactions = transactionState.valueOrNull ?? [];
  return AnalyticsHelper.calculateCategoryVelocities(transactions);
});

/// Provider for comprehensive [AnalyticsReport] telemetry snapshot.
final analyticsReportProvider = Provider<AnalyticsReport>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  final transactions = transactionState.valueOrNull ?? [];
  return AnalyticsHelper.generateReport(transactions);
});
