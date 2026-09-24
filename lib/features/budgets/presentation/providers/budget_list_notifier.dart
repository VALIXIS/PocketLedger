import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/budget_local_data_source.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
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
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
        state = AsyncValue.data(newList);
      } else {
        state = AsyncValue.data([...currentList, budget]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await repository.updateBudget(budget);
      final currentList = state.value ?? [];
      final newList = currentList.map((b) => b.id == budget.id ? budget : b).toList();
      state = AsyncValue.data(newList);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await repository.deleteBudget(id);
      final currentList = state.value ?? [];
      final newList = currentList.where((b) => b.id != id).toList();
      state = AsyncValue.data(newList);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
