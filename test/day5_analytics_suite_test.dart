import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/analytics/domain/analytics_helper.dart';
import 'package:pocketledger/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';
import 'package:pocketledger/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<Transaction> _storage = [];

  @override
  Future<List<Transaction>> getTransactions() async {
    return List.from(_storage);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final index = _storage.indexWhere((tx) => tx.id == transaction.id);
    if (index >= 0) {
      _storage[index] = transaction;
    } else {
      _storage.add(transaction);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _storage.removeWhere((tx) => tx.id == id);
  }
}

void main() {
  final d1 = DateTime(2026, 9, 1);
  final d5 = DateTime(2026, 9, 5);
  final d10 = DateTime(2026, 9, 10);

  group('Day 5 Full Analytics Suite Tests', () {
    late MockTransactionRepository mockRepository;

    setUp(() {
      mockRepository = MockTransactionRepository();
    });

    group('1. Net Worth Summary & Telemetry Calculations', () {
      test(
        '1-6. Net worth, total income, total expenses, savings rate, and zero-income savings rate',
        () {
          final transactions = [
            Transaction(
              id: '1',
              type: TransactionType.income,
              amountInCents: 1000000, // $10,000
              category: 'Salary',
              date: d1,
              note: 'Company',
              createdAt: d1,
            ),
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 250000, // $2,500
              category: 'Food',
              date: d5,
              note: 'Supermarket',
              createdAt: d5,
            ),
          ];

          final report = AnalyticsHelper.generateReport(transactions);

          expect(report.totalIncome, 10000.0);
          expect(report.totalExpenses, 2500.0);
          expect(report.netCashflow, 7500.0);
          expect(report.savingsRate, 75.0);

          // Zero income safety
          final zeroIncomeReport = AnalyticsHelper.generateReport([
            Transaction(
              id: '3',
              type: TransactionType.expense,
              amountInCents: 50000,
              category: 'Food',
              date: d1,
              note: '',
              createdAt: d1,
            ),
          ]);
          expect(zeroIncomeReport.savingsRate, 0.0);
        },
      );
    });

    group('2. Top Merchants (Grouping, Sorting, Counts & Empty Handling)', () {
      test(
        '7-10. Top merchant grouping, sorting by spending, tx counts, and empty handling',
        () {
          // Empty merchant test
          expect(AnalyticsHelper.calculateTopMerchants([]), isEmpty);

          final transactions = [
            // Amazon: 2 txs = $125 + $25 = $150
            Transaction(
              id: '1',
              type: TransactionType.expense,
              amountInCents: 12500,
              category: 'Shopping',
              date: d1,
              note: 'Amazon',
              createdAt: d1,
            ),
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 2500,
              category: 'Shopping',
              date: d5,
              note: 'Amazon',
              createdAt: d5,
            ),

            // Uber: 3 txs = $30 + $30 + $40 = $100
            Transaction(
              id: '3',
              type: TransactionType.expense,
              amountInCents: 3000,
              category: 'Transport',
              date: d1,
              note: 'Uber',
              createdAt: d1,
            ),
            Transaction(
              id: '4',
              type: TransactionType.expense,
              amountInCents: 3000,
              category: 'Transport',
              date: d5,
              note: 'Uber',
              createdAt: d5,
            ),
            Transaction(
              id: '5',
              type: TransactionType.expense,
              amountInCents: 4000,
              category: 'Transport',
              date: d10,
              note: 'Uber',
              createdAt: d10,
            ),

            // Fallback to category when note is empty: Bills = $50
            Transaction(
              id: '6',
              type: TransactionType.expense,
              amountInCents: 5000,
              category: 'Bills',
              date: d10,
              note: '',
              createdAt: d10,
            ),
          ];

          final top = AnalyticsHelper.calculateTopMerchants(
            transactions,
            limit: 5,
          );

          expect(top.length, 3);
          // #1 Amazon: $150 total, 2 txs
          expect(top[0].merchantName, 'Amazon');
          expect(top[0].totalSpending, 150.0);
          expect(top[0].transactionCount, 2);

          // #2 Uber: $100 total, 3 txs
          expect(top[1].merchantName, 'Uber');
          expect(top[1].totalSpending, 100.0);
          expect(top[1].transactionCount, 3);

          // #3 Bills (category fallback): $50 total, 1 tx
          expect(top[2].merchantName, 'Bills');
          expect(top[2].totalSpending, 50.0);
          expect(top[2].transactionCount, 1);
        },
      );
    });

    group('3. Category Velocity (Calculation, Sorting & Calendar Days)', () {
      test(
        '11-13. Category velocity calculation, sorting by velocity, and calendar days',
        () {
          // Sept 1 to Sept 10 = 10 calendar days
          final transactions = [
            Transaction(
              id: '1',
              type: TransactionType.expense,
              amountInCents:
                  500000, // $5,000 Food -> Velocity = 5000/10 = 500/day
              category: 'food',
              date: d1,
              note: '',
              createdAt: d1,
            ),
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents:
                  200000, // $2,000 Transport -> Velocity = 2000/10 = 200/day
              category: 'transport',
              date: d10,
              note: '',
              createdAt: d10,
            ),
          ];

          final velocities = AnalyticsHelper.calculateCategoryVelocities(
            transactions,
          );

          expect(velocities.length, 2);

          // #1 Food: $500/day
          expect(velocities[0].category, 'food');
          expect(velocities[0].categoryName, 'Food');
          expect(velocities[0].totalSpending, 5000.0);
          expect(velocities[0].dailyVelocity, 500.0);
          expect(velocities[0].periodDays, 10);

          // #2 Transport: $200/day
          expect(velocities[1].category, 'transport');
          expect(velocities[1].categoryName, 'Transport');
          expect(velocities[1].totalSpending, 2000.0);
          expect(velocities[1].dailyVelocity, 200.0);
          expect(velocities[1].periodDays, 10);
        },
      );
    });

    group('4. AnalyticsScreen UI & Providers Integration', () {
      testWidgets(
        '14. Renders full AnalyticsScreen with 4 sections and empty state handling',
        (tester) async {
          final container = ProviderContainer(
            overrides: [
              transactionRepositoryProvider.overrideWithValue(mockRepository),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: AnalyticsScreen()),
            ),
          );
          await tester.pumpAndSettle();

          // Empty state when repository is empty
          expect(find.text('No Analytics Data Available'), findsOneWidget);

          // Populate mock data
          await mockRepository.saveTransaction(
            Transaction(
              id: '1',
              type: TransactionType.income,
              amountInCents: 500000,
              category: 'Salary',
              date: d1,
              note: 'Company',
              createdAt: d1,
            ),
          );
          await mockRepository.saveTransaction(
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 150000,
              category: 'food',
              date: d10,
              note: 'Supermarket',
              createdAt: d10,
            ),
          );

          // Reload notifier
          await container
              .read(transactionListProvider.notifier)
              .loadTransactions();
          await tester.pumpAndSettle();

          // Section 1: Net Worth Summary
          expect(find.text('Net Worth & Financial Summary'), findsOneWidget);
          expect(find.text('Net Position'), findsOneWidget);
          expect(find.text('Savings Rate'), findsOneWidget);

          // Section 2: Visual Charts
          expect(find.text('Monthly Cashflow Comparison'), findsOneWidget);

          // Section 3: Top Merchants
          expect(find.text('Top Merchants & Outlets'), findsOneWidget);
          expect(find.text('Supermarket'), findsOneWidget);

          // Section 4: Category Velocity
          expect(find.text('Category Spending Velocity'), findsOneWidget);
          expect(find.text('Food'), findsOneWidget);
        },
      );
    });
  });
}
