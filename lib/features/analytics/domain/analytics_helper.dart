import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';
import 'models/analytics_report.dart';
import 'models/category_velocity.dart';
import 'models/monthly_trend.dart';
import 'models/top_merchant.dart';

/// Pure Dart, stateless helper class for calculating financial analytics and telemetry metrics.
class AnalyticsHelper {
  // Private constructor to prevent instantiation (stateless utility class)
  AnalyticsHelper._();

  /// Filters [transactions] based on an optional date range ([startDate] to [endDate]).
  ///
  /// Safe against invalid date ranges (where [startDate] is after [endDate]).
  /// Returns a new list without mutating [transactions].
  static List<Transaction> filterTransactions(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (transactions.isEmpty) return const [];

    DateTime? normStart;
    DateTime? normEnd;

    if (startDate != null) {
      normStart = DateTime(startDate.year, startDate.month, startDate.day);
    }
    if (endDate != null) {
      normEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
    }

    if (normStart != null && normEnd != null && normStart.isAfter(normEnd)) {
      return const [];
    }

    return transactions.where((tx) {
      if (normStart != null && tx.date.isBefore(normStart)) {
        return false;
      }
      if (normEnd != null && tx.date.isAfter(normEnd)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Calculates total income in monetary units (double) safely using integer cents internally.
  static double calculateTotalIncome(List<Transaction> transactions) {
    int totalCents = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalCents += tx.amountInCents;
      }
    }
    return _sanitizeDouble(totalCents / 100.0);
  }

  /// Calculates total expenses in monetary units (double) safely using integer cents internally.
  static double calculateTotalExpenses(List<Transaction> transactions) {
    int totalCents = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalCents += tx.amountInCents;
      }
    }
    return _sanitizeDouble(totalCents / 100.0);
  }

