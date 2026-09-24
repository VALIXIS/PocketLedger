import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/repositories/budget_repository.dart';
import 'package:pocketledger/features/budgets/presentation/providers/budget_list_notifier.dart';
import 'package:pocketledger/features/budgets/presentation/screens/budget_list_screen.dart';
import 'package:pocketledger/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class MockBudgetRepository implements BudgetRepository {
  final Map<String, Budget> storage = {};
  bool shouldThrow = false;

  @override
  Future<List<Budget>> getBudgets() async {
    if (shouldThrow) throw Exception('Network error');
    return storage.values.toList();
  }

  @override
  Future<Budget?> getBudgetById(String id) async => storage[id];

  @override
  Future<void> saveBudget(Budget budget) async => storage[budget.id] = budget;

  @override
  Future<void> updateBudget(Budget budget) async => storage[budget.id] = budget;

  @override
  Future<void> deleteBudget(String id) async => storage.remove(id);

  @override
  Future<void> clearBudgets() async => storage.clear();

  @override
  int calculateRolloverAmount(Budget budget, int spentAmountInCents) => 0;

  @override
  Future<Budget> rolloverBudget({
    required Budget budget,
    required int spentAmountInCents,
    String? newBudgetId,
    DateTime? newStartDate,
  }) async => budget;
}

class MockTransactionLocalDataSource implements TransactionLocalDataSource {
  @override
  Future<List<Transaction>> getTransactions() async => [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id) async {}
}

void main() {
  Widget buildTestableWidget(
    Widget child, {
    required MockBudgetRepository repo,
  }) {
    return ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(repo),
        transactionLocalDataSourceProvider.overrideWithValue(
          MockTransactionLocalDataSource(),
        ),
      ],
      child: MaterialApp(theme: ThemeData(useMaterial3: true), home: child),
    );
  }

  group('BudgetListScreen Widget Tests', () {
    testWidgets('1. Displays empty state when no budgets exist', (
      tester,
    ) async {
      final repo = MockBudgetRepository();
      await tester.pumpWidget(
        buildTestableWidget(const BudgetListScreen(), repo: repo),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Budgets Set Yet'), findsOneWidget);
      expect(find.text('Add Your First Budget'), findsOneWidget);
    });

    testWidgets('2. Displays list of budgets when data exists', (tester) async {
      final repo = MockBudgetRepository();
      final b1 = Budget(
        id: 'b1',
        name: 'Weekly Snacks',
        amountInCents: 5000,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2026, 1, 1),
      );
      await repo.saveBudget(b1);

      await tester.pumpWidget(
        buildTestableWidget(const BudgetListScreen(), repo: repo),
      );

      await tester.pumpAndSettle();

      expect(find.text('Weekly Snacks'), findsAtLeast(1));
    });

    testWidgets('3. Displays error state on repository failure', (
      tester,
    ) async {
      final repo = MockBudgetRepository()..shouldThrow = true;
      await tester.pumpWidget(
        buildTestableWidget(const BudgetListScreen(), repo: repo),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load budgets'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
