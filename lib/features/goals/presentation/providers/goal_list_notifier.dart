import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/goals_local_data_source.dart';
import '../../data/models/financial_goal.dart';
import '../../data/repositories/goals_repository_impl.dart';
import '../../domain/repositories/goals_repository.dart';

enum GoalListStatus { initial, loading, loaded, error }

class GoalListState {
  final GoalListStatus status;
  final List<FinancialGoal> goals;
  final String? errorMessage;
  final String? userId;

  const GoalListState({
    this.status = GoalListStatus.initial,
    this.goals = const [],
    this.errorMessage,
    this.userId,
  });

  bool get isLoading => status == GoalListStatus.loading;
  bool get hasError => status == GoalListStatus.error;
  bool get isLoaded => status == GoalListStatus.loaded;
  bool get isInitial => status == GoalListStatus.initial;

  GoalListState copyWith({
    GoalListStatus? status,
    List<FinancialGoal>? goals,
    String? errorMessage,
    bool clearError = false,
    String? userId,
    bool clearUserId = false,
  }) {
    return GoalListState(
      status: status ?? this.status,
      goals: goals != null ? List.unmodifiable(goals) : this.goals,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalListState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          userId == other.userId &&
          _listEquals(goals, other.goals);

  static bool _listEquals(List<FinancialGoal> a, List<FinancialGoal> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      status.hashCode ^
      goals.hashCode ^
      errorMessage.hashCode ^
      userId.hashCode;
}

class GoalListNotifier extends StateNotifier<GoalListState> {
  final GoalsRepository repository;

  GoalListNotifier({required this.repository, String? userId})
    : super(GoalListState(userId: userId)) {
    loadGoals();
  }

  void setUserId(String? userId) {
    if (state.userId != userId) {
      state = state.copyWith(userId: userId);
      loadGoals();
    }
  }

  Future<void> loadGoals() async {
    state = state.copyWith(status: GoalListStatus.loading, clearError: true);
    try {
      final List<FinancialGoal> fetchedGoals;
      if (state.userId != null && state.userId!.isNotEmpty) {
        fetchedGoals = await repository.getGoalsForUser(state.userId!);
      } else {
        fetchedGoals = await repository.getAllGoals();
      }
      state = state.copyWith(
        status: GoalListStatus.loaded,
        goals: fetchedGoals,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: GoalListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addGoal(FinancialGoal goal) async {
    try {
      await repository.addGoal(goal);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(
        status: GoalListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    try {
      await repository.updateGoal(goal);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(
        status: GoalListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await repository.deleteGoal(id);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(
        status: GoalListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> addContribution(String goalId, int amountInCents) async {
    try {
      final goal = await repository.getGoal(goalId);
      if (goal == null) {
        throw StateError('Goal with ID $goalId not found');
      }
      final updatedGoal = goal.addContribution(amountInCents);
      await repository.updateGoal(updatedGoal);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(
        status: GoalListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> removeContribution(String goalId, int amountInCents) async {
    try {
      final goal = await repository.getGoal(goalId);
      if (goal == null) {
        throw StateError('Goal with ID $goalId not found');
      }
      final updatedGoal = goal.removeContribution(amountInCents);
      await repository.updateGoal(updatedGoal);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(
        status: GoalListStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadGoals();
  }
}

// Global Providers
final goalsLocalDataSourceProvider = Provider<GoalsLocalDataSource>((ref) {
  return HiveGoalsLocalDataSource();
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final localDataSource = ref.watch(goalsLocalDataSourceProvider);
  return GoalsRepositoryImpl(localDataSource: localDataSource);
});

final goalListNotifierProvider =
    StateNotifierProvider<GoalListNotifier, GoalListState>((ref) {
      final repository = ref.watch(goalsRepositoryProvider);
      return GoalListNotifier(repository: repository);
    });
