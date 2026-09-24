import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>(
  (ref) {
    return HiveTransactionLocalDataSource();
  },
);

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  return TransactionRepositoryImpl(localDataSource: localDataSource);
});

class TransactionListNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository repository;

  TransactionListNotifier({required this.repository})
    : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final list = await repository.getTransactions();
      // Sort by date descending so newest are first
      list.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await repository.saveTransaction(transaction);
      final currentList = state.value ?? [];
      final newList = [...currentList, transaction];
      newList.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await repository.saveTransaction(transaction);
      final currentList = state.value ?? [];
      final newList = currentList.map((tx) {
        return tx.id == transaction.id ? transaction : tx;
      }).toList();
      newList.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await repository.deleteTransaction(id);
      final currentList = state.value ?? [];
      final newList = currentList.where((tx) => tx.id != id).toList();
      if (mounted) {
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

final transactionListProvider =
    StateNotifierProvider<
      TransactionListNotifier,
      AsyncValue<List<Transaction>>
    >((ref) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionListNotifier(repository: repository);
    });

// Centralized Stats Class for Dashboard calculations
class DashboardStats {
  final int totalIncomeInCents;
  final int totalExpensesInCents;
  final int balanceInCents;

  DashboardStats({
    required this.totalIncomeInCents,
    required this.totalExpensesInCents,
    required this.balanceInCents,
  });

  double get totalIncome => totalIncomeInCents / 100.0;
  double get totalExpenses => totalExpensesInCents / 100.0;
  double get balance => balanceInCents / 100.0;
}

// Stats Provider
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final transactionState = ref.watch(transactionListProvider);
  return transactionState.maybeWhen(
    data: (transactions) {
      int incomeCents = 0;
      int expenseCents = 0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.income) {
          incomeCents += tx.amountInCents;
        } else {
          expenseCents += tx.amountInCents;
        }
      }
      return DashboardStats(
        totalIncomeInCents: incomeCents,
        totalExpensesInCents: expenseCents,
        balanceInCents: incomeCents - expenseCents,
      );
    },
    orElse: () => DashboardStats(
      totalIncomeInCents: 0,
      totalExpensesInCents: 0,
      balanceInCents: 0,
    ),
  );
});
