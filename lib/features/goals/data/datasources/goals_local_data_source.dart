import 'package:hive/hive.dart';
import '../models/financial_goal.dart';

abstract class GoalsLocalDataSource {
  Future<void> init();
  Future<void> saveGoal(FinancialGoal goal);
  Future<void> updateGoal(FinancialGoal goal);
  Future<FinancialGoal?> getGoal(String id);
  Future<List<FinancialGoal>> getAllGoals();
  Future<List<FinancialGoal>> getGoalsForUser(String userId);
  Future<void> deleteGoal(String id);
  Future<bool> containsGoal(String id);
  Future<void> clear();
  Future<void> close();
}

class HiveGoalsLocalDataSource implements GoalsLocalDataSource {
  static const String boxName = 'goals_box';

  Box<FinancialGoal>? _box;

  HiveGoalsLocalDataSource({Box<FinancialGoal>? box}) {
    _box = box;
  }

  Future<Box<FinancialGoal>> _openBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<FinancialGoal>(boxName);
      return _box!;
    }
    _box = await Hive.openBox<FinancialGoal>(boxName);
    return _box!;
  }

  @override
  Future<void> init() async {
    await _openBox();
  }

  @override
  Future<void> saveGoal(FinancialGoal goal) async {
    final box = await _openBox();
    await box.put(goal.id, goal);
  }

  @override
  Future<void> updateGoal(FinancialGoal goal) async {
    final box = await _openBox();
    await box.put(goal.id, goal);
  }

  @override
  Future<FinancialGoal?> getGoal(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  @override
  Future<List<FinancialGoal>> getAllGoals() async {
    final box = await _openBox();
    return box.values.toList();
  }

  @override
  Future<List<FinancialGoal>> getGoalsForUser(String userId) async {
    final box = await _openBox();
    return box.values.where((goal) => goal.userId == userId).toList();
  }

  @override
  Future<void> deleteGoal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  @override
  Future<bool> containsGoal(String id) async {
    final box = await _openBox();
    return box.containsKey(id);
  }

  @override
  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }

  @override
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    } else if (Hive.isBoxOpen(boxName)) {
      await Hive.box<FinancialGoal>(boxName).close();
    }
  }
}
