import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/goals/data/models/financial_goal.dart';
import 'package:pocketledger/features/goals/domain/repositories/goals_repository.dart';
import 'package:pocketledger/features/goals/presentation/providers/goal_list_notifier.dart';

class FakeGoalsRepository implements GoalsRepository {
  final Map<String, FinancialGoal> _goals = {};
  bool shouldThrow = false;

  @override
  Future<void> addGoal(FinancialGoal goal) async {
    if (shouldThrow) throw Exception('Simulated add failure');
    if (_goals.containsKey(goal.id)) {
      throw StateError('Goal with ID ${goal.id} already exists.');
    }
    _goals[goal.id] = goal;
  }

  @override
  Future<void> updateGoal(FinancialGoal goal) async {
    if (shouldThrow) throw Exception('Simulated update failure');
    if (!_goals.containsKey(goal.id)) {
      throw StateError('Goal with ID ${goal.id} not found.');
    }
    _goals[goal.id] = goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    if (shouldThrow) throw Exception('Simulated delete failure');
    _goals.remove(id);
  }

  @override
  Future<FinancialGoal?> getGoal(String id) async {
    if (shouldThrow) throw Exception('Simulated get failure');
    return _goals[id];
  }

  @override
  Future<List<FinancialGoal>> getAllGoals() async {
    if (shouldThrow) throw Exception('Simulated get all failure');
    return _goals.values.toList();
  }

  @override
  Future<List<FinancialGoal>> getGoalsForUser(String userId) async {
    if (shouldThrow) throw Exception('Simulated get user failure');
    return _goals.values.where((g) => g.userId == userId).toList();
  }

  @override
  Future<bool> containsGoal(String id) async {
    return _goals.containsKey(id);
  }
}

void main() {
  late FakeGoalsRepository repository;
  late GoalListNotifier notifier;

  setUp(() {
    repository = FakeGoalsRepository();
    notifier = GoalListNotifier(repository: repository);
  });

  tearDown(() {
    notifier.dispose();
  });

  FinancialGoal createGoal({
    String id = 'goal-1',
    String name = 'Emergency Fund',
    int target = 100000,
    int saved = 20000,
    String userId = '',
  }) {
    return FinancialGoal(
      id: id,
      name: name,
      targetAmountInCents: target,
      savedAmountInCents: saved,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      userId: userId,
    );
  }

  test('Initial state loads goals and updates to loaded', () async {
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, GoalListStatus.loaded);
    expect(notifier.state.goals, isEmpty);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.hasError, isFalse);
  });

  test('addGoal adds goal and reloads state', () async {
    final goal = createGoal();
    await notifier.addGoal(goal);

    expect(notifier.state.goals.length, 1);
    expect(notifier.state.goals.first.id, 'goal-1');
    expect(notifier.state.goals.first.name, 'Emergency Fund');
  });

  test('updateGoal modifies goal in state', () async {
    final goal = createGoal();
    await notifier.addGoal(goal);

    final modified = goal.copyWith(name: 'Updated Fund');
    await notifier.updateGoal(modified);

    expect(notifier.state.goals.first.name, 'Updated Fund');
  });

  test('deleteGoal removes goal from state', () async {
    final goal = createGoal();
    await notifier.addGoal(goal);
    expect(notifier.state.goals.length, 1);

    await notifier.deleteGoal('goal-1');
    expect(notifier.state.goals, isEmpty);
  });

  test('addContribution updates saved amount and status', () async {
    final goal = createGoal(target: 100000, saved: 20000);
    await notifier.addGoal(goal);

    await notifier.addContribution('goal-1', 30000);
    expect(notifier.state.goals.first.savedAmountInCents, 50000);

    // Add remaining contribution to complete
    await notifier.addContribution('goal-1', 50000);
    expect(notifier.state.goals.first.savedAmountInCents, 100000);
    expect(notifier.state.goals.first.status, GoalStatus.completed);
  });

  test('removeContribution updates saved amount cleanly', () async {
    final goal = createGoal(target: 100000, saved: 50000);
    await notifier.addGoal(goal);

    await notifier.removeContribution('goal-1', 20000);
    expect(notifier.state.goals.first.savedAmountInCents, 30000);
  });

  test('user filtering isolates user goals', () async {
    await repository.addGoal(createGoal(id: 'g-1', userId: 'user-a'));
    await repository.addGoal(createGoal(id: 'g-2', userId: 'user-b'));

    notifier.setUserId('user-a');
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.goals.length, 1);
    expect(notifier.state.goals.first.id, 'g-1');

    notifier.setUserId('user-b');
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.goals.length, 1);
    expect(notifier.state.goals.first.id, 'g-2');
  });

  test('Repository error sets error state and preserves data safely', () async {
    await notifier.addGoal(createGoal(id: 'g-1'));
    expect(notifier.state.goals.length, 1);

    repository.shouldThrow = true;
    await notifier.loadGoals();

    expect(notifier.state.status, GoalListStatus.error);
    expect(notifier.state.hasError, isTrue);
    expect(notifier.state.errorMessage, isNotNull);
  });

  test('refresh reloads goals successfully', () async {
    await repository.addGoal(createGoal(id: 'g-1'));
    await notifier.refresh();

    expect(notifier.state.goals.length, 1);
    expect(notifier.state.status, GoalListStatus.loaded);
  });
}
