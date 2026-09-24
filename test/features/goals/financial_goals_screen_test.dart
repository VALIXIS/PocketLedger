import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/goals/data/models/financial_goal.dart';
import 'package:pocketledger/features/goals/domain/repositories/goals_repository.dart';
import 'package:pocketledger/features/goals/presentation/providers/goal_list_notifier.dart';
import 'package:pocketledger/features/goals/presentation/screens/financial_goals_screen.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_card.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_empty_state.dart';

class MockGoalsRepository implements GoalsRepository {
  final Map<String, FinancialGoal> goals = {};

  @override
  Future<void> addGoal(FinancialGoal goal) async {
    goals[goal.id] = goal;
  }

  @override
  Future<void> updateGoal(FinancialGoal goal) async {
    goals[goal.id] = goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    goals.remove(id);
  }

  @override
  Future<FinancialGoal?> getGoal(String id) async => goals[id];

  @override
  Future<List<FinancialGoal>> getAllGoals() async => goals.values.toList();

  @override
  Future<List<FinancialGoal>> getGoalsForUser(String userId) async =>
      goals.values.where((g) => g.userId == userId).toList();

  @override
  Future<bool> containsGoal(String id) async => goals.containsKey(id);
}

Widget createGoalsScreenApp({required MockGoalsRepository repository}) {
  return ProviderScope(
    overrides: [
      goalsRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: FinancialGoalsScreen(),
    ),
  );
}

void main() {
  group('FinancialGoalsScreen Widget Tests', () {
    testWidgets('renders empty state when no goals exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockGoalsRepository();

      await tester.pumpWidget(createGoalsScreenApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Savings Goals'), findsOneWidget);
      expect(find.byType(GoalEmptyState), findsOneWidget);
      expect(find.text('No Savings Goals Yet'), findsOneWidget);
    });

    testWidgets('renders summary header and goal cards when goals exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockGoalsRepository();
      final goal1 = FinancialGoal(
        id: 'g-1',
        name: 'Emergency Fund',
        targetAmountInCents: 100000,
        savedAmountInCents: 50000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final goal2 = FinancialGoal(
        id: 'g-2',
        name: 'Vacation',
        targetAmountInCents: 200000,
        savedAmountInCents: 200000,
        status: GoalStatus.completed,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addGoal(goal1);
      await repo.addGoal(goal2);

      await tester.pumpWidget(createGoalsScreenApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL SAVINGS PROGRESS'), findsOneWidget);
      expect(find.text('1 of 2 Completed'), findsOneWidget);
      expect(find.text('Emergency Fund'), findsOneWidget);
      expect(find.text('Vacation'), findsOneWidget);
      expect(find.byType(GoalCard), findsNWidgets(2));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('filters goals by Active and Completed tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockGoalsRepository();
      final goal1 = FinancialGoal(
        id: 'g-1',
        name: 'Active Car Fund',
        targetAmountInCents: 100000,
        savedAmountInCents: 20000,
        status: GoalStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final goal2 = FinancialGoal(
        id: 'g-2',
        name: 'Completed Gadget Fund',
        targetAmountInCents: 50000,
        savedAmountInCents: 50000,
        status: GoalStatus.completed,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addGoal(goal1);
      await repo.addGoal(goal2);

      await tester.pumpWidget(createGoalsScreenApp(repository: repo));
      await tester.pumpAndSettle();

      // Tap Active filter
      await tester.tap(find.text('Active (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Active Car Fund'), findsOneWidget);
      expect(find.text('Completed Gadget Fund'), findsNothing);

      // Tap Completed filter
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Active Car Fund'), findsNothing);
      expect(find.text('Completed Gadget Fund'), findsOneWidget);

      // Tap All filter
      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Active Car Fund'), findsOneWidget);
      expect(find.text('Completed Gadget Fund'), findsOneWidget);
    });

    testWidgets('pull-to-refresh triggers reload cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockGoalsRepository();
      final goal = FinancialGoal(
        id: 'g-refresh',
        name: 'Refresh Test Goal',
        targetAmountInCents: 80000,
        savedAmountInCents: 10000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addGoal(goal);

      await tester.pumpWidget(createGoalsScreenApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Refresh Test Goal'), findsOneWidget);

      await tester.fling(
        find.text('Refresh Test Goal'),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Refresh Test Goal'), findsOneWidget);
    });
  });
}
