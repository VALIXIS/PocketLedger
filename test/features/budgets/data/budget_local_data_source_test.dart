import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';

void main() {
  late Directory tempDir;
  late Box<Budget> box;
  late HiveBudgetLocalDataSource dataSource;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(HiveBudgetLocalDataSource.boxName);
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(BudgetAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BudgetPeriodAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<Budget>('${HiveBudgetLocalDataSource.boxName}_test_${DateTime.now().microsecondsSinceEpoch}');
    dataSource = HiveBudgetLocalDataSource(box: box);
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

  group('BudgetLocalDataSource Unit Tests', () {
    test('1. Empty Hive box returns an empty budget list', () async {
      final budgets = await dataSource.getBudgets();
      expect(budgets, isEmpty);
    });

    test('2. Adding a budget persists it', () async {
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await dataSource.saveBudget(budget);
      final stored = await dataSource.getBudgetById('b1');

      expect(stored, isNotNull);
      expect(stored?.id, equals('b1'));
      expect(stored?.name, equals('Groceries'));
    });

    test('3. Fetching budgets returns persisted budgets', () async {
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await dataSource.saveBudget(budget);
      final budgets = await dataSource.getBudgets();

      expect(budgets.length, equals(1));
      expect(budgets.first.name, equals('Groceries'));
    });

    test('4. Fetching by ID returns the correct budget', () async {
      final budget1 = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      final budget2 = Budget(
        id: 'b2',
        name: 'Tech',
        amountInCents: 100000,
        period: BudgetPeriod.yearly,
        startDate: DateTime(2026, 1, 1),
      );

      await dataSource.saveBudget(budget1);
      await dataSource.saveBudget(budget2);

      final fetched = await dataSource.getBudgetById('b2');
      expect(fetched, isNotNull);
      expect(fetched?.name, equals('Tech'));
      expect(fetched?.amountInCents, equals(100000));
    });

    test('5. Updating a budget persists the updated data', () async {
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await dataSource.saveBudget(budget);
      final updated = budget.copyWith(name: 'Updated Groceries', amountInCents: 60000);
      await dataSource.updateBudget(updated);

      final fetched = await dataSource.getBudgetById('b1');
      expect(fetched?.name, equals('Updated Groceries'));
      expect(fetched?.amountInCents, equals(60000));
    });

    test('6. Deleting a budget removes it', () async {
      final budget = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await dataSource.saveBudget(budget);
      await dataSource.deleteBudget('b1');

      final fetched = await dataSource.getBudgetById('b1');
      expect(fetched, isNull);
      expect(await dataSource.getBudgets(), isEmpty);
    });

    test('7. Multiple budgets can coexist', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      final b2 = Budget(
        id: 'b2',
        name: 'Transport',
        amountInCents: 20000,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2026, 1, 1),
      );

      await dataSource.saveBudget(b1);
      await dataSource.saveBudget(b2);

      final list = await dataSource.getBudgets();
      expect(list.length, equals(2));
      expect(list.map((b) => b.id), containsAll(['b1', 'b2']));
    });
  });
}
