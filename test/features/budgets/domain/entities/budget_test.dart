import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';

void main() {
  group('Budget Entity Tests', () {
    test('creates budget instance with integer cents correctly', () {
      final startDate = DateTime(2026, 1, 1);
      final budget = Budget(
        id: 'budget_1',
        categoryId: 'food',
        name: 'Food & Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: startDate,
        rolloverEnabled: true,
      );

      expect(budget.id, equals('budget_1'));
      expect(budget.categoryId, equals('food'));
      expect(budget.name, equals('Food & Groceries'));
      expect(budget.amountInCents, equals(50000));
      expect(budget.amount, equals(500.0));
      expect(budget.period, equals(BudgetPeriod.monthly));
      expect(budget.startDate, equals(startDate));
      expect(budget.rolloverEnabled, isTrue);
    });

    test('supports doubleToCents helper safely', () {
      expect(Budget.doubleToCents(19.99), equals(1999));
      expect(Budget.doubleToCents(100.00), equals(10000));
      expect(Budget.doubleToCents(0.50), equals(50));
    });

    test('copyWith updates specified fields correctly', () {
      final startDate = DateTime(2026, 1, 1);
      final budget = Budget(
        id: 'b1',
        categoryId: 'transport',
        name: 'Transport',
        amountInCents: 15000,
        period: BudgetPeriod.weekly,
        startDate: startDate,
        rolloverEnabled: false,
      );

      final updated = budget.copyWith(
        amountInCents: 20000,
        period: BudgetPeriod.yearly,
        rolloverEnabled: true,
      );

      expect(updated.id, equals('b1'));
      expect(updated.categoryId, equals('transport'));
      expect(updated.amountInCents, equals(20000));
      expect(updated.amount, equals(200.0));
      expect(updated.period, equals(BudgetPeriod.yearly));
      expect(updated.rolloverEnabled, isTrue);
    });

    test('equality and hashCode work as expected', () {
      final date = DateTime(2026, 3, 15);
      final b1 = Budget(
        id: 'b1',
        categoryId: 'c1',
        name: 'Test',
        amountInCents: 1000,
        period: BudgetPeriod.weekly,
        startDate: date,
        rolloverEnabled: false,
      );
      final b2 = Budget(
        id: 'b1',
        categoryId: 'c1',
        name: 'Test',
        amountInCents: 1000,
        period: BudgetPeriod.weekly,
        startDate: date,
        rolloverEnabled: false,
      );
      final b3 = Budget(
        id: 'b2',
        categoryId: 'c1',
        name: 'Test',
        amountInCents: 1000,
        period: BudgetPeriod.weekly,
        startDate: date,
        rolloverEnabled: false,
      );

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });

    test('supports all budget periods: weekly, monthly, yearly', () {
      expect(BudgetPeriod.values, containsAll([
        BudgetPeriod.weekly,
        BudgetPeriod.monthly,
        BudgetPeriod.yearly,
      ]));
    });
  });
}
