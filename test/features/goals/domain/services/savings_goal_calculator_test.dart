import 'package:flutter_test/flutter_test.dart';

import 'package:pocketledger/features/goals/domain/services/savings_goal_calculator.dart';

void main() {
  const calculator = SavingsGoalCalculator();

  group('SavingsGoalCalculator', () {
    test('calculates months required correctly', () {
      final result = calculator.calculate(
        targetAmountInCents: 10000000,
        currentSavedAmountInCents: 2000000,
        monthlyContributionInCents: 1000000,
        startDate: DateTime(2026, 1, 1),
      );

      expect(result.remainingAmountInCents, 8000000);

      expect(result.monthsRequired, 8);

      expect(result.projectedCompletionDate, DateTime(2026, 9, 1));
      expect(result.isAlreadyCompleted, isFalse);
      expect(result.isAchievable, isTrue);
    });

    test('returns zero months when goal is already completed', () {
      final result = calculator.calculate(
        targetAmountInCents: 100000,
        currentSavedAmountInCents: 120000,
        monthlyContributionInCents: 5000,
      );

      expect(result.monthsRequired, 0);

      expect(result.remainingAmountInCents, 0);

      expect(result.progressPercentage, 100);
      expect(result.isAlreadyCompleted, isTrue);
    });

    test('calculates required monthly contribution', () {
      final result = calculator.requiredMonthlyContribution(
        targetAmountInCents: 1200000,
        currentSavedAmountInCents: 200000,
        months: 10,
      );

      expect(result, 100000);
    });

    test(
      'required monthly contribution returns 0 if target is already met',
      () {
        final result = calculator.requiredMonthlyContribution(
          targetAmountInCents: 50000,
          currentSavedAmountInCents: 60000,
          months: 5,
        );

        expect(result, 0);
      },
    );

    test(
      'throws ArgumentError on invalid inputs to requiredMonthlyContribution',
      () {
        expect(
          () => calculator.requiredMonthlyContribution(
            targetAmountInCents: 100000,
            currentSavedAmountInCents: 10000,
            months: 0,
          ),
          throwsArgumentError,
        );
      },
    );

    test('throws ArgumentError on negative parameters to calculate', () {
      expect(
        () => calculator.calculate(
          targetAmountInCents: -1,
          currentSavedAmountInCents: 100,
          monthlyContributionInCents: 100,
        ),
        throwsArgumentError,
      );

      expect(
        () => calculator.calculate(
          targetAmountInCents: 1000,
          currentSavedAmountInCents: -5,
          monthlyContributionInCents: 100,
        ),
        throwsArgumentError,
      );

      expect(
        () => calculator.calculate(
          targetAmountInCents: 1000,
          currentSavedAmountInCents: 100,
          monthlyContributionInCents: -10,
        ),
        throwsArgumentError,
      );
    });

    test('handles zero monthly contribution when uncompleted', () {
      final result = calculator.calculate(
        targetAmountInCents: 100000,
        currentSavedAmountInCents: 25000,
        monthlyContributionInCents: 0,
      );

      expect(result.monthsRequired, 0);
      expect(result.remainingAmountInCents, 75000);
      expect(result.progressPercentage, 25.0);
      expect(result.isAchievable, isFalse);
    });

    test('does not produce progress above 100', () {
      final result = calculator.calculate(
        targetAmountInCents: 100000,
        currentSavedAmountInCents: 200000,
        monthlyContributionInCents: 5000,
      );

      expect(result.progressPercentage, 100);
    });

    test('handles month overflow and month-end day clipping properly', () {
      final result = calculator.calculate(
        targetAmountInCents: 20000,
        currentSavedAmountInCents: 0,
        monthlyContributionInCents: 20000,
        startDate: DateTime(2026, 1, 31),
      );

      expect(result.monthsRequired, 1);
      // February 2026 has 28 days, day should clip to 28
      expect(result.projectedCompletionDate.year, 2026);
      expect(result.projectedCompletionDate.month, 2);
      expect(result.projectedCompletionDate.day, 28);
    });
  });
}
