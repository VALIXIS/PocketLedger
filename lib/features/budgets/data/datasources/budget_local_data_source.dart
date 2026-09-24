import 'package:hive/hive.dart';
import '../../domain/entities/budget.dart';

abstract class BudgetLocalDataSource {
  Future<List<Budget>> getBudgets();
  Future<Budget?> getBudgetById(String id);
  Future<void> saveBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<void> clearBudgets();
}

class HiveBudgetLocalDataSource implements BudgetLocalDataSource {
  static const String boxName = 'budgets_box';

  final Box<Budget>? box;

  HiveBudgetLocalDataSource({this.box});

  Future<Box<Budget>> _openBox() async {
    final b = box;
    if (b != null && b.isOpen) {
      return b;
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Budget>(boxName);
    }
    return await Hive.openBox<Budget>(boxName);
  }

  @override
  Future<List<Budget>> getBudgets() async {
    final b = await _openBox();
    return b.values.toList();
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    final b = await _openBox();
    return b.get(id);
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final b = await _openBox();
    await b.put(budget.id, budget);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    final b = await _openBox();
    await b.put(budget.id, budget);
  }

  @override
  Future<void> deleteBudget(String id) async {
    final b = await _openBox();
    await b.delete(id);
  }

  @override
  Future<void> clearBudgets() async {
    final b = await _openBox();
    await b.clear();
  }
}
