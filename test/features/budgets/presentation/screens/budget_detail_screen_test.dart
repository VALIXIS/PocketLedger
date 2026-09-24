import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/repositories/budget_repository.dart';
import 'package:pocketledger/features/budgets/presentation/providers/budget_list_notifier.dart';
import 'package:pocketledger/features/budgets/presentation/screens/budget_detail_screen.dart';
import 'package:pocketledger/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class MockBudgetRepository implements BudgetRepository {
  final Map<String, Budget> storage = {};

  @override
  Future<List<Budget>> getBudgets() async => storage.values.toList();

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
  Widget buildTestableWidget(Widget child, {required MockBudgetRepository repo}) {
    return ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(repo),
        transactionLocalDataSourceProvider.overrideWithValue(MockTransactionLocalDataSource()),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      ),
    );
  }

  group('BudgetDetailScreen Widget Tests', () {
    testWidgets('6. Displays budget detail information correctly', (tester) async {
      final repo = MockBudgetRepository();
      final b1 = Budget(
        id: 'b1',
        name: 'Dining Out',
        amountInCents: 25000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      await repo.saveBudget(b1);

      await tester.pumpWidget(
        buildTestableWidget(const BudgetDetailScreen(budgetId: 'b1'), repo: repo),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dining Out'), findsOneWidget);
      expect(find.text('Pacing & Projections'), findsOneWidget);
    });

    testWidgets('8. Delete action shows confirmation dialog', (tester) async {
      final repo = MockBudgetRepository();
      final b1 = Budget(
        id: 'b1',
        name: 'Dining Out',
        amountInCents: 25000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      await repo.saveBudget(b1);

      await tester.pumpWidget(
        buildTestableWidget(const BudgetDetailScreen(budgetId: 'b1'), repo: repo),
      );

      await tester.pumpAndSettle();

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Budget'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Dining Out"? This action cannot be undone.'), findsOneWidget);
    });
  });
}
