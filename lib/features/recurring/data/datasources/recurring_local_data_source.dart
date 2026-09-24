import 'package:hive/hive.dart';
import '../models/recurring_transaction.dart';

abstract class RecurringLocalDataSource {
  Future<void> init();
  Future<void> saveRecurringTransaction(RecurringTransaction transaction);
  Future<void> updateRecurringTransaction(RecurringTransaction transaction);
  Future<RecurringTransaction?> getRecurringTransaction(String id);
  Future<List<RecurringTransaction>> getAllRecurringTransactions();
  Future<List<RecurringTransaction>> getRecurringTransactionsForUser(
    String userId,
  );
  Future<List<RecurringTransaction>> getActiveRecurringTransactions();
  Future<List<RecurringTransaction>> getDueTransactions([DateTime? asOf]);
  Future<void> deleteRecurringTransaction(String id);
  Future<bool> containsRecurringTransaction(String id);
  Future<void> clear();
  Future<void> close();
}

class HiveRecurringLocalDataSource implements RecurringLocalDataSource {
  static const String boxName = 'recurring_box';

  Box<RecurringTransaction>? _box;

  HiveRecurringLocalDataSource({Box<RecurringTransaction>? box}) {
    _box = box;
  }

  Future<Box<RecurringTransaction>> _openBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<RecurringTransaction>(boxName);
      return _box!;
    }
    _box = await Hive.openBox<RecurringTransaction>(boxName);
    return _box!;
  }

  @override
  Future<void> init() async {
    await _openBox();
  }

  @override
  Future<void> saveRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final box = await _openBox();
    await box.put(transaction.id, transaction);
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final box = await _openBox();
    await box.put(transaction.id, transaction);
  }

  @override
  Future<RecurringTransaction?> getRecurringTransaction(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  @override
  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    final box = await _openBox();
    return box.values.toList();
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsForUser(
    String userId,
  ) async {
    final box = await _openBox();
    return box.values.where((tx) => tx.userId == userId).toList();
  }

  @override
  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    final box = await _openBox();
    return box.values.where((tx) => tx.isActive).toList();
  }

  @override
  Future<List<RecurringTransaction>> getDueTransactions([
    DateTime? asOf,
  ]) async {
    final box = await _openBox();
    final target = asOf ?? DateTime.now();
    final normalizedTarget = DateTime(target.year, target.month, target.day);

    return box.values.where((tx) {
      if (!tx.isActive) return false;
      if (tx.hasEnded) return false;

      final normalizedNext = DateTime(
        tx.nextOccurrence.year,
        tx.nextOccurrence.month,
        tx.nextOccurrence.day,
      );
      return !normalizedNext.isAfter(normalizedTarget);
    }).toList();
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  @override
  Future<bool> containsRecurringTransaction(String id) async {
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
      await Hive.box<RecurringTransaction>(boxName).close();
    }
  }
}
