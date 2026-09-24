import '../../data/models/recurring_transaction.dart';

abstract class RecurringRepository {
  Future<void> addRecurringTransaction(RecurringTransaction transaction);
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
}
