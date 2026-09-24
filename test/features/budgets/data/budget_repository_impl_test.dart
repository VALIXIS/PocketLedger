import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:pocketledger/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';

void main() {
  late Directory tempDir;
  late Box<Budget> box;
  late HiveBudgetLocalDataSource dataSource;
  late BudgetRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_repo_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(BudgetAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BudgetPeriodAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<Budget>(
      'budgets_repo_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    dataSource = HiveBudgetLocalDataSource(box: box);
    repository = BudgetRepositoryImpl(localDataSource: dataSource);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BudgetRepositoryImpl Unit Tests', () {
    test('1. Repository delegates fetching correctly', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Food',
        amountInCents: 30000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await repository.saveBudget(b1);

      final budgets = await repository.getBudgets();
      expect(budgets.length, equals(1));
      expect(budgets.first.id, equals('b1'));

      final fetched = await repository.getBudgetById('b1');
      expect(fetched?.name, equals('Food'));
    });

    test('2. Repository delegates creation correctly', () async {
      final b1 = Budget(
        id: 'b2',
        name: 'Travel',
        amountInCents: 50000,
        period: BudgetPeriod.yearly,
        startDate: DateTime(2026, 1, 1),
      );

      await repository.saveBudget(b1);
      final result = await repository.getBudgetById('b2');

      expect(result, isNotNull);
      expect(result?.name, equals('Travel'));
    });

    test('3. Repository delegates updates correctly', () async {
      final b1 = Budget(
        id: 'b3',
        name: 'Utilities',
        amountInCents: 15000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await repository.saveBudget(b1);
      final updated = b1.copyWith(
        name: 'Bills & Utilities',
        amountInCents: 18000,
      );
      await repository.updateBudget(updated);

      final result = await repository.getBudgetById('b3');
      expect(result?.name, equals('Bills & Utilities'));
      expect(result?.amountInCents, equals(18000));
    });

    test('4. Repository delegates deletion correctly', () async {
      final b1 = Budget(
        id: 'b4',
        name: 'Subscriptions',
        amountInCents: 5000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await repository.saveBudget(b1);
      await repository.deleteBudget('b4');

      final result = await repository.getBudgetById('b4');
      expect(result, isNull);
    });

    test('5. Repository correctly performs rollover behavior', () async {
      final original = Budget(
        id: 'b_rollover',
        name: 'Groceries',
        amountInCents: 10000, // 100.00
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        rolloverEnabled: true,
      );

      await repository.saveBudget(original);

      final nextBudget = await repository.rolloverBudget(
        budget: original,
        spentAmountInCents: 7500, // Unused = 2500
        newBudgetId: 'b_rollover_next',
      );

      expect(nextBudget.id, equals('b_rollover_next'));
      expect(nextBudget.amountInCents, equals(12500)); // 10000 + 2500
      expect(nextBudget.startDate, equals(DateTime(2026, 2, 1)));

      final storedNext = await repository.getBudgetById('b_rollover_next');
      expect(storedNext, isNotNull);
      expect(storedNext?.amountInCents, equals(12500));

      // Ensure historical budget record was NOT mutated
      final storedOriginal = await repository.getBudgetById('b_rollover');
      expect(storedOriginal?.amountInCents, equals(10000));
    });
  });
}
