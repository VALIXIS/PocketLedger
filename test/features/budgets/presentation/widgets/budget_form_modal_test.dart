import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/repositories/budget_repository.dart';
import 'package:pocketledger/features/budgets/presentation/providers/budget_list_notifier.dart';
import 'package:pocketledger/features/budgets/presentation/widgets/budget_form_modal.dart';

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

void main() {
  Widget buildTestableWidget(Widget child, {required MockBudgetRepository repo}) {
    return ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  group('BudgetFormModal Widget Tests', () {
    testWidgets('14. Add mode displays empty/default fields', (tester) async {
      final repo = MockBudgetRepository();
      await tester.pumpWidget(
        buildTestableWidget(const BudgetFormModal(), repo: repo),
      );

      expect(find.text('Add New Budget'), findsOneWidget);
      expect(find.text('Create Budget'), findsOneWidget);
    });

    testWidgets('15. Edit mode pre-populates existing values', (tester) async {
      final repo = MockBudgetRepository();
      final existing = Budget(
        id: 'b1',
        name: 'Existing Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildTestableWidget(BudgetFormModal(existingBudget: existing), repo: repo),
      );

      expect(find.text('Edit Budget'), findsOneWidget);
      expect(find.text('Existing Groceries'), findsOneWidget);
      expect(find.text('500.00'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('16. Invalid amount is rejected', (tester) async {
      final repo = MockBudgetRepository();
      await tester.pumpWidget(
        buildTestableWidget(const BudgetFormModal(), repo: repo),
      );

      // Enter name but invalid amount
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Budget');
      await tester.enterText(find.byType(TextFormField).at(1), '-50');
      await tester.tap(find.text('Create Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid positive amount'), findsOneWidget);
    });

    testWidgets('17. Empty name is rejected', (tester) async {
      final repo = MockBudgetRepository();
      await tester.pumpWidget(
        buildTestableWidget(const BudgetFormModal(), repo: repo),
      );

      await tester.tap(find.text('Create Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a budget name'), findsOneWidget);
    });
  });
}
