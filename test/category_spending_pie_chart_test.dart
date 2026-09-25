import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/analytics/presentation/widgets/category_spending_pie_chart.dart';
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

  group('CategorySpendingPieChart - Day 3 Donut Chart Tests', () {
    late MockTransactionRepository mockRepository;

    setUp(() {
      mockRepository = MockTransactionRepository();
    });

    Widget createTestableWidget() {
      return ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CategorySpendingPieChart()),
          ),
        ),
      );
    }

    testWidgets(
      'renders empty state when there are no transactions or no expenses',
      (tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Expense Breakdown by Category'), findsOneWidget);
        expect(find.text('No Expense Category Data'), findsOneWidget);
        expect(
          find.text(
            'Add expense transactions to see your interactive category breakdown.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders empty state when there are only income transactions', (
      tester,
    ) async {
      mockRepository.saveTransaction(
        Transaction(
          id: '1',
          type: TransactionType.income,
          amountInCents: 500000, // $5000
          category: 'Salary',
          date: now,
          note: 'Salary',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Expense Category Data'), findsOneWidget);
    });

    testWidgets('renders category breakdown donut chart with expense data', (
      tester,
    ) async {
      mockRepository.saveTransaction(
        Transaction(
          id: '1',
          type: TransactionType.expense,
          amountInCents: 500000, // $5000 (50%)
          category: 'food',
          date: now,
          note: '',
          createdAt: now,
        ),
      );
      mockRepository.saveTransaction(
        Transaction(
          id: '2',
          type: TransactionType.expense,
          amountInCents: 300000, // $3000 (30%)
          category: 'transport',
          date: now,
          note: '',
          createdAt: now,
        ),
      );
      mockRepository.saveTransaction(
        Transaction(
          id: '3',
          type: TransactionType.expense,
          amountInCents: 200000, // $2000 (20%)
          category: 'bills',
          date: now,
          note: '',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Should display chart title
      expect(find.text('Expense Breakdown by Category'), findsOneWidget);

      // Default state when nothing selected: Total Spent $10,000.00
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('All Expenses'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('Tap any slice to inspect'), findsOneWidget);
    });

    testWidgets('handles single category expense list correctly', (
      tester,
    ) async {
      mockRepository.saveTransaction(
        Transaction(
          id: '1',
          type: TransactionType.expense,
          amountInCents: 100000, // $1000 (100%)
          category: 'shopping',
          date: now,
          note: '',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Expense Breakdown by Category'), findsOneWidget);
      expect(find.text('All Expenses'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
    });
  });
}
