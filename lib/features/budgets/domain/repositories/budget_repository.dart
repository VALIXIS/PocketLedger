import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets();
  Future<Budget?> getBudgetById(String id);
  Future<void> saveBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<void> clearBudgets();

  /// Calculates unused rollover amount in integer cents.
  int calculateRolloverAmount(Budget budget, int spentAmountInCents);

  /// Carries over unused budget into the next period and returns the newly created Budget.
  Future<Budget> rolloverBudget({
    required Budget budget,
    required int spentAmountInCents,
    String? newBudgetId,
    DateTime? newStartDate,
  });
}
