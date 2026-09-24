import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:pocketledger/features/goals/data/models/financial_goal.dart';
import 'package:pocketledger/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:pocketledger/features/goals/domain/repositories/goals_repository.dart';

void main() {
  late Directory tempDir;
  late GoalsLocalDataSource dataSource;
  late GoalsRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('goals_repo_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(GoalStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(FinancialGoalAdapter());
    }

    dataSource = HiveGoalsLocalDataSource();
    await dataSource.init();
    repository = GoalsRepositoryImpl(localDataSource: dataSource);
  });

  tearDown(() async {
    await dataSource.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  FinancialGoal createSampleGoal() => FinancialGoal(
        id: 'goal-100',
        name: 'Home Renovation',
        description: 'Kitchen and living room remodel',
        targetAmountInCents: 2000000,
        savedAmountInCents: 500000,
        targetDate: DateTime(2027, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        userId: 'user-vip',
      );

  test('addGoal stores a new goal successfully', () async {
    final sampleGoal = createSampleGoal();
    await repository.addGoal(sampleGoal);

    expect(await repository.containsGoal('goal-100'), isTrue);
    final fetched = await repository.getGoal('goal-100');
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Home Renovation');
    expect(fetched.targetAmountInCents, 2000000);
  });

  test('addGoal throws StateError when duplicate ID is added', () async {
    final sampleGoal = createSampleGoal();
    await repository.addGoal(sampleGoal);

    final duplicateGoal = createSampleGoal();
    expect(
      () => repository.addGoal(duplicateGoal),
      throwsStateError,
    );
  });

  test('updateGoal modifies existing goal successfully', () async {
    final sampleGoal = createSampleGoal();
    await repository.addGoal(sampleGoal);

    final modified = sampleGoal.copyWith(
      savedAmountInCents: 750000,
      name: 'Luxury Home Renovation',
    );
    await repository.updateGoal(modified);

    final fetched = await repository.getGoal('goal-100');
    expect(fetched!.savedAmountInCents, 750000);
    expect(fetched.name, 'Luxury Home Renovation');
  });

  test('updateGoal throws StateError when goal does not exist', () async {
    final sampleGoal = createSampleGoal();
    expect(
      () => repository.updateGoal(sampleGoal),
      throwsStateError,
    );
  });

  test('getAllGoals and getGoalsForUser return filtered results', () async {
    final goalUser1 = createSampleGoal();
    final goalUser2 = FinancialGoal(
      id: 'goal-200',
      name: 'Europe Trip',
      targetAmountInCents: 300000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      userId: 'user-standard',
    );

    await repository.addGoal(goalUser1);
    await repository.addGoal(goalUser2);

    final allGoals = await repository.getAllGoals();
    expect(allGoals.length, 2);

    final vipGoals = await repository.getGoalsForUser('user-vip');
    expect(vipGoals.length, 1);
    expect(vipGoals.first.id, 'goal-100');

    final standardGoals = await repository.getGoalsForUser('user-standard');
    expect(standardGoals.length, 1);
    expect(standardGoals.first.id, 'goal-200');
  });

  test('deleteGoal removes goal safely', () async {
    final sampleGoal = createSampleGoal();
    await repository.addGoal(sampleGoal);
    expect(await repository.containsGoal('goal-100'), isTrue);

    await repository.deleteGoal('goal-100');
    expect(await repository.containsGoal('goal-100'), isFalse);
    expect(await repository.getGoal('goal-100'), isNull);
  });
}
