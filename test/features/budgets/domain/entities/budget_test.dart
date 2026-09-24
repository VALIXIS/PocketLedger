import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';

void main() {
  group('Budget Domain Entity Tests', () {
    test('creates Budget with required parameters and correct default values', () {
      final startDate = DateTime(2026, 1, 1);
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000, // $500.00
        period: BudgetPeriod.monthly,
        startDate: startDate,
      );

      expect(budget.id, equals('b1'));
      expect(budget.name, equals('Groceries'));
      expect(budget.amountInCents, equals(50000));
      expect(budget.amount, equals(500.0));
      expect(budget.period, equals(BudgetPeriod.monthly));
      expect(budget.startDate, equals(startDate));
      expect(budget.categoryId, equals(''));
      expect(budget.rolloverEnabled, isFalse);
    });

    test('converts double amount to cents correctly', () {
      expect(Budget.doubleToCents(49.99), equals(4999));
      expect(Budget.doubleToCents(100.00), equals(10000));
      expect(Budget.doubleToCents(0.05), equals(5));
    });

    test('supports all budget periods', () {
      expect(BudgetPeriod.values, containsAll([
        BudgetPeriod.weekly,
        BudgetPeriod.monthly,
        BudgetPeriod.yearly,
      ]));
    });

    test('copyWith creates a new updated instance', () {
      final startDate = DateTime(2026, 1, 1);
      final initial = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: startDate,
        categoryId: 'food',
      );

      final updated = initial.copyWith(
        amountInCents: 75000,
        period: BudgetPeriod.weekly,
        rolloverEnabled: true,
      );

      expect(updated.id, equals('b1'));
      expect(updated.name, equals('Groceries'));
      expect(updated.amountInCents, equals(75000));
      expect(updated.amount, equals(750.0));
      expect(updated.period, equals(BudgetPeriod.weekly));
      expect(updated.categoryId, equals('food'));
      expect(updated.rolloverEnabled, isTrue);
    });
  });
}
