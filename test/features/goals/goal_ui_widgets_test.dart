import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/goals/data/models/financial_goal.dart';
import 'package:pocketledger/features/goals/domain/repositories/goals_repository.dart';
import 'package:pocketledger/features/goals/presentation/providers/goal_list_notifier.dart';
import 'package:pocketledger/features/goals/presentation/widgets/contribution_modal.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_card.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_empty_state.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_form.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_milestone_badges.dart';
import 'package:pocketledger/features/goals/presentation/widgets/goal_progress_indicator.dart';

class FakeGoalsRepository implements GoalsRepository {
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

Widget createTestApp({
  required Widget child,
  FakeGoalsRepository? repository,
}) {
  final repo = repository ?? FakeGoalsRepository();
  return ProviderScope(
    overrides: [
      goalsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('GoalProgressIndicator Tests', () {
    testWidgets('renders correct progress and accessible semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GoalProgressIndicator(progress: 0.75, height: 10),
        ),
      );

      expect(find.byType(GoalProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(GoalProgressIndicator));
      expect(semantics.label, contains('75.0 percent'));
    });
  });

  group('GoalMilestoneBadges Tests', () {
    testWidgets('computes and displays correct milestone badge labels', (
      tester,
    ) async {
      // 0% -> Getting Started
      await tester.pumpWidget(
        createTestApp(child: const GoalMilestoneBadge(progress: 0.0)),
      );
      expect(find.text('Getting Started'), findsOneWidget);

      // 30% -> Quarter Way (25%)
      await tester.pumpWidget(
        createTestApp(child: const GoalMilestoneBadge(progress: 0.30)),
      );
      expect(find.text('Quarter Way'), findsOneWidget);

      // 55% -> Halfway There (50%)
      await tester.pumpWidget(
        createTestApp(child: const GoalMilestoneBadge(progress: 0.55)),
      );
      expect(find.text('Halfway There'), findsOneWidget);

      // 80% -> Almost There (75%)
      await tester.pumpWidget(
        createTestApp(child: const GoalMilestoneBadge(progress: 0.80)),
      );
      expect(find.text('Almost There'), findsOneWidget);

      // 100% -> Goal Achieved
      await tester.pumpWidget(
        createTestApp(child: const GoalMilestoneBadge(progress: 1.0)),
      );
      expect(find.text('Goal Achieved'), findsOneWidget);
    });
  });

  group('GoalCard Tests', () {
    testWidgets(
      'renders all goal attributes and opens contribution modal on tap',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = FakeGoalsRepository();
        final goal = FinancialGoal(
          id: 'goal-card-1',
          name: 'Europe Holiday',
          description: 'Summer 2026 trip to Europe',
          targetAmountInCents: 500000,
          savedAmountInCents: 250000,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          targetDate: DateTime(2026, 8, 1),
          iconName: 'flight',
        );
        await repo.addGoal(goal);

        await tester.pumpWidget(
          createTestApp(
            repository: repo,
            child: GoalCard(goal: goal),
          ),
        );

        expect(find.text('Europe Holiday'), findsOneWidget);
        expect(find.text('Summer 2026 trip to Europe'), findsOneWidget);
        expect(find.text('50.0%'), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('Add Money'), findsOneWidget);

        // Tap Add Money to open ContributionModal
        await tester.tap(find.text('Add Money'));
        await tester.pumpAndSettle();

        expect(find.text('Add Contribution'), findsOneWidget);
      },
    );
  });

  group('ContributionModal Tests', () {
    testWidgets('calculates live preview and submits contribution', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeGoalsRepository();
      final goal = FinancialGoal(
        id: 'contrib-1',
        name: 'New Bike',
        targetAmountInCents: 100000,
        savedAmountInCents: 40000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addGoal(goal);

      await tester.pumpWidget(
        createTestApp(
          repository: repo,
          child: Builder(
            builder:
                (ctx) => ElevatedButton(
                  onPressed: () => ContributionModal.show(ctx, goal),
                  child: const Text('Open Modal'),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Add Contribution'), findsOneWidget);

      // Tap quick preset "+50" chip
      expect(find.text('+50'), findsOneWidget);
      await tester.tap(find.text('+50'));
      await tester.pumpAndSettle();

      // Submit contribution
      final confirmBtn = find.widgetWithText(
        ElevatedButton,
        'Add Contribution',
      );
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Modal closed and repository updated
      expect(find.byType(ContributionModal), findsNothing);
      expect(repo.goals['contrib-1']?.savedAmountInCents, 45000);
    });
  });

  group('GoalEmptyState Tests', () {
    testWidgets('renders empty state illustration and triggers callback', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        createTestApp(
          child: GoalEmptyState(onAddGoalPressed: () => called = true),
        ),
      );

      expect(find.text('No Savings Goals Yet'), findsOneWidget);
      expect(find.text('Create Your First Goal'), findsOneWidget);

      await tester.tap(find.text('Create Your First Goal'));
      expect(called, isTrue);
    });
  });

  group('GoalForm Tests', () {
    testWidgets('validates required fields and creates new goal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeGoalsRepository();

      await tester.pumpWidget(
        createTestApp(
          repository: repo,
          child: Builder(
            builder:
                (ctx) => ElevatedButton(
                  onPressed: () => GoalForm.showAddGoal(ctx),
                  child: const Text('Open Form'),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      expect(find.text('New Savings Goal'), findsOneWidget);

      // Scroll and Tap Create without filling -> validation error
      final createBtn = find.widgetWithText(FilledButton, 'Create Goal');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a goal name'), findsOneWidget);

      // Enter Goal Name and Target Amount
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal Name *'),
        'MacBook Pro',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '2500.00');
      await tester.pumpAndSettle();

      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Ensure form closed and goal saved in repo
      expect(find.text('New Savings Goal'), findsNothing);
      expect(repo.goals.length, 1);
      expect(repo.goals.values.first.name, 'MacBook Pro');
      expect(repo.goals.values.first.targetAmountInCents, 250000);
    });

    testWidgets('edits existing goal properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeGoalsRepository();
      final goal = FinancialGoal(
        id: 'edit-me-1',
        name: 'Old House Fund',
        targetAmountInCents: 5000000,
        savedAmountInCents: 1000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addGoal(goal);

      await tester.pumpWidget(
        createTestApp(
          repository: repo,
          child: Builder(
            builder:
                (ctx) => ElevatedButton(
                  onPressed: () => GoalForm.showEditGoal(ctx, goal),
                  child: const Text('Edit Goal'),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Savings Goal'), findsOneWidget);
      expect(find.text('Old House Fund'), findsOneWidget);

      // Modify goal name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal Name *'),
        'New Dream Home',
      );
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Savings Goal'), findsNothing);
      expect(repo.goals['edit-me-1']?.name, 'New Dream Home');
    });
  });
}
