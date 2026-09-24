import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:pocketledger/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';

class MockBudgetLocalDataSource extends Fake implements BudgetLocalDataSource {
  final Map<String, Budget> storage = {};

  @override
  Future<void> saveBudget(Budget budget) async {
    storage[budget.id] = budget;
  }
}

void main() {
  late MockBudgetLocalDataSource mockDataSource;
  late BudgetRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockBudgetLocalDataSource();
    repository = BudgetRepositoryImpl(localDataSource: mockDataSource);
  });

  group('Budget Rollover Logic Unit Tests', () {
    test(
      'Test 1 — Partial spending: 10000 budget - 7500 spent = 2500 rollover',
      () {
        final budget = Budget(
          id: 'b1',
          name: 'Dining',
          amountInCents: 10000,
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 1, 1),
          rolloverEnabled: true,
        );

        final rollover = repository.calculateRolloverAmount(budget, 7500);
        expect(rollover, equals(2500));
      },
    );

    test('Test 2 — Fully spent: 10000 budget - 10000 spent = 0 rollover', () {
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        rolloverEnabled: true,
      );

      final rollover = repository.calculateRolloverAmount(budget, 10000);
      expect(rollover, equals(0));
    });

    test('Test 3 — Overspent: 10000 budget - 12000 spent = 0 rollover', () {
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        rolloverEnabled: true,
      );

      final rollover = repository.calculateRolloverAmount(budget, 12000);
      expect(rollover, equals(0));
    });

    test('Test 4 — No spending: 10000 budget - 0 spent = 10000 rollover', () {
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        rolloverEnabled: true,
      );

      final rollover = repository.calculateRolloverAmount(budget, 0);
      expect(rollover, equals(10000));
    });

    test(
      'Test 5 — Weekly budget rollover and start date calculation',
      () async {
        final startDate = DateTime(2026, 1, 1);
        final budget = Budget(
          id: 'b_weekly',
          name: 'Weekly Snacks',
          amountInCents: 5000,
          period: BudgetPeriod.weekly,
          startDate: startDate,
          rolloverEnabled: true,
        );

        final nextBudget = await repository.rolloverBudget(
          budget: budget,
          spentAmountInCents: 2000, // unused 3000
        );

        expect(nextBudget.period, equals(BudgetPeriod.weekly));
        expect(nextBudget.amountInCents, equals(8000)); // 5000 + 3000
        expect(
          nextBudget.startDate,
          equals(startDate.add(const Duration(days: 7))),
        );
      },
    );

    test(
      'Test 6 — Monthly budget rollover and start date calculation',
      () async {
        final startDate = DateTime(2026, 1, 15);
        final budget = Budget(
          id: 'b_monthly',
          name: 'Monthly Groceries',
          amountInCents: 40000,
          period: BudgetPeriod.monthly,
          startDate: startDate,
          rolloverEnabled: true,
        );

        final nextBudget = await repository.rolloverBudget(
          budget: budget,
          spentAmountInCents: 30000, // unused 10000
        );

        expect(nextBudget.period, equals(BudgetPeriod.monthly));
        expect(nextBudget.amountInCents, equals(50000)); // 40000 + 10000
        expect(nextBudget.startDate, equals(DateTime(2026, 2, 15)));
      },
    );

    test(
      'Test 7 — Yearly budget rollover and start date calculation',
      () async {
        final startDate = DateTime(2026, 3, 1);
        final budget = Budget(
          id: 'b_yearly',
          name: 'Annual Vacation',
          amountInCents: 120000,
          period: BudgetPeriod.yearly,
          startDate: startDate,
          rolloverEnabled: true,
        );

        final nextBudget = await repository.rolloverBudget(
          budget: budget,
          spentAmountInCents: 50000, // unused 70000
        );

        expect(nextBudget.period, equals(BudgetPeriod.yearly));
        expect(nextBudget.amountInCents, equals(190000)); // 120000 + 70000
        expect(nextBudget.startDate, equals(DateTime(2027, 3, 1)));
      },
    );

    test('Test 8 — Integer precision with non-round cent values', () {
      final budget = Budget(
        id: 'b_precision',
        name: 'Custom Budget',
        amountInCents: 9999,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        rolloverEnabled: true,
      );

      final rollover = repository.calculateRolloverAmount(budget, 3333);
      expect(rollover, equals(6666));
      expect(rollover, isA<int>());
    });
  });
}
