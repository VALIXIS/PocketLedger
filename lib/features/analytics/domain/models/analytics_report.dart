import 'package:flutter/foundation.dart';

@immutable
class AnalyticsReport {
  final double totalIncome;
  final double totalExpenses;
  final double netCashflow;
  final Map<String, double> categoryExpenseTotals;
  final Map<String, double> categoryPercentages;
  final double cashflowVelocity;
  final double incomeExpenseRatio;
  final double savingsRate;
  final int periodDays;
  final int transactionCount;

  const AnalyticsReport({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashflow,
    required this.categoryExpenseTotals,
    required this.categoryPercentages,
    required this.cashflowVelocity,
    required this.incomeExpenseRatio,
    required this.savingsRate,
    required this.periodDays,
    required this.transactionCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsReport &&
          runtimeType == other.runtimeType &&
          totalIncome == other.totalIncome &&
          totalExpenses == other.totalExpenses &&
          netCashflow == other.netCashflow &&
          mapEquals(categoryExpenseTotals, other.categoryExpenseTotals) &&
          mapEquals(categoryPercentages, other.categoryPercentages) &&
          cashflowVelocity == other.cashflowVelocity &&
          incomeExpenseRatio == other.incomeExpenseRatio &&
          savingsRate == other.savingsRate &&
          periodDays == other.periodDays &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode =>
      totalIncome.hashCode ^
      totalExpenses.hashCode ^
      netCashflow.hashCode ^
      categoryExpenseTotals.hashCode ^
      categoryPercentages.hashCode ^
      cashflowVelocity.hashCode ^
      incomeExpenseRatio.hashCode ^
      savingsRate.hashCode ^
      periodDays.hashCode ^
      transactionCount.hashCode;

  @override
  String toString() {
    return 'AnalyticsReport(totalIncome: \$totalIncome, totalExpenses: \$totalExpenses, netCashflow: \$netCashflow, cashflowVelocity: \$cashflowVelocity, incomeExpenseRatio: \$incomeExpenseRatio, savingsRate: \$savingsRate%, periodDays: \$periodDays, transactionCount: \$transactionCount)';
  }
}
