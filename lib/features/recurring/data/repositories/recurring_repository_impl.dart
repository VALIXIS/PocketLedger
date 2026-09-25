import '../../domain/repositories/recurring_repository.dart';
import '../datasources/recurring_local_data_source.dart';
import '../models/recurring_transaction.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringLocalDataSource localDataSource;

  RecurringRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    final exists = await localDataSource.containsRecurringTransaction(
      transaction.id,
    );
    if (exists) {
      throw StateError(
        'Recurring transaction with ID ${transaction.id} already exists.',
      );
    }
    await localDataSource.saveRecurringTransaction(transaction);
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final exists = await localDataSource.containsRecurringTransaction(
      transaction.id,
    );
    if (!exists) {
      throw StateError(
        'Recurring transaction with ID ${transaction.id} does not exist.',
      );
    }
    await localDataSource.updateRecurringTransaction(transaction);
  }

  @override
  Future<RecurringTransaction?> getRecurringTransaction(String id) {
    return localDataSource.getRecurringTransaction(id);
  }

  @override
  Future<List<RecurringTransaction>> getAllRecurringTransactions() {
    return localDataSource.getAllRecurringTransactions();
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsForUser(
    String userId,
  ) {
    return localDataSource.getRecurringTransactionsForUser(userId);
  }

  @override
  Future<List<RecurringTransaction>> getActiveRecurringTransactions() {
    return localDataSource.getActiveRecurringTransactions();
  }

  @override
  Future<List<RecurringTransaction>> getDueTransactions([DateTime? asOf]) {
    return localDataSource.getDueTransactions(asOf);
  }

  @override
  Future<void> deleteRecurringTransaction(String id) {
    return localDataSource.deleteRecurringTransaction(id);
  }

  @override
  Future<bool> containsRecurringTransaction(String id) {
    return localDataSource.containsRecurringTransaction(id);
  }
}
