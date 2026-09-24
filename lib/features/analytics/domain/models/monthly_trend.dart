import 'package:flutter/foundation.dart';

@immutable
class MonthlyTrend {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpenses;
  final double netCashflow;

  const MonthlyTrend({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashflow,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyTrend &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          totalIncome == other.totalIncome &&
          totalExpenses == other.totalExpenses &&
          netCashflow == other.netCashflow;

  @override
  int get hashCode =>
      year.hashCode ^
      month.hashCode ^
      totalIncome.hashCode ^
      totalExpenses.hashCode ^
      netCashflow.hashCode;

  @override
  String toString() {
    return 'MonthlyTrend($year-$month: Income: \$totalIncome, Expenses: \$totalExpenses, Net: \$netCashflow)';
  }
}
