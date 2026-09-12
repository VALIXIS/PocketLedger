import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/ai/financial_context_engine.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

void main() {
  group('FinancialContextEngine Aggregation Tests', () {
    test('Correctly aggregates empty transaction list', () {
      final telemetry = FinancialContextEngine.aggregate([]);

      expect(telemetry.totalIncomeInCents, 0);
      expect(telemetry.totalExpensesInCents, 0);
      expect(telemetry.netBalanceInCents, 0);
      expect(telemetry.totalTransactionCount, 0);
      expect(telemetry.topCategories, isEmpty);
      expect(telemetry.topExpenses, isEmpty);
      expect(telemetry.anomalyAlerts, isEmpty);
    });

    test('Correctly aggregates income and expense transactions', () {
      final now = DateTime.now();
      final List<Transaction> transactions = [
        Transaction(
          id: '1',
          type: TransactionType.income,
          amountInCents: 500000, // $5000.00
          category: 'salary',
          date: now,
          note: 'Monthly salary',
          createdAt: now,
        ),
        Transaction(
          id: '2',
          type: TransactionType.expense,
          amountInCents: 150000, // $1500.00
          category: 'food',
          date: now,
          note: 'Groceries',
          createdAt: now,
        ),
        Transaction(
          id: '3',
          type: TransactionType.expense,
          amountInCents: 50000, // $500.00
          category: 'food',
          date: now,
          note: 'Restaurants',
          createdAt: now,
        ),
        Transaction(
          id: '4',
          type: TransactionType.expense,
          amountInCents: 100000, // $1000.00
          category: 'bills',
          date: now,
          note: 'Electricity bill',
          createdAt: now,
        ),
      ];

      final telemetry = FinancialContextEngine.aggregate(transactions);

      expect(telemetry.totalIncomeInCents, 500000);
      expect(telemetry.totalExpensesInCents, 300000);
      expect(telemetry.netBalanceInCents, 200000);
      expect(telemetry.totalTransactionCount, 4);

      // Top category should be 'food' ($2000 total = 66.7% of $3000 expenses)
      expect(telemetry.topCategories.first.categoryId, 'food');
      expect(telemetry.topCategories.first.totalInCents, 200000);

      // Anomaly detection: food > 35% of total expenses
      expect(telemetry.anomalyAlerts.length, 1);
      expect(telemetry.anomalyAlerts.first, contains('High category concentration'));
    });
  });
}
