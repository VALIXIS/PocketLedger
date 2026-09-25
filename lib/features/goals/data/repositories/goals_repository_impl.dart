import '../../domain/repositories/goals_repository.dart';
import '../datasources/goals_local_data_source.dart';
import '../models/financial_goal.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final GoalsLocalDataSource localDataSource;

  GoalsRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addGoal(FinancialGoal goal) async {
    final exists = await localDataSource.containsGoal(goal.id);
    if (exists) {
      throw StateError('Goal with ID ${goal.id} already exists.');
    }
    await localDataSource.saveGoal(goal);
  }

  @override
  Future<void> updateGoal(FinancialGoal goal) async {
    final exists = await localDataSource.containsGoal(goal.id);
    if (!exists) {
      throw StateError('Goal with ID ${goal.id} does not exist.');
    }
    await localDataSource.updateGoal(goal);
  }

  @override
  Future<FinancialGoal?> getGoal(String id) {
    return localDataSource.getGoal(id);
  }

  @override
  Future<List<FinancialGoal>> getAllGoals() {
    return localDataSource.getAllGoals();
  }

  @override
  Future<List<FinancialGoal>> getGoalsForUser(String userId) {
    return localDataSource.getGoalsForUser(userId);
  }

  @override
  Future<void> deleteGoal(String id) {
    return localDataSource.deleteGoal(id);
  }

  @override
  Future<bool> containsGoal(String id) {
    return localDataSource.containsGoal(id);
  }
}
