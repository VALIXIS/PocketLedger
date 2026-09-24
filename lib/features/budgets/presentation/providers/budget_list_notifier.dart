import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/datasources/budget_local_data_source.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_alert.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/services/budget_alert_engine.dart';
import '../../domain/services/budget_notification_service.dart';
import '../services/budget_pacing_engine.dart';

final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) {
  return HiveBudgetLocalDataSource();
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final localDataSource = ref.watch(budgetLocalDataSourceProvider);
  return BudgetRepositoryImpl(localDataSource: localDataSource);
});

final budgetPacingEngineProvider = Provider<BudgetPacingEngine>((ref) {
  return const BudgetPacingEngine();
});

final budgetAlertEngineProvider = Provider<BudgetAlertEngine>((ref) {
  return const BudgetAlertEngine();
});

final budgetNotificationServiceProvider = Provider<BudgetNotificationService>((ref) {
  return BudgetNotificationService();
});

/// Derived Riverpod provider for evaluating active budget alerts and triggering notification hooks.
final activeBudgetAlertsProvider = Provider<List<BudgetAlert>>((ref) {
  final budgetState = ref.watch(budgetListNotifierProvider);
  final transactionState = ref.watch(transactionListProvider);
  final alertEngine = ref.watch(budgetAlertEngineProvider);
  final notificationService = ref.watch(budgetNotificationServiceProvider);

  if (budgetState.hasError || transactionState.hasError) {
    return const [];
  }

  final budgets = budgetState.value ?? [];
  final transactions = transactionState.value ?? [];

  if (budgets.isEmpty) {
    return const [];
  }

  final now = DateTime.now();
  final Map<String, int> spentMap = {};
  for (final budget in budgets) {
    final range = BudgetPacingEngine.getActivePeriodRange(budget, now);
    int total = 0;
    for (final tx in transactions) {
      if (tx.type.name == 'expense') {
        if (budget.categoryId.isNotEmpty && tx.category != budget.categoryId) {
          continue;
        }
        if (tx.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(range.end)) {
          total += tx.amountInCents;
        }
      }
    }
    spentMap[budget.id] = total;
  }

  final alerts = alertEngine.evaluateActiveAlerts(budgets, spentMap, timestamp: now);

  // Trigger notification hooks for state transition deduplication
  notificationService.processAlerts(alerts);

  return alerts;
});

class BudgetListNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final BudgetRepository repository;
  final BudgetPacingEngine pacingEngine;

  BudgetListNotifier({
    required this.repository,
    this.pacingEngine = const BudgetPacingEngine(),
  }) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = const AsyncValue.loading();
    try {
      final list = await repository.getBudgets();
      if (mounted) {
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> refreshBudgets() async {
    await loadBudgets();
  }

  Future<void> addBudget(Budget budget) async {
    try {
      await repository.saveBudget(budget);
      final currentList = state.value ?? [];
      final index = currentList.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        final newList = List<Budget>.from(currentList);
        newList[index] = budget;
        if (mounted) {
          state = AsyncValue.data(newList);
        }
      } else {
        if (mounted) {
          state = AsyncValue.data([...currentList, budget]);
        }
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await repository.updateBudget(budget);
      final currentList = state.value ?? [];
      final newList = currentList.map((b) => b.id == budget.id ? budget : b).toList();
      if (mounted) {
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await repository.deleteBudget(id);
      final currentList = state.value ?? [];
      final newList = currentList.where((b) => b.id != id).toList();
      if (mounted) {
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  BudgetPacingResult calculatePacing({
    required Budget budget,
    required int spentInCents,
    DateTime? currentTime,
  }) {
    return pacingEngine.calculatePacing(
      budget: budget,
      spentInCents: spentInCents,
      currentTime: currentTime,
    );
  }
}

final budgetListNotifierProvider =
    StateNotifierProvider<BudgetListNotifier, AsyncValue<List<Budget>>>((ref) {
      final repository = ref.watch(budgetRepositoryProvider);
      final pacingEngine = ref.watch(budgetPacingEngineProvider);
      return BudgetListNotifier(
        repository: repository,
        pacingEngine: pacingEngine,
      );
    });
