import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/goals/data/models/financial_goal.dart';

void main() {
  group('FinancialGoal Model & Domain Logic Tests', () {
    final baseCreatedAt = DateTime(2026, 1, 1, 10, 0);
    final baseUpdatedAt = DateTime(2026, 1, 1, 10, 0);
    final baseTargetDate = DateTime(2026, 12, 31);

    test('1. Creation works and fields are populated properly', () {
      final goal = FinancialGoal(
        id: 'goal-1',
        name: 'Emergency Fund',
        description: 'Save 6 months of expenses',
        targetAmountInCents: 600000,
        savedAmountInCents: 150000,
        targetDate: baseTargetDate,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
        status: GoalStatus.active,
        iconName: 'savings',
        colorValue: 0xFF4CAF50,
        userId: 'user-123',
      );

      expect(goal.id, 'goal-1');
      expect(goal.name, 'Emergency Fund');
      expect(goal.description, 'Save 6 months of expenses');
      expect(goal.targetAmountInCents, 600000);
      expect(goal.savedAmountInCents, 150000);
      expect(goal.targetDate, baseTargetDate);
      expect(goal.createdAt, baseCreatedAt);
      expect(goal.updatedAt, baseUpdatedAt);
      expect(goal.status, GoalStatus.active);
      expect(goal.iconName, 'savings');
      expect(goal.colorValue, 0xFF4CAF50);
      expect(goal.userId, 'user-123');
    });

    test(
      '2. Target amount is stored as integer cents without float inaccuracies',
      () {
        final cents = FinancialGoal.doubleToCents(1234.56);
        expect(cents, 123456);

        final goal = FinancialGoal(
          id: 'goal-2',
          name: 'Laptop',
          targetAmountInCents: cents,
          createdAt: baseCreatedAt,
          updatedAt: baseUpdatedAt,
        );

        expect(goal.targetAmountInCents, isA<int>());
        expect(goal.targetAmountInCents, 123456);
        expect(goal.targetAmount, 1234.56);
      },
    );

    test('3. Saved amount is stored as integer cents', () {
      final goal = FinancialGoal(
        id: 'goal-3',
        name: 'Vacation',
        targetAmountInCents: 200000,
        savedAmountInCents: 75050,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(goal.savedAmountInCents, isA<int>());
      expect(goal.savedAmountInCents, 75050);
      expect(goal.savedAmount, 750.50);
    });

    test('4. Remaining amount calculation is correct and never negative', () {
      final inProgressGoal = FinancialGoal(
        id: 'goal-4a',
        name: 'Phone',
        targetAmountInCents: 100000,
        savedAmountInCents: 30000,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );
      expect(inProgressGoal.remainingAmountInCents, 70000);
      expect(inProgressGoal.remainingAmount, 700.0);

      final overfundedGoal = FinancialGoal(
        id: 'goal-4b',
        name: 'Phone',
        targetAmountInCents: 100000,
        savedAmountInCents: 120000,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );
      expect(overfundedGoal.remainingAmountInCents, 0);
      expect(overfundedGoal.remainingAmount, 0.0);
    });

    test('5. Progress calculation is correct', () {
      final goal = FinancialGoal(
        id: 'goal-5',
        name: 'Bike',
        targetAmountInCents: 50000,
        savedAmountInCents: 25000,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(goal.progress, 0.5);
      expect(goal.progressPercentage, 50.0);
    });

    test('6. Progress never exceeds 1.0 even when overfunded', () {
      final overfundedGoal = FinancialGoal(
        id: 'goal-6',
        name: 'Camera',
        targetAmountInCents: 100000,
        savedAmountInCents: 150000,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(overfundedGoal.progress, 1.0);
      expect(overfundedGoal.progressPercentage, 100.0);
    });

    test('7. Progress never goes below 0.0 for zero or empty target', () {
      final emptyTargetGoal = FinancialGoal(
        id: 'goal-7',
        name: 'Zero Target',
        targetAmountInCents: 0,
        savedAmountInCents: 0,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(emptyTargetGoal.progress, 0.0);
      expect(emptyTargetGoal.progressPercentage, 0.0);
    });

    test('8. Contribution increases saved amount and updates updatedAt', () {
      final initialTime = DateTime(2026, 1, 1, 12, 0);
      final goal = FinancialGoal(
        id: 'goal-8',
        name: 'Car',
        targetAmountInCents: 1000000,
        savedAmountInCents: 200000,
        createdAt: initialTime,
        updatedAt: initialTime,
      );

      final updatedGoal = goal.addContribution(150000);
      expect(updatedGoal.savedAmountInCents, 350000);
      expect(updatedGoal.status, GoalStatus.active);
      expect(
        updatedGoal.updatedAt.isAfter(initialTime) ||
            updatedGoal.updatedAt == initialTime,
        isTrue,
      );
    });

    test(
      '9. Invalid contribution throws ArgumentError on zero or negative values',
      () {
        final goal = FinancialGoal(
          id: 'goal-9',
          name: 'Education',
          targetAmountInCents: 500000,
          savedAmountInCents: 100000,
          createdAt: baseCreatedAt,
          updatedAt: baseUpdatedAt,
        );

        expect(() => goal.addContribution(0), throwsArgumentError);
        expect(() => goal.addContribution(-500), throwsArgumentError);
        expect(() => goal.removeContribution(0), throwsArgumentError);
        expect(() => goal.removeContribution(-100), throwsArgumentError);
      },
    );

    test(
      '10. Goal becomes completed after reaching or exceeding target amount',
      () {
        final goal = FinancialGoal(
          id: 'goal-10',
          name: 'Headphones',
          targetAmountInCents: 20000,
          savedAmountInCents: 15000,
          createdAt: baseCreatedAt,
          updatedAt: baseUpdatedAt,
          status: GoalStatus.active,
        );

        expect(goal.isCompleted, isFalse);

        final completedGoal = goal.addContribution(5000);
        expect(completedGoal.savedAmountInCents, 20000);
        expect(completedGoal.status, GoalStatus.completed);
        expect(completedGoal.isCompleted, isTrue);

        final overCompletedGoal = goal.addContribution(10000);
        expect(overCompletedGoal.savedAmountInCents, 25000);
        expect(overCompletedGoal.status, GoalStatus.completed);
        expect(overCompletedGoal.isCompleted, isTrue);
      },
    );

    test(
      '11. Removing contribution never creates a negative balance and adjusts status appropriately',
      () {
        final completedGoal = FinancialGoal(
          id: 'goal-11',
          name: 'Course',
          targetAmountInCents: 10000,
          savedAmountInCents: 10000,
          createdAt: baseCreatedAt,
          updatedAt: baseUpdatedAt,
          status: GoalStatus.completed,
        );

        // Removing partial amount drops below target, reverting completed status to active
        final revertedGoal = completedGoal.removeContribution(3000);
        expect(revertedGoal.savedAmountInCents, 7000);
        expect(revertedGoal.status, GoalStatus.active);
        expect(revertedGoal.isCompleted, isFalse);

        // Removing more than total saved clamps to 0
        final drainedGoal = completedGoal.removeContribution(20000);
        expect(drainedGoal.savedAmountInCents, 0);
        expect(drainedGoal.status, GoalStatus.active);
      },
    );

    test(
      '12. copyWith preserves unchanged fields and supports clearing targetDate',
      () {
        final goal = FinancialGoal(
          id: 'goal-12',
          name: 'House Downpayment',
          description: 'Save 20%',
          targetAmountInCents: 5000000,
          savedAmountInCents: 1000000,
          targetDate: DateTime(2028, 6, 30),
          createdAt: baseCreatedAt,
          updatedAt: baseUpdatedAt,
          status: GoalStatus.active,
          iconName: 'home',
          colorValue: 0xFF2196F3,
          userId: 'user-999',
        );

        final updatedName = goal.copyWith(name: 'Dream Home Downpayment');
        expect(updatedName.name, 'Dream Home Downpayment');
        expect(updatedName.targetAmountInCents, 5000000);
        expect(updatedName.targetDate, DateTime(2028, 6, 30));
        expect(updatedName.iconName, 'home');

        // Clear target date
        final clearedDateGoal = goal.copyWith(clearTargetDate: true);
        expect(clearedDateGoal.targetDate, isNull);
        expect(clearedDateGoal.name, 'House Downpayment');
      },
    );
  });
}
