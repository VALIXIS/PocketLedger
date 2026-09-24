import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget_alert.dart';
import 'package:pocketledger/features/budgets/domain/services/budget_alert_engine.dart';

void main() {
  group('BudgetAlertEngine Unit Tests', () {
    const engine = BudgetAlertEngine();
    final testDate = DateTime(2026, 1, 1);

    test('1. Evaluates normal level (none) when spent is under 75%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 10000, // $100.00
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 7400); // 74%

      expect(alert.level, equals(BudgetAlertLevel.none));
      expect(alert.percentageSpent, equals(74.0));
      expect(alert.isActive, isFalse);
    });

    test('2. Evaluates warning level when spent is exactly 75%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 7500); // 75%

      expect(alert.level, equals(BudgetAlertLevel.warning));
      expect(alert.percentageSpent, equals(75.0));
      expect(alert.isActive, isTrue);
      expect(alert.message, contains('warning'));
    });

    test('3. Evaluates warning level when spent is between 75% and 89.9%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 20000, // $200.00
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 17000); // 85%

      expect(alert.level, equals(BudgetAlertLevel.warning));
      expect(alert.percentageSpent, equals(85.0));
    });

    test('4. Evaluates danger level when spent is exactly 90%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Entertainment',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 9000); // 90%

      expect(alert.level, equals(BudgetAlertLevel.danger));
      expect(alert.percentageSpent, equals(90.0));
      expect(alert.message, contains('critical'));
    });

    test('5. Evaluates danger level when spent is between 90% and 99.9%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Utilities',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 9500); // 95%

      expect(alert.level, equals(BudgetAlertLevel.danger));
      expect(alert.percentageSpent, equals(95.0));
    });

    test('6. Evaluates exceeded level when spent is exactly 100%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Shopping',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 10000); // 100%

      expect(alert.level, equals(BudgetAlertLevel.exceeded));
      expect(alert.percentageSpent, equals(100.0));
      expect(alert.remainingInCents, equals(0));
      expect(alert.message, contains('exceeded'));
    });

    test('7. Evaluates exceeded level when spent is over 100%', () {
      final budget = Budget(
        id: 'b1',
        name: 'Shopping',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alert = engine.evaluateBudget(budget: budget, spentInCents: 15000); // 150%

      expect(alert.level, equals(BudgetAlertLevel.exceeded));
      expect(alert.percentageSpent, equals(150.0));
      expect(alert.remainingInCents, equals(-5000));
    });

    test('8. Handles zero budget amount edge cases cleanly', () {
      final zeroBudget = Budget(
        id: 'b_zero',
        name: 'Zero Test',
        amountInCents: 0,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      final alertSpent0 = engine.evaluateBudget(budget: zeroBudget, spentInCents: 0);
      expect(alertSpent0.level, equals(BudgetAlertLevel.none));
      expect(alertSpent0.percentageSpent, equals(0.0));

      final alertSpentMore = engine.evaluateBudget(budget: zeroBudget, spentInCents: 500);
      expect(alertSpentMore.level, equals(BudgetAlertLevel.exceeded));
      expect(alertSpentMore.percentageSpent, equals(100.0));
    });

    test('9. Throws ArgumentError when spent amount is negative', () {
      final budget = Budget(
        id: 'b1',
        name: 'Test',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: testDate,
      );

      expect(
        () => engine.evaluateBudget(budget: budget, spentInCents: -500),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('10. Evaluates multiple budgets and sorts by priority (Exceeded > Danger > Warning)', () {
      final b1 = Budget(id: 'b1', name: 'Warning B', amountInCents: 10000, period: BudgetPeriod.monthly, startDate: testDate);
      final b2 = Budget(id: 'b2', name: 'Exceeded B', amountInCents: 10000, period: BudgetPeriod.monthly, startDate: testDate);
      final b3 = Budget(id: 'b3', name: 'Danger B', amountInCents: 10000, period: BudgetPeriod.monthly, startDate: testDate);
      final b4 = Budget(id: 'b4', name: 'Normal B', amountInCents: 10000, period: BudgetPeriod.monthly, startDate: testDate);

      final spentMap = {
        'b1': 8000,  // Warning 80%
        'b2': 12000, // Exceeded 120%
        'b3': 9500,  // Danger 95%
        'b4': 5000,  // Normal 50%
      };

      final activeAlerts = engine.evaluateActiveAlerts([b1, b2, b3, b4], spentMap);

      expect(activeAlerts.length, equals(3));
      expect(activeAlerts[0].budgetId, equals('b2')); // Exceeded first
      expect(activeAlerts[0].level, equals(BudgetAlertLevel.exceeded));

      expect(activeAlerts[1].budgetId, equals('b3')); // Danger second
      expect(activeAlerts[1].level, equals(BudgetAlertLevel.danger));

      expect(activeAlerts[2].budgetId, equals('b1')); // Warning third
      expect(activeAlerts[2].level, equals(BudgetAlertLevel.warning));
    });
  });
}
