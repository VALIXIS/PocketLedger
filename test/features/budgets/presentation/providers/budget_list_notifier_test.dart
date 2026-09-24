import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/repositories/budget_repository.dart';
import 'package:pocketledger/features/budgets/presentation/providers/budget_list_notifier.dart';
import 'package:pocketledger/features/budgets/presentation/services/budget_pacing_engine.dart';

class MockBudgetRepository implements BudgetRepository {
  final Map<String, Budget> storage = {};
  bool shouldThrow = false;

  @override
  Future<List<Budget>> getBudgets() async {
    if (shouldThrow) throw Exception('Database error');
    return storage.values.toList();
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    if (shouldThrow) throw Exception('Database error');
    return storage[id];
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    if (shouldThrow) throw Exception('Database error');
    storage[budget.id] = budget;
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    if (shouldThrow) throw Exception('Database error');
    storage[budget.id] = budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    if (shouldThrow) throw Exception('Database error');
    storage.remove(id);
  }

  @override
  Future<void> clearBudgets() async {
    if (shouldThrow) throw Exception('Database error');
    storage.clear();
  }

  @override
  int calculateRolloverAmount(Budget budget, int spentAmountInCents) {
    if (!budget.rolloverEnabled) return 0;
    final unused = budget.amountInCents - spentAmountInCents;
    return unused > 0 ? unused : 0;
  }

  @override
  Future<Budget> rolloverBudget({
    required Budget budget,
    required int spentAmountInCents,
    String? newBudgetId,
    DateTime? newStartDate,
  }) async {
    final rollover = calculateRolloverAmount(budget, spentAmountInCents);
    final nextId = newBudgetId ?? '${budget.id}_next';
    final nextBudget = budget.copyWith(
      id: nextId,
      amountInCents: budget.amountInCents + rollover,
    );
    await saveBudget(nextBudget);
    return nextBudget;
  }
}

void main() {
  late MockBudgetRepository mockRepository;
  late BudgetListNotifier notifier;

  setUp(() {
    mockRepository = MockBudgetRepository();
    notifier = BudgetListNotifier(repository: mockRepository);
  });

  group('BudgetListNotifier Unit Tests', () {
    test('1. Initial state loads budgets', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Groceries',
        amountInCents: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      await mockRepository.saveBudget(b1);

      await notifier.loadBudgets();

      expect(notifier.state, isA<AsyncData<List<Budget>>>());
      expect(notifier.state.value?.length, equals(1));
      expect(notifier.state.value?.first.name, equals('Groceries'));
    });

    test('2. Successful budget loading', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Food',
        amountInCents: 20000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      await mockRepository.saveBudget(b1);

      await notifier.loadBudgets();
      expect(notifier.state.value, contains(b1));
    });

    test('3. Empty budget list', () async {
      await notifier.loadBudgets();
      expect(notifier.state.value, isEmpty);
    });

    test('4. Repository failure puts notifier in AsyncError state', () async {
      mockRepository.shouldThrow = true;
      await notifier.loadBudgets();

      expect(notifier.state, isA<AsyncError<List<Budget>>>());
    });

    test('5. Adding a budget updates state', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Utilities',
        amountInCents: 15000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await notifier.addBudget(b1);
      expect(notifier.state.value?.length, equals(1));
      expect(notifier.state.value?.first.id, equals('b1'));
    });

    test('6. Updating a budget updates existing state item', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Utilities',
        amountInCents: 15000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await notifier.addBudget(b1);
      final updated = b1.copyWith(name: 'Updated Utilities', amountInCents: 18000);

      await notifier.updateBudget(updated);
      expect(notifier.state.value?.first.name, equals('Updated Utilities'));
      expect(notifier.state.value?.first.amountInCents, equals(18000));
    });

    test('7. Deleting a budget removes item from state', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Utilities',
        amountInCents: 15000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      await notifier.addBudget(b1);
      await notifier.deleteBudget('b1');

      expect(notifier.state.value, isEmpty);
    });

    test('8. Refreshing budgets reloads data from repository', () async {
      await notifier.refreshBudgets();
      expect(notifier.state.value, isEmpty);

      final b1 = Budget(
        id: 'b1',
        name: 'Rent',
        amountInCents: 100000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );
      await mockRepository.saveBudget(b1);

      await notifier.refreshBudgets();
      expect(notifier.state.value?.length, equals(1));
    });

    test('9. Error state behavior when save fails', () async {
      final b1 = Budget(
        id: 'b1',
        name: 'Error item',
        amountInCents: 1000,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2026, 1, 1),
      );

      mockRepository.shouldThrow = true;
      await notifier.addBudget(b1);

      expect(notifier.state, isA<AsyncError<List<Budget>>>());
    });

    test('10. Pacing calculation integration works via notifier', () {
      final b1 = Budget(
        id: 'b1',
        name: 'Shopping',
        amountInCents: 10000,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      final pacing = notifier.calculatePacing(
        budget: b1,
        spentInCents: 6000,
        currentTime: DateTime(2026, 1, 13, 9, 36),
      );

      expect(pacing.isProjectedToExceed, isTrue);
      expect(pacing.status, equals(BudgetPacingStatus.projectedToExceed));
    });
  });
}
