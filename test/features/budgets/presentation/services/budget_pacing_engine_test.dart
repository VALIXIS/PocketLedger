import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/presentation/services/budget_pacing_engine.dart';

void main() {
  late BudgetPacingEngine pacingEngine;

  setUp(() {
    pacingEngine = const BudgetPacingEngine();
  });

  group('BudgetPacingEngine Unit Tests', () {
    test('1. On-track budget: 10000 budget, 1500 spent early in period', () {
      final periodStart = DateTime(2026, 1, 1);
      final currentTime = DateTime(2026, 1, 7); // ~19.3% of month
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 1500,
        currentTime: currentTime,
      );

      expect(result.isProjectedToExceed, isFalse);
      expect(result.status, equals(BudgetPacingStatus.onTrack));
    });

    test('2. Projected blowout: 10000 budget, 6000 spent at 40% elapsed', () {
      final periodStart = DateTime(2026, 1, 1);
      // Jan has 31 days. 40% elapsed ~ day 13 (Jan 13 10:00)
      final currentTime = DateTime(2026, 1, 13, 9, 36);
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 6000,
        currentTime: currentTime,
      );

      expect(result.projectedSpendInCents, greaterThan(10000));
      expect(result.isProjectedToExceed, isTrue);
      expect(result.status, equals(BudgetPacingStatus.projectedToExceed));
    });

    test('3. Already exceeded: 10000 budget, 11000 spent', () {
      final periodStart = DateTime(2026, 1, 1);
      final currentTime = DateTime(2026, 1, 15);
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 11000,
        currentTime: currentTime,
      );

      expect(result.status, equals(BudgetPacingStatus.exceeded));
      expect(result.remainingInCents, equals(-1000));
    });

    test('4. Zero spending: 10000 budget, 0 spent', () {
      final periodStart = DateTime(2026, 1, 1);
      final currentTime = DateTime(2026, 1, 15);
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 0,
        currentTime: currentTime,
      );

      expect(result.projectedSpendInCents, equals(0));
      expect(result.isProjectedToExceed, isFalse);
      expect(result.status, equals(BudgetPacingStatus.onTrack));
    });

    test('5. Zero budget: 0 budget, 0 spent (no division by zero)', () {
      final periodStart = DateTime(2026, 1, 1);
      final currentTime = DateTime(2026, 1, 15);
      final budget = Budget(
        id: 'b1',
        name: 'Empty',
        amountInCents: 0,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 0,
        currentTime: currentTime,
      );

      expect(result.projectedSpendInCents, equals(0));
      expect(result.isProjectedToExceed, isFalse);
      expect(result.status, equals(BudgetPacingStatus.onTrack));
    });

    test('6. Weekly period calculation', () {
      final periodStart = DateTime(2026, 1, 1);
      final currentTime = DateTime(2026, 1, 4, 12, 0); // half week
      final budget = Budget(
        id: 'b_weekly',
        name: 'Snacks',
        amountInCents: 5000,
        period: BudgetPeriod.weekly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 2000,
        currentTime: currentTime,
      );

      expect(result.elapsedFraction, closeTo(0.5, 0.1));
      expect(result.projectedSpendInCents, closeTo(4000, 500));
    });

    test('7. Monthly period calculation', () {
      final periodStart = DateTime(2026, 1, 15);
      final currentTime = DateTime(2026, 1, 30);
      final budget = Budget(
        id: 'b_monthly',
        name: 'Groceries',
        amountInCents: 30000,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 15000,
        currentTime: currentTime,
      );

      expect(result.elapsedFraction, greaterThan(0.4));
      expect(result.elapsedFraction, lessThan(0.6));
    });

    test('8. Yearly period calculation', () {
      final periodStart = DateTime(2026, 1, 1);
      final currentTime = DateTime(2026, 7, 1); // mid year
      final budget = Budget(
        id: 'b_yearly',
        name: 'Annual Pass',
        amountInCents: 120000,
        period: BudgetPeriod.yearly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 60000,
        currentTime: currentTime,
      );

      expect(result.elapsedFraction, closeTo(0.5, 0.05));
    });

    test('9. Leap year date calculation', () {
      final leapStart = DateTime(2028, 2, 1); // 2028 is a leap year
      final nextMonth = BudgetPacingEngine.getNextPeriodStartDate(
        leapStart,
        BudgetPeriod.monthly,
      );

      expect(nextMonth.month, equals(3));
      expect(nextMonth.day, equals(1));

      final leapYearEnd = BudgetPacingEngine.getNextPeriodStartDate(
        leapStart,
        BudgetPeriod.yearly,
      );
      expect(leapYearEnd.year, equals(2029));
    });

    test('10. Completed period does not extrapolate spending', () {
      final periodStart = DateTime(2026, 1, 1);
      final completedTime = DateTime(2026, 1, 31, 23, 59, 59);
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: periodStart,
      );

      final result = pacingEngine.calculatePacing(
        budget: budget,
        spentInCents: 8000,
        currentTime: completedTime,
      );

      expect(result.elapsedFraction, closeTo(1.0, 0.01));
      expect(result.projectedSpendInCents, equals(8000));
      expect(result.daysRemaining, equals(0));
      expect(result.isProjectedToExceed, isFalse);
    });

    test('11. Negative spending throws ArgumentError', () {
      final budget = Budget(
        id: 'b1',
        name: 'Dining',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      expect(
        () => pacingEngine.calculatePacing(budget: budget, spentInCents: -500),
        throwsArgumentError,
      );
    });
  });
}
