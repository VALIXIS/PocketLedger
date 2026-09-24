import 'budget_stress_scenario.dart';

/// Status classification for stress test outcomes.
enum BudgetStressStatus {
  /// Utilization < 75%
  withinBudget,

  /// 75% <= Utilization < 100%
  nearLimit,

  /// Utilization >= 100% or spent exceeds budget
  exceeded,
}

/// Immutable domain model representing the evaluated result of a budget stress test.
class BudgetStressTest {
  /// Allocated budget in integer cents
  final int allocationInCents;

  /// Current actual spending in integer cents
  final int currentSpendingInCents;

  /// Applied stress percentage (e.g. 0, 10, 20, 35, 50)
  final int stressPercent;

  /// Stress scenario applied
  final BudgetStressScenario scenario;

  /// Stressed total spending in integer cents
  final int stressedSpendingInCents;

  /// Remaining amount in integer cents after stress (0 if exceeded)
  final int remainingInCents;

  /// True if stressed spending exceeds allocated budget
  final bool exceedsBudget;

  /// Projected utilization percentage (e.g. 85.5)
  final double utilizationPercent;

  /// Stress status derived from utilization
  final BudgetStressStatus status;

  const BudgetStressTest({
    required this.allocationInCents,
    required this.currentSpendingInCents,
    required this.stressPercent,
    required this.scenario,
    required this.stressedSpendingInCents,
    required this.remainingInCents,
    required this.exceedsBudget,
    required this.utilizationPercent,
    required this.status,
  });

  /// Helper to convert allocationInCents to double dollars
  double get allocation => allocationInCents / 100.0;

  /// Helper to convert currentSpendingInCents to double dollars
  double get currentSpending => currentSpendingInCents / 100.0;

  /// Helper to convert stressedSpendingInCents to double dollars
  double get stressedSpending => stressedSpendingInCents / 100.0;

  /// Helper to convert remainingInCents to double dollars
  double get remaining => remainingInCents / 100.0;

  BudgetStressTest copyWith({
    int? allocationInCents,
    int? currentSpendingInCents,
    int? stressPercent,
    BudgetStressScenario? scenario,
    int? stressedSpendingInCents,
    int? remainingInCents,
    bool? exceedsBudget,
    double? utilizationPercent,
    BudgetStressStatus? status,
  }) {
    return BudgetStressTest(
      allocationInCents: allocationInCents ?? this.allocationInCents,
      currentSpendingInCents:
          currentSpendingInCents ?? this.currentSpendingInCents,
      stressPercent: stressPercent ?? this.stressPercent,
      scenario: scenario ?? this.scenario,
      stressedSpendingInCents:
          stressedSpendingInCents ?? this.stressedSpendingInCents,
      remainingInCents: remainingInCents ?? this.remainingInCents,
      exceedsBudget: exceedsBudget ?? this.exceedsBudget,
      utilizationPercent: utilizationPercent ?? this.utilizationPercent,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetStressTest &&
          runtimeType == other.runtimeType &&
          allocationInCents == other.allocationInCents &&
          currentSpendingInCents == other.currentSpendingInCents &&
          stressPercent == other.stressPercent &&
          scenario == other.scenario &&
          stressedSpendingInCents == other.stressedSpendingInCents &&
          remainingInCents == other.remainingInCents &&
          exceedsBudget == other.exceedsBudget &&
          utilizationPercent == other.utilizationPercent &&
          status == other.status;

  @override
  int get hashCode =>
      allocationInCents.hashCode ^
      currentSpendingInCents.hashCode ^
      stressPercent.hashCode ^
      scenario.hashCode ^
      stressedSpendingInCents.hashCode ^
      remainingInCents.hashCode ^
      exceedsBudget.hashCode ^
      utilizationPercent.hashCode ^
      status.hashCode;
}
