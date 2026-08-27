import 'package:hive/hive.dart';
import '../../domain/models/transaction.dart';

abstract class TransactionLocalDataSource {
  Future<List<Transaction>> getTransactions();
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
}

class HiveTransactionLocalDataSource implements TransactionLocalDataSource {
  static const String boxName = 'transactions_box';

  Future<Box<Transaction>> _openBox() async {
    return await Hive.openBox<Transaction>(boxName);
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    final box = await _openBox();
    return box.values.toList();
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final box = await _openBox();
    await box.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
