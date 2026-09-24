import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/repositories/budget_repository.dart';
import 'package:pocketledger/features/budgets/presentation/providers/budget_list_notifier.dart';
import 'package:pocketledger/features/budgets/presentation/widgets/budget_recalibration_card.dart';

class MockBudgetRepository implements BudgetRepository {
  final Map<String, Budget> storage = {};
  bool updateCalled = false;
  Budget? updatedBudget;

  @override
  Future<List<Budget>> getBudgets() async => storage.values.toList();

  @override
  Future<Budget?> getBudgetById(String id) async => storage[id];

  @override
  Future<void> saveBudget(Budget budget) async => storage[budget.id] = budget;

  @override
  Future<void> updateBudget(Budget budget) async {
    updateCalled = true;
    updatedBudget = budget;
    storage[budget.id] = budget;
  }

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
  final testBudget = Budget(
    id: 'b1',
    name: 'Groceries',
    amountInCents: 1000000, // $10,000.00
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 1, 1),
  );

  Widget createWidgetUnderTest(Widget child, MockBudgetRepository repo) {
    return ProviderScope(
      overrides: [budgetRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16.0), child: child),
          ),
        ),
      ),
    );
  }

  group('BudgetRecalibrationCard Widget Tests', () {
    testWidgets('1. Recalibration card renders current and recommended cap', (
      tester,
    ) async {
      final repo = MockBudgetRepository()..storage['b1'] = testBudget;

      await tester.pumpWidget(
        createWidgetUnderTest(
          BudgetRecalibrationCard(
            budget: testBudget,
            currentPeriodSpendingInCents: 850000, // $8,500.00
            historicalSpendingInCents: const [850000],
          ),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget Recalibration'), findsOneWidget);
      expect(find.text('Current Cap'), findsOneWidget);
      expect(find.text('Recommended Cap'), findsOneWidget);
      expect(find.byKey(const Key('confidence_badge')), findsOneWidget);
    });

    testWidgets('2. Review Recommendation button opens review modal', (
      tester,
    ) async {
      final repo = MockBudgetRepository()..storage['b1'] = testBudget;

      await tester.pumpWidget(
        createWidgetUnderTest(
          BudgetRecalibrationCard(
            budget: testBudget,
            currentPeriodSpendingInCents: 850000,
            historicalSpendingInCents: const [850000],
          ),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      final reviewBtn = find.byKey(const Key('review_recommendation_button'));
      expect(reviewBtn, findsOneWidget);

      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('recalibration_review_modal')),
        findsOneWidget,
      );
      expect(find.text('Review Budget Recommendation'), findsOneWidget);
      expect(
        find.text('This will not change your budget until you confirm.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '3. Cancel button in modal closes dialog without modifying budget',
      (tester) async {
        final repo = MockBudgetRepository()..storage['b1'] = testBudget;

        await tester.pumpWidget(
          createWidgetUnderTest(
            BudgetRecalibrationCard(
              budget: testBudget,
              currentPeriodSpendingInCents: 850000,
              historicalSpendingInCents: const [850000],
            ),
            repo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('review_recommendation_button')));
        await tester.pumpAndSettle();

        final cancelBtn = find.byKey(const Key('cancel_recommendation_button'));
        expect(cancelBtn, findsOneWidget);

        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('recalibration_review_modal')),
          findsNothing,
        );
        expect(repo.updateCalled, isFalse);
      },
    );

    testWidgets(
      '4. Apply Recommendation button updates saved budget via repository flow',
      (tester) async {
        final repo = MockBudgetRepository()..storage['b1'] = testBudget;
        bool onAppliedCalled = false;

        await tester.pumpWidget(
          createWidgetUnderTest(
            BudgetRecalibrationCard(
              budget: testBudget,
              currentPeriodSpendingInCents: 850000,
              historicalSpendingInCents: const [850000],
              onApplied: () {
                onAppliedCalled = true;
              },
            ),
            repo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('review_recommendation_button')));
        await tester.pumpAndSettle();

        final applyBtn = find.byKey(const Key('apply_recommendation_button'));
        expect(applyBtn, findsOneWidget);

        await tester.tap(applyBtn);
        await tester.pumpAndSettle();

        expect(repo.updateCalled, isTrue);
        expect(repo.updatedBudget, isNotNull);
        expect(onAppliedCalled, isTrue);
      },
    );
  });
}
