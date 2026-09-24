import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget_stress_scenario.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget_stress_test.dart';
import 'package:pocketledger/features/budgets/domain/services/budget_stress_test_engine.dart';

void main() {
  group('BudgetStressTestEngine Unit Tests', () {
    const engine = BudgetStressTestEngine();

    test('1. Baseline scenario (0% stress) maintains exact spending', () {
      final result = engine.run(
        allocationInCents: 1000000, // $10,000.00
        currentSpendingInCents: 800000, // $8,000.00
        scenario: BudgetStressScenario.baseline,
      );

      expect(result.stressedSpendingInCents, equals(800000));
      expect(result.remainingInCents, equals(200000));
      expect(result.exceedsBudget, isFalse);
      expect(result.utilizationPercent, equals(80.0));
      expect(result.status, equals(BudgetStressStatus.nearLimit));
    });

    test('2. Mild scenario (10% stress) calculates correctly', () {
      final result = engine.run(
        allocationInCents: 1000000, // $10,000.00
        currentSpendingInCents: 800000, // $8,000.00
        scenario: BudgetStressScenario.mild,
      );

      // 8000 + 800 = 8800
      expect(result.stressedSpendingInCents, equals(880000));
      expect(result.remainingInCents, equals(120000));
      expect(result.exceedsBudget, isFalse);
      expect(result.utilizationPercent, equals(88.0));
      expect(result.status, equals(BudgetStressStatus.nearLimit));
    });

    test('3. Moderate scenario (20% stress) calculates correctly', () {
      final result = engine.run(
        allocationInCents: 1000000, // $10,000.00
        currentSpendingInCents: 800000, // $8,000.00
        scenario: BudgetStressScenario.moderate,
      );

      // 8000 + 1600 = 9600
      expect(result.stressedSpendingInCents, equals(960000));
      expect(result.remainingInCents, equals(40000));
      expect(result.exceedsBudget, isFalse);
      expect(result.utilizationPercent, equals(96.0));
      expect(result.status, equals(BudgetStressStatus.nearLimit));
    });

    test('4. Severe scenario (35% stress) calculates correctly', () {
      final result = engine.run(
        allocationInCents: 1000000, // $10,000.00
        currentSpendingInCents: 500000, // $5,000.00
        scenario: BudgetStressScenario.severe,
      );

      // 5000 + 1750 = 6750
      expect(result.stressedSpendingInCents, equals(675000));
      expect(result.remainingInCents, equals(325000));
      expect(result.exceedsBudget, isFalse);
      expect(result.utilizationPercent, equals(67.5));
      expect(result.status, equals(BudgetStressStatus.withinBudget));
    });

    test('5. Extreme scenario (50% stress) calculates correctly', () {
      final result = engine.run(
        allocationInCents: 1000000, // $10,000.00
        currentSpendingInCents: 400000, // $4,000.00
        scenario: BudgetStressScenario.extreme,
      );

      // 4000 + 2000 = 6000
      expect(result.stressedSpendingInCents, equals(600000));
      expect(result.remainingInCents, equals(400000));
      expect(result.exceedsBudget, isFalse);
      expect(result.utilizationPercent, equals(60.0));
      expect(result.status, equals(BudgetStressStatus.withinBudget));
    });

    test(
      '6. Detects exceeded budget under stress (Budget 10,000, Spent 9,000, 20% stress = 10,800)',
      () {
        final result = engine.run(
          allocationInCents: 1000000, // $10,000.00
          currentSpendingInCents: 900000, // $9,000.00
          scenario: BudgetStressScenario.moderate, // +20%
        );

        expect(result.stressedSpendingInCents, equals(1080000)); // $10,800.00
        expect(result.remainingInCents, equals(0));
        expect(result.exceedsBudget, isTrue);
        expect(result.status, equals(BudgetStressStatus.exceeded));
      },
    );

    test('7. Handles zero budget allocation safely', () {
      final zeroResultSpent0 = engine.run(
        allocationInCents: 0,
        currentSpendingInCents: 0,
        scenario: BudgetStressScenario.moderate,
      );
      expect(zeroResultSpent0.exceedsBudget, isFalse);
      expect(zeroResultSpent0.utilizationPercent, equals(0.0));

      final zeroResultSpentMore = engine.run(
        allocationInCents: 0,
        currentSpendingInCents: 500,
        scenario: BudgetStressScenario.moderate,
      );
      expect(zeroResultSpentMore.exceedsBudget, isTrue);
      expect(zeroResultSpentMore.status, equals(BudgetStressStatus.exceeded));
    });

    test('8. Handles zero spending safely across all scenarios', () {
      for (final scenario in BudgetStressScenario.values) {
        final result = engine.run(
          allocationInCents: 500000,
          currentSpendingInCents: 0,
          scenario: scenario,
        );
        expect(result.stressedSpendingInCents, equals(0));
        expect(result.remainingInCents, equals(500000));
        expect(result.exceedsBudget, isFalse);
        expect(result.status, equals(BudgetStressStatus.withinBudget));
      }
    });

    test('9. Normalizes negative spending safely to 0', () {
      final result = engine.run(
        allocationInCents: 500000,
        currentSpendingInCents: -25000,
        scenario: BudgetStressScenario.moderate,
      );

      expect(result.currentSpendingInCents, equals(0));
      expect(result.stressedSpendingInCents, equals(0));
      expect(result.remainingInCents, equals(500000));
      expect(result.exceedsBudget, isFalse);
    });

    test('10. Enforces integer-cents precision arithmetic', () {
      final result = engine.run(
        allocationInCents: 33333, // $333.33
        currentSpendingInCents: 12345, // $123.45
        scenario: BudgetStressScenario.moderate, // 20%
      );

      // 12345 + (12345 * 20 ~/ 100) = 12345 + 2469 = 14814
      expect(result.stressedSpendingInCents, equals(14814));
      expect(result.remainingInCents, equals(18519));
      expect(result.exceedsBudget, isFalse);
    });
  });
}
