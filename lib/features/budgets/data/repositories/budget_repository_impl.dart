import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_data_source.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Budget>> getBudgets() {
    return localDataSource.getBudgets();
  }

  @override
  Future<Budget?> getBudgetById(String id) {
    return localDataSource.getBudgetById(id);
  }

  @override
  Future<void> saveBudget(Budget budget) {
    return localDataSource.saveBudget(budget);
  }

  @override
  Future<void> updateBudget(Budget budget) {
    return localDataSource.updateBudget(budget);
  }

  @override
  Future<void> deleteBudget(String id) {
    return localDataSource.deleteBudget(id);
  }

  @override
  Future<void> clearBudgets() {
    return localDataSource.clearBudgets();
  }

  @override
  int calculateRolloverAmount(Budget budget, int spentAmountInCents) {
    if (!budget.rolloverEnabled) {
      return 0;
    }
    final unusedCents = budget.amountInCents - spentAmountInCents;
    return unusedCents > 0 ? unusedCents : 0;
  }

  @override
  Future<Budget> rolloverBudget({
    required Budget budget,
    required int spentAmountInCents,
    String? newBudgetId,
    DateTime? newStartDate,
  }) async {
    final rolloverCents = calculateRolloverAmount(budget, spentAmountInCents);
    final nextStartDate = newStartDate ?? getNextPeriodStartDate(budget.startDate, budget.period);
    final nextId = newBudgetId ?? '${budget.id}_next_${nextStartDate.millisecondsSinceEpoch}';

    final nextBudget = budget.copyWith(
      id: nextId,
      amountInCents: budget.amountInCents + rolloverCents,
      startDate: nextStartDate,
    );

    await localDataSource.saveBudget(nextBudget);
    return nextBudget;
  }

  static DateTime getNextPeriodStartDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        int year = startDate.year;
        int month = startDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        int lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        int day = startDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : startDate.day;
        return DateTime(year, month, day, startDate.hour, startDate.minute, startDate.second);
      case BudgetPeriod.yearly:
        int year = startDate.year + 1;
        int month = startDate.month;
        int lastDayOfMonth = DateTime(year, month + 1, 0).day;
        int day = startDate.day > lastDayOfMonth ? lastDayOfMonth : startDate.day;
        return DateTime(year, month, day, startDate.hour, startDate.minute, startDate.second);
    }
  }
}
