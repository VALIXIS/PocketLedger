import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/recurring_local_data_source.dart';
import '../../data/models/recurring_transaction.dart';
import '../../data/repositories/recurring_repository_impl.dart';
import '../../domain/repositories/recurring_repository.dart';

enum RecurringListStatus { initial, loading, loaded, error }

class RecurringListState {
  final RecurringListStatus status;
  final List<RecurringTransaction> transactions;
  final String? errorMessage;
  final String? userId;

  const RecurringListState({
    this.status = RecurringListStatus.initial,
    this.transactions = const [],
    this.errorMessage,
    this.userId,
  });

  bool get isLoading => status == RecurringListStatus.loading;
  bool get hasError => status == RecurringListStatus.error;
  bool get isLoaded => status == RecurringListStatus.loaded;
  bool get isInitial => status == RecurringListStatus.initial;

  RecurringListState copyWith({
    RecurringListStatus? status,
    List<RecurringTransaction>? transactions,
    String? errorMessage,
    bool clearError = false,
    String? userId,
    bool clearUserId = false,
  }) {
    return RecurringListState(
      status: status ?? this.status,
      transactions: transactions != null
          ? List.unmodifiable(transactions)
          : this.transactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringListState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          userId == other.userId &&
          _listEquals(transactions, other.transactions);

  static bool _listEquals(
    List<RecurringTransaction> a,
    List<RecurringTransaction> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      status.hashCode ^
      transactions.hashCode ^
      errorMessage.hashCode ^
      userId.hashCode;
}

class RecurringListNotifier extends StateNotifier<RecurringListState> {
  final RecurringRepository repository;

  RecurringListNotifier({required this.repository, String? userId})
    : super(RecurringListState(userId: userId)) {
    loadRecurringTransactions();
  }

  void setUserId(String? userId) {
    if (state.userId != userId) {
      state = state.copyWith(userId: userId);
      loadRecurringTransactions();
    }
  }

  Future<void> loadRecurringTransactions() async {
    state = state.copyWith(
      status: RecurringListStatus.loading,
      clearError: true,
    );
    try {
      final List<RecurringTransaction> fetched;
      if (state.userId != null && state.userId!.isNotEmpty) {
        fetched = await repository.getRecurringTransactionsForUser(
          state.userId!,
        );
      } else {
        fetched = await repository.getAllRecurringTransactions();
      }
      state = state.copyWith(
        status: RecurringListStatus.loaded,
        transactions: fetched,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    try {
      await repository.addRecurringTransaction(transaction);
      await loadRecurringTransactions();
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    try {
      await repository.updateRecurringTransaction(transaction);
      await loadRecurringTransactions();
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await repository.deleteRecurringTransaction(id);
      await loadRecurringTransactions();
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> pauseRecurringTransaction(String id) async {
    try {
      final current = await repository.getRecurringTransaction(id);
      if (current == null) {
        throw StateError('Recurring transaction with ID $id not found');
      }
      final updated = current.copyWith(
        status: RecurringTransactionStatus.paused,
        updatedAt: DateTime.now(),
      );
      await repository.updateRecurringTransaction(updated);
      await loadRecurringTransactions();
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> resumeRecurringTransaction(String id) async {
    try {
      final current = await repository.getRecurringTransaction(id);
      if (current == null) {
        throw StateError('Recurring transaction with ID $id not found');
      }
      final updated = current.copyWith(
        status: RecurringTransactionStatus.active,
        updatedAt: DateTime.now(),
      );
      await repository.updateRecurringTransaction(updated);
      await loadRecurringTransactions();
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> cancelRecurringTransaction(String id) async {
    try {
      final current = await repository.getRecurringTransaction(id);
      if (current == null) {
        throw StateError('Recurring transaction with ID $id not found');
      }
      final updated = current.copyWith(
        status: RecurringTransactionStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      await repository.updateRecurringTransaction(updated);
      await loadRecurringTransactions();
    } catch (e) {
      state = state.copyWith(
        status: RecurringListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadRecurringTransactions();
  }
}

// Global Providers
final recurringLocalDataSourceProvider = Provider<RecurringLocalDataSource>((
  ref,
) {
  return HiveRecurringLocalDataSource();
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final localDataSource = ref.watch(recurringLocalDataSourceProvider);
  return RecurringRepositoryImpl(localDataSource: localDataSource);
});

final recurringListNotifierProvider =
    StateNotifierProvider<RecurringListNotifier, RecurringListState>((ref) {
      final repository = ref.watch(recurringRepositoryProvider);
      return RecurringListNotifier(repository: repository);
    });
