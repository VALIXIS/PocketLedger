import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:pocketledger/features/goals/data/models/financial_goal.dart';

void main() {
  late Directory tempDir;
  late HiveGoalsLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('goals_ds_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(GoalStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(FinancialGoalAdapter());
    }

    dataSource = HiveGoalsLocalDataSource();
    await dataSource.init();
  });

  tearDown(() async {
    await dataSource.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  FinancialGoal createSampleGoal1() => FinancialGoal(
    id: 'goal-1',
    name: 'Emergency Fund',
    targetAmountInCents: 500000,
    savedAmountInCents: 100000,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userId: 'user-a',
  );

  FinancialGoal createSampleGoal2() => FinancialGoal(
    id: 'goal-2',
    name: 'New Car',
    targetAmountInCents: 1500000,
    savedAmountInCents: 250000,
    createdAt: DateTime(2026, 1, 2),
    updatedAt: DateTime(2026, 1, 2),
    userId: 'user-b',
  );

  test('saveGoal, getGoal, and containsGoal work properly', () async {
    expect(await dataSource.containsGoal('goal-1'), isFalse);
    expect(await dataSource.getGoal('goal-1'), isNull);

    final goal1 = createSampleGoal1();
    await dataSource.saveGoal(goal1);

    expect(await dataSource.containsGoal('goal-1'), isTrue);
    final fetched = await dataSource.getGoal('goal-1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'goal-1');
    expect(fetched.name, 'Emergency Fund');
    expect(fetched.targetAmountInCents, 500000);
  });

  test('getAllGoals and getGoalsForUser return expected records', () async {
    await dataSource.saveGoal(createSampleGoal1());
    await dataSource.saveGoal(createSampleGoal2());

    final all = await dataSource.getAllGoals();
    expect(all.length, 2);

    final userAGoals = await dataSource.getGoalsForUser('user-a');
    expect(userAGoals.length, 1);
    expect(userAGoals.first.id, 'goal-1');

    final userBGoals = await dataSource.getGoalsForUser('user-b');
    expect(userBGoals.length, 1);
    expect(userBGoals.first.id, 'goal-2');

    final userCGoals = await dataSource.getGoalsForUser('user-c');
    expect(userCGoals, isEmpty);
  });

  test('updateGoal modifies existing goal in box', () async {
    final goal1 = createSampleGoal1();
    await dataSource.saveGoal(goal1);

    final updated = goal1.copyWith(
      name: 'Updated Emergency Fund',
      savedAmountInCents: 200000,
    );
    await dataSource.updateGoal(updated);

    final fetched = await dataSource.getGoal('goal-1');
    expect(fetched!.name, 'Updated Emergency Fund');
    expect(fetched.savedAmountInCents, 200000);
  });

  test('deleteGoal removes goal from box', () async {
    await dataSource.saveGoal(createSampleGoal1());
    expect(await dataSource.containsGoal('goal-1'), isTrue);

    await dataSource.deleteGoal('goal-1');
    expect(await dataSource.containsGoal('goal-1'), isFalse);
    expect(await dataSource.getGoal('goal-1'), isNull);
  });

  test('clear empties the box', () async {
    await dataSource.saveGoal(createSampleGoal1());
    await dataSource.saveGoal(createSampleGoal2());
    expect((await dataSource.getAllGoals()).length, 2);

    await dataSource.clear();
    expect(await dataSource.getAllGoals(), isEmpty);
  });
}
