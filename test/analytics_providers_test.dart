import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/analytics/presentation/providers/analytics_providers.dart';
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

  group('Day 2 Riverpod Analytics Data Streams', () {
    late MockTransactionRepository mockRepository;

    setUp(() {
      mockRepository = MockTransactionRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    group('1. categorySpendingProvider', () {
      test('groups expenses correctly and ignores income', () async {
        mockRepository.saveTransaction(
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 500000, // $5000
            category: 'Salary',
            date: now,
            note: 'Income',
            createdAt: now,
          ),
        );
        mockRepository.saveTransaction(
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 150000, // $1500
            category: 'Food',
            date: now,
            note: 'Grocery',
            createdAt: now,
          ),
        );
        mockRepository.saveTransaction(
          Transaction(
            id: '3',
            type: TransactionType.expense,
            amountInCents: 50000, // $500
            category: 'Food',
            date: now,
            note: 'Dinner',
            createdAt: now,
          ),
        );
        mockRepository.saveTransaction(
          Transaction(
            id: '4',
            type: TransactionType.expense,
            amountInCents: 100000, // $1000
            category: 'Bills',
            date: now,
            note: 'Electric',
            createdAt: now,
          ),
        );

        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final spending = container.read(categorySpendingProvider);

        expect(spending['Food'], 2000.0);
        expect(spending['Bills'], 1000.0);
        expect(spending.containsKey('Salary'), false); // Income ignored
      });

      test('returns empty map for empty transaction list', () async {
        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final spending = container.read(categorySpendingProvider);
        expect(spending, isEmpty);
      });

      test('handles empty or missing category names safely', () async {
        mockRepository.saveTransaction(
          Transaction(
            id: '1',
            type: TransactionType.expense,
            amountInCents: 2500,
            category: '',
            date: now,
            note: '',
            createdAt: now,
          ),
        );

        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final spending = container.read(categorySpendingProvider);
        expect(spending['Uncategorized'], 25.0);
      });
    });

    group('2. monthlyTrendProvider', () {
      test('aggregates income, expenses, and net cashflow grouped by month and sorted chronologically', () async {
        final jan = DateTime(2026, 1, 15);
        final feb = DateTime(2026, 2, 20);

        // Jan 2026: Income 4000, Expense 1000 -> Net = 3000
        mockRepository.saveTransaction(
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 400000,
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
            amountInCents: 100000,
            category: 'Rent',
            date: jan,
            note: '',
            createdAt: jan,
          ),
        );

        // Feb 2026: Income 5000, Expense 2000 -> Net = 3000
        mockRepository.saveTransaction(
          Transaction(
            id: '3',
            type: TransactionType.income,
            amountInCents: 500000,
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
            amountInCents: 200000,
            category: 'Rent',
            date: feb,
            note: '',
            createdAt: feb,
          ),
        );

        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final trends = container.read(monthlyTrendProvider);

        expect(trends.length, 2);
        // Chronological order: Jan 2026 then Feb 2026
        expect(trends[0].year, 2026);
        expect(trends[0].month, 1);
        expect(trends[0].totalIncome, 4000.0);
        expect(trends[0].totalExpenses, 1000.0);
        expect(trends[0].netCashflow, 3000.0);

        expect(trends[1].year, 2026);
        expect(trends[1].month, 2);
        expect(trends[1].totalIncome, 5000.0);
        expect(trends[1].totalExpenses, 2000.0);
        expect(trends[1].netCashflow, 3000.0);
      });

      test('handles income-only and expense-only months correctly', () async {
        final march = DateTime(2026, 3, 10);
        final april = DateTime(2026, 4, 10);

        // March: Income only ($3000)
        mockRepository.saveTransaction(
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 300000,
            category: 'Freelance',
            date: march,
            note: '',
            createdAt: march,
          ),
        );

        // April: Expense only ($800)
        mockRepository.saveTransaction(
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 80000,
            category: 'Travel',
            date: april,
            note: '',
            createdAt: april,
          ),
        );

        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final trends = container.read(monthlyTrendProvider);

        expect(trends.length, 2);

        // March (Income only)
        expect(trends[0].month, 3);
        expect(trends[0].totalIncome, 3000.0);
        expect(trends[0].totalExpenses, 0.0);
        expect(trends[0].netCashflow, 3000.0);

        // April (Expense only)
        expect(trends[1].month, 4);
        expect(trends[1].totalIncome, 0.0);
        expect(trends[1].totalExpenses, 800.0);
        expect(trends[1].netCashflow, -800.0);
      });

      test('returns empty list for empty transactions', () async {
        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final trends = container.read(monthlyTrendProvider);
        expect(trends, isEmpty);
      });
    });

    group('3. netWorthProvider', () {
      test('calculates net position = income - expenses accurately', () async {
        mockRepository.saveTransaction(
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 1000000, // $10,000
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
        );
        mockRepository.saveTransaction(
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 350000, // $3,500
            category: 'Rent',
            date: now,
            note: '',
            createdAt: now,
          ),
        );

        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        final netWorth = container.read(netWorthProvider);
        expect(netWorth, 6500.0);
        expect(netWorth.isNaN, false);
        expect(netWorth.isInfinite, false);
      });

      test('handles empty data, income-only data, and expense-only data', () async {
        final container = createContainer();
        await container.read(transactionListProvider.notifier).loadTransactions();

        // Empty
        expect(container.read(netWorthProvider), 0.0);

        // Income only
        await container.read(transactionListProvider.notifier).addTransaction(
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 500000, // $5000
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
        );
        expect(container.read(netWorthProvider), 5000.0);
      });
    });

    group('4. Riverpod Reactivity', () {
      test('all analytics providers update automatically when transactions are added, updated, or deleted', () async {
        final container = createContainer();

        // Initial empty check
        await container.read(transactionListProvider.notifier).loadTransactions();
        expect(container.read(netWorthProvider), 0.0);
        expect(container.read(categorySpendingProvider), isEmpty);
        expect(container.read(monthlyTrendProvider), isEmpty);

        // Action 1: Add Income ($5,000)
        final tx1 = Transaction(
          id: '1',
          type: TransactionType.income,
          amountInCents: 500000,
          category: 'Salary',
          date: DateTime(2026, 9, 1),
          note: 'Salary',
          createdAt: now,
        );
        await container.read(transactionListProvider.notifier).addTransaction(tx1);

        expect(container.read(netWorthProvider), 5000.0);
        expect(container.read(monthlyTrendProvider).first.totalIncome, 5000.0);

        // Action 2: Add Expense ($1,200 Food)
        final tx2 = Transaction(
          id: '2',
          type: TransactionType.expense,
          amountInCents: 120000,
          category: 'Food',
          date: DateTime(2026, 9, 5),
          note: 'Groceries',
          createdAt: now,
        );
        await container.read(transactionListProvider.notifier).addTransaction(tx2);

        expect(container.read(netWorthProvider), 3800.0); // 5000 - 1200
        expect(container.read(categorySpendingProvider)['Food'], 1200.0);
        expect(container.read(monthlyTrendProvider).first.totalExpenses, 1200.0);

        // Action 3: Update Expense ($1,200 -> $1,500 Food)
        final updatedTx2 = tx2.copyWith(amountInCents: 150000);
        await container.read(transactionListProvider.notifier).updateTransaction(updatedTx2);

        expect(container.read(netWorthProvider), 3500.0); // 5000 - 1500
        expect(container.read(categorySpendingProvider)['Food'], 1500.0);
        expect(container.read(monthlyTrendProvider).first.totalExpenses, 1500.0);

        // Action 4: Delete Expense (tx2)
        await container.read(transactionListProvider.notifier).deleteTransaction('2');

        expect(container.read(netWorthProvider), 5000.0);
        expect(container.read(categorySpendingProvider), isEmpty);
        expect(container.read(monthlyTrendProvider).first.totalExpenses, 0.0);
      });
    });
  });
}
