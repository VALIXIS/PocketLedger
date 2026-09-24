import '../../data/models/financial_goal.dart';

abstract class GoalsRepository {
  Future<void> addGoal(FinancialGoal goal);
  Future<void> updateGoal(FinancialGoal goal);
  Future<FinancialGoal?> getGoal(String id);
  Future<List<FinancialGoal>> getAllGoals();
  Future<List<FinancialGoal>> getGoalsForUser(String userId);
  Future<void> deleteGoal(String id);
  Future<bool> containsGoal(String id);
}
