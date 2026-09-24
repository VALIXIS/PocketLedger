import 'dart:convert';
import '../../../features/transactions/domain/models/transaction.dart';
import '../../../features/transactions/domain/models/transaction_type.dart';

class CategorySummary {
  final String categoryId;
  final int totalInCents;
  final double percentageOfTotal;

  CategorySummary({
    required this.categoryId,
    required this.totalInCents,
    required this.percentageOfTotal,
  });

  Map<String, dynamic> toJson() => {
    'category': categoryId,
    'amount': (totalInCents / 100.0).toStringAsFixed(2),
    'percentage': '${percentageOfTotal.toStringAsFixed(1)}%',
  };
}

class FinancialTelemetry {
  final int totalIncomeInCents;
  final int totalExpensesInCents;
  final int netBalanceInCents;
  final int totalTransactionCount;
  final List<CategorySummary> topCategories;
  final List<Map<String, String>> topExpenses;
  final List<String> anomalyAlerts;

  FinancialTelemetry({
    required this.totalIncomeInCents,
    required this.totalExpensesInCents,
    required this.netBalanceInCents,
    required this.totalTransactionCount,
    required this.topCategories,
    required this.topExpenses,
    required this.anomalyAlerts,
  });

  double get totalIncome => totalIncomeInCents / 100.0;
  double get totalExpenses => totalExpensesInCents / 100.0;
  double get netBalance => netBalanceInCents / 100.0;

  Map<String, dynamic> toJson() => {
    'summary': {
      'total_income': totalIncome.toStringAsFixed(2),
      'total_expenses': totalExpenses.toStringAsFixed(2),
      'net_balance': netBalance.toStringAsFixed(2),
      'transaction_count': totalTransactionCount,
      'savings_rate': totalIncome > 0
          ? '${((netBalance / totalIncome) * 100).toStringAsFixed(1)}%'
          : '0%',
    },
    'top_expense_categories': topCategories.map((c) => c.toJson()).toList(),
    'top_single_expenses': topExpenses,
    'spending_anomalies': anomalyAlerts,
  };

  String toFormattedJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}

class FinancialContextEngine {
  static FinancialTelemetry aggregate(List<Transaction> transactions) {
    int incomeCents = 0;
    int expenseCents = 0;

    final Map<String, int> categoryExpenseTotals = {};
    final List<Transaction> expenseTransactions = [];

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        incomeCents += tx.amountInCents;
      } else {
        expenseCents += tx.amountInCents;
        expenseTransactions.add(tx);
        categoryExpenseTotals[tx.category] =
            (categoryExpenseTotals[tx.category] ?? 0) + tx.amountInCents;
      }
    }

    // Sort category summaries descending
    final List<CategorySummary> categorySummaries = [];
    if (expenseCents > 0) {
      categoryExpenseTotals.forEach((catId, cents) {
        final pct = (cents / expenseCents) * 100.0;
        categorySummaries.add(
          CategorySummary(
            categoryId: catId,
            totalInCents: cents,
            percentageOfTotal: pct,
          ),
        );
      });
      categorySummaries.sort(
        (a, b) => b.totalInCents.compareTo(a.totalInCents),
      );
    }

    // Top 5 highest individual expenses
    expenseTransactions.sort(
      (a, b) => b.amountInCents.compareTo(a.amountInCents),
    );
    final top5Expenses = expenseTransactions.take(5).map((tx) {
      return {
        'category': tx.category,
        'amount': (tx.amountInCents / 100.0).toStringAsFixed(2),
        'date': tx.date.toIso8601String().split('T').first,
        'note': tx.note.isNotEmpty ? tx.note : 'No note',
      };
    }).toList();

    // Detect anomalies
    final List<String> anomalies = [];
    if (expenseCents > incomeCents && incomeCents > 0) {
      anomalies.add(
        'Net deficit: Expenses exceed income by \$${((expenseCents - incomeCents) / 100.0).toStringAsFixed(2)}',
      );
    }
    for (final cat in categorySummaries) {
      if (cat.percentageOfTotal > 35.0) {
        anomalies.add(
          'High category concentration: ${cat.categoryId} accounts for ${cat.percentageOfTotal.toStringAsFixed(1)}% of total expenses.',
        );
      }
    }

    return FinancialTelemetry(
      totalIncomeInCents: incomeCents,
      totalExpensesInCents: expenseCents,
      netBalanceInCents: incomeCents - expenseCents,
      totalTransactionCount: transactions.length,
      topCategories: categorySummaries.take(5).toList(),
      topExpenses: top5Expenses,
      anomalyAlerts: anomalies,
    );
  }
}
