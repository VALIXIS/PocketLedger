import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/analytics/presentation/widgets/monthly_cashflow_bar_chart.dart';
import 'package:pocketledger/features/analytics/presentation/widgets/spending_trend_line_chart.dart';
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
  final now = DateTime(2026, 9, 24);

  group('Day 4 Charts - Bar Chart & 12-Month Line Chart Tests', () {
    late MockTransactionRepository mockRepository;

    setUp(() {
      mockRepository = MockTransactionRepository();
    });

    Widget createTestableWidget(Widget child) {
      return ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    group('1. MonthlyCashflowBarChart', () {
      testWidgets('renders empty state when there are no transactions', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestableWidget(const MonthlyCashflowBarChart()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Monthly Cashflow Comparison'), findsOneWidget);
        expect(find.text('No Monthly Cashflow Data'), findsOneWidget);
        expect(
          find.text(
            'Add income and expense transactions to see monthly comparison bars.',
          ),
          findsOneWidget,
        );
      });

      testWidgets(
        'renders monthly comparison bar chart with income and expense data',
        (tester) async {
          final jan = DateTime(2026, 1, 15);
          final feb = DateTime(2026, 2, 20);

          mockRepository.saveTransaction(
            Transaction(
              id: '1',
              type: TransactionType.income,
              amountInCents: 3000000, // $30,000
              category: 'Salary',
              date: jan,
              note: '',
              createdAt: jan,
            ),
          );
          mockRepository.saveTransaction(
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 2000000, // $20,000
              category: 'Rent',
              date: jan,
              note: '',
              createdAt: jan,
            ),
          );
          mockRepository.saveTransaction(
            Transaction(
              id: '3',
              type: TransactionType.income,
              amountInCents: 3500000, // $35,000
              category: 'Salary',
              date: feb,
              note: '',
              createdAt: feb,
            ),
          );
          mockRepository.saveTransaction(
            Transaction(
              id: '4',
              type: TransactionType.expense,
              amountInCents: 2200000, // $22,000
              category: 'Rent',
              date: feb,
              note: '',
              createdAt: feb,
            ),
          );

          await tester.pumpWidget(
            createTestableWidget(const MonthlyCashflowBarChart()),
          );
          await tester.pumpAndSettle();

          expect(find.text('Monthly Cashflow Comparison'), findsOneWidget);
          expect(find.text('Income'), findsOneWidget);
          expect(find.text('Expenses'), findsOneWidget);
          expect(find.text('Jan'), findsOneWidget);
          expect(find.text('Feb'), findsOneWidget);
        },
      );
    });

    group('2. SpendingTrendLineChart', () {
      testWidgets('renders empty state when there are no transactions', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestableWidget(const SpendingTrendLineChart()),
        );
        await tester.pumpAndSettle();

        expect(find.text('12-Month Spending Trend'), findsOneWidget);
        expect(find.text('No Spending History'), findsOneWidget);
      });

      testWidgets(
        'renders 12-month spending trend line chart with expense history',
        (tester) async {
          for (int m = 1; m <= 14; m++) {
            final date = DateTime(
              2025 + (m > 12 ? 1 : 0),
              ((m - 1) % 12) + 1,
              10,
            );
            mockRepository.saveTransaction(
              Transaction(
                id: 'tx_$m',
                type: TransactionType.expense,
                amountInCents: 50000 + (m * 10000), // Varying expenses
                category: 'Food',
                date: date,
                note: '',
                createdAt: date,
              ),
            );
          }

          await tester.pumpWidget(
            createTestableWidget(const SpendingTrendLineChart()),
          );
          await tester.pumpAndSettle();

          expect(find.text('12-Month Spending Trend'), findsOneWidget);
          // Enforces maximum 12 months history
          expect(find.text('12 Months History'), findsOneWidget);
        },
      );

      testWidgets('handles fewer than 12 months history gracefully', (
        tester,
      ) async {
        mockRepository.saveTransaction(
          Transaction(
            id: '1',
            type: TransactionType.expense,
            amountInCents: 150000,
            category: 'Food',
            date: now,
            note: '',
            createdAt: now,
          ),
        );

        await tester.pumpWidget(
          createTestableWidget(const SpendingTrendLineChart()),
        );
        await tester.pumpAndSettle();

        expect(find.text('12-Month Spending Trend'), findsOneWidget);
        expect(find.text('1 Month History'), findsOneWidget);
      });
    });
  });
}