  /// Calculates net cashflow (Total Income - Total Expenses).
  static double calculateNetCashflow(List<Transaction> transactions) {
    int incomeCents = 0;
    int expenseCents = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        incomeCents += tx.amountInCents;
      } else if (tx.type == TransactionType.expense) {
        expenseCents += tx.amountInCents;
      }
    }

    return _sanitizeDouble((incomeCents - expenseCents) / 100.0);
  }

  /// Calculates total expense amounts per category.
  ///
  /// Returns a map of category names to their total expense amount.
  /// Missing or empty category names default to `'Uncategorized'`.
  static Map<String, double> calculateCategoryExpenseTotals(
    List<Transaction> transactions,
  ) {
    final Map<String, int> centsMap = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final categoryKey = tx.category.trim().isEmpty
            ? 'Uncategorized'
            : tx.category.trim();
        centsMap[categoryKey] = (centsMap[categoryKey] ?? 0) + tx.amountInCents;
      }
    }

    final Map<String, double> result = {};
    centsMap.forEach((category, cents) {
      result[category] = _sanitizeDouble(cents / 100.0);
    });

    return result;
  }

  /// Calculates expense percentages for each category relative to total expenses.
  ///
  /// Returns a map of category names to their percentage (0.0 to 100.0).
  /// Safe against zero total expenses (returns empty map).
  static Map<String, double> calculateCategoryPercentages(
    List<Transaction> transactions,
  ) {
    int totalExpenseCents = 0;
    final Map<String, int> centsMap = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalExpenseCents += tx.amountInCents;
        final categoryKey = tx.category.trim().isEmpty
            ? 'Uncategorized'
            : tx.category.trim();
        centsMap[categoryKey] = (centsMap[categoryKey] ?? 0) + tx.amountInCents;
      }
    }

    if (totalExpenseCents <= 0) {
      return const {};
    }

    final Map<String, double> result = {};
    centsMap.forEach((category, cents) {
      final pct = (cents / totalExpenseCents) * 100.0;
      result[category] = _sanitizeDouble(pct);
    });

    return result;
  }

  /// Calculates monthly financial trends grouped by calendar month and sorted chronologically.
  static List<MonthlyTrend> calculateMonthlyTrends(
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty) return const [];

    final Map<String, _MonthlyTotals> grouped = {};

    for (final tx in transactions) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      final current = grouped.putIfAbsent(
        key,
        () => _MonthlyTotals(year: tx.date.year, month: tx.date.month),
      );

      if (tx.type == TransactionType.income) {
        current.incomeCents += tx.amountInCents;
      } else if (tx.type == TransactionType.expense) {
        current.expenseCents += tx.amountInCents;
      }
    }

    final List<MonthlyTrend> trends = grouped.values.map((totals) {
      final income = _sanitizeDouble(totals.incomeCents / 100.0);
      final expenses = _sanitizeDouble(totals.expenseCents / 100.0);
      final net = _sanitizeDouble(
        (totals.incomeCents - totals.expenseCents) / 100.0,
      );
      return MonthlyTrend(
        year: totals.year,
        month: totals.month,
        totalIncome: income,
        totalExpenses: expenses,
        netCashflow: net,
      );
    }).toList();

    trends.sort((a, b) {
      if (a.year != b.year) {
        return a.year.compareTo(b.year);
      }
      return a.month.compareTo(b.month);
    });

    return trends;
  }

  /// Calculates Top Merchants grouped by merchant name/label from expense transactions.
  ///
  /// Uses `tx.note` as the primary merchant label, falling back to `tx.category`.
  /// Returns a sorted list of top [limit] merchants.
  static List<TopMerchant> calculateTopMerchants(
    List<Transaction> transactions, {
    int limit = 5,
  }) {
    if (transactions.isEmpty) return const [];

    final Map<String, _MerchantAccumulator> map = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final String rawLabel = tx.note.trim().isNotEmpty
            ? tx.note.trim()
            : (tx.category.trim().isNotEmpty
                  ? tx.category.trim()
                  : 'Uncategorized');

        final label =
            rawLabel.substring(0, 1).toUpperCase() + rawLabel.substring(1);

        final acc = map.putIfAbsent(
          label,
          () => _MerchantAccumulator(merchantName: label),
        );

        acc.totalCents += tx.amountInCents;
        acc.count += 1;
      }
    }

    final list = map.values.map((acc) {
      return TopMerchant(
        merchantName: acc.merchantName,
        totalSpending: _sanitizeDouble(acc.totalCents / 100.0),
        transactionCount: acc.count,
      );
    }).toList();

    list.sort((a, b) {
      final comp = b.totalSpending.compareTo(a.totalSpending);
      if (comp != 0) return comp;
      return b.transactionCount.compareTo(a.transactionCount);
    });

    return list.take(limit).toList();
  }

  /// Calculates category spending velocities (daily burn rate) for all expense categories.
  static List<CategoryVelocity> calculateCategoryVelocities(
    List<Transaction> transactions,
  ) {
    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    if (expenses.isEmpty) return const [];

    final periodDays = calculatePeriodDays(expenses);
    final safeDays = periodDays < 1 ? 1 : periodDays;

    final Map<String, _CategoryAccumulator> map = {};

    for (final tx in expenses) {
      final rawCat = tx.category.trim().isEmpty
          ? 'Uncategorized'
          : tx.category.trim();

      final acc = map.putIfAbsent(
        rawCat,
        () => _CategoryAccumulator(category: rawCat),
      );

      acc.totalCents += tx.amountInCents;
      acc.count += 1;
    }

    final list = map.values.map((acc) {
      final total = _sanitizeDouble(acc.totalCents / 100.0);
      final velocity = _sanitizeDouble(total / safeDays);
      final formattedName =
          acc.category.substring(0, 1).toUpperCase() +
          acc.category.substring(1).replaceAll('_', ' ');

      return CategoryVelocity(
        category: acc.category,
        categoryName: formattedName,
        totalSpending: total,
        transactionCount: acc.count,
        dailyVelocity: velocity,
        periodDays: safeDays,
      );
    }).toList();

    list.sort((a, b) => b.dailyVelocity.compareTo(a.dailyVelocity));

    return list;
  }

  /// Calculates period length in days.
  static int calculatePeriodDays(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate != null && endDate != null) {
      final normStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final normEnd = DateTime(endDate.year, endDate.month, endDate.day);

      if (normStart.isAfter(normEnd)) {
        return 0;
      }
      return normEnd.difference(normStart).inDays + 1;
    }

    final filtered = filterTransactions(
      transactions,
      startDate: startDate,
      endDate: endDate,
    );

    if (filtered.isEmpty) {
      return 0;
    }

    DateTime? minDate;
    DateTime? maxDate;

    for (final tx in filtered) {
      if (minDate == null || tx.date.isBefore(minDate)) {
        minDate = tx.date;
      }
      if (maxDate == null || tx.date.isAfter(maxDate)) {
        maxDate = tx.date;
      }
    }

    if (minDate == null || maxDate == null) {
      return 0;
    }

    final normMin = DateTime(minDate.year, minDate.month, minDate.day);
    final normMax = DateTime(maxDate.year, maxDate.month, maxDate.day);

    final days = normMax.difference(normMin).inDays + 1;
    return days < 1 ? 1 : days;
  }

  /// Calculates Cashflow Velocity (Average Net Cashflow per day).
  static double calculateCashflowVelocity(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
    int? customPeriodDays,
  }) {
    final filtered = filterTransactions(
      transactions,
      startDate: startDate,
      endDate: endDate,
    );

    if (filtered.isEmpty) {
      return 0.0;
    }

    final days = (customPeriodDays != null && customPeriodDays > 0)
        ? customPeriodDays
        : calculatePeriodDays(filtered, startDate: startDate, endDate: endDate);

    if (days <= 0) {
      return 0.0;
    }

    final netCashflow = calculateNetCashflow(filtered);
    return _sanitizeDouble(netCashflow / days);
  }

  /// Calculates Income / Expense Ratio (`Income / Expenses`).
  static double calculateIncomeExpenseRatio(List<Transaction> transactions) {
    int incomeCents = 0;
    int expenseCents = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        incomeCents += tx.amountInCents;
      } else if (tx.type == TransactionType.expense) {
        expenseCents += tx.amountInCents;
      }
    }

    if (expenseCents <= 0) {
      return 0.0;
    }

    return _sanitizeDouble(incomeCents / expenseCents);
  }

  /// Calculates Savings Rate (`(Income - Expenses) / Income * 100`).
  static double calculateSavingsRate(List<Transaction> transactions) {
    int incomeCents = 0;
    int expenseCents = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        incomeCents += tx.amountInCents;
      } else if (tx.type == TransactionType.expense) {
        expenseCents += tx.amountInCents;
      }
    }

    if (incomeCents <= 0) {
      return 0.0;
    }

    final netCents = incomeCents - expenseCents;
    final rate = (netCents / incomeCents) * 100.0;
    return _sanitizeDouble(rate);
  }

  /// Generates a comprehensive [AnalyticsReport] from a list of transactions.
  static AnalyticsReport generateReport(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filtered = filterTransactions(
      transactions,
      startDate: startDate,
      endDate: endDate,
    );

    final totalIncome = calculateTotalIncome(filtered);
    final totalExpenses = calculateTotalExpenses(filtered);
    final netCashflow = calculateNetCashflow(filtered);
    final categoryTotals = calculateCategoryExpenseTotals(filtered);
    final categoryPcts = calculateCategoryPercentages(filtered);
    final periodDays = calculatePeriodDays(
      filtered,
      startDate: startDate,
      endDate: endDate,
    );
    final cashflowVel = calculateCashflowVelocity(
      filtered,
      startDate: startDate,
      endDate: endDate,
      customPeriodDays: periodDays,
    );
    final ratio = calculateIncomeExpenseRatio(filtered);
    final savings = calculateSavingsRate(filtered);

    return AnalyticsReport(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netCashflow: netCashflow,
      categoryExpenseTotals: categoryTotals,
      categoryPercentages: categoryPcts,
      cashflowVelocity: cashflowVel,
      incomeExpenseRatio: ratio,
      savingsRate: savings,
      periodDays: periodDays,
      transactionCount: filtered.length,
    );
  }

  /// Internal helper to ensure numeric values never return NaN, Infinity, or -Infinity.
  static double _sanitizeDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    return value;
  }
}

class _MonthlyTotals {
  final int year;
  final int month;
  int incomeCents = 0;
  int expenseCents = 0;

  _MonthlyTotals({required this.year, required this.month});
}

class _MerchantAccumulator {
  final String merchantName;
  int totalCents = 0;
  int count = 0;

  _MerchantAccumulator({required this.merchantName});
}

class _CategoryAccumulator {
  final String category;
  int totalCents = 0;
  int count = 0;

  _CategoryAccumulator({required this.category});
}
