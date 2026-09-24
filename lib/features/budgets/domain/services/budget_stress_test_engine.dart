import '../entities/budget_stress_scenario.dart';
import '../entities/budget_stress_test.dart';

/// Pure, deterministic service for executing budget stress testing scenarios.
class BudgetStressTestEngine {
  const BudgetStressTestEngine();

  /// Runs a stress scenario evaluation against budget [allocationInCents] and [currentSpendingInCents].
  BudgetStressTest run({
    required int allocationInCents,
    required int currentSpendingInCents,
    required BudgetStressScenario scenario,
  }) {
    // Normalize negative spending safely
    final normalizedSpending = currentSpendingInCents < 0
        ? 0
        : currentSpendingInCents;
    final stressPercent = scenario.stressPercent;

    // Integer cents arithmetic for stressed spending calculation
    final stressIncrement = (normalizedSpending * stressPercent) ~/ 100;
    final stressedSpendingInCents = normalizedSpending + stressIncrement;

    // Zero allocation edge cases
    if (allocationInCents <= 0) {
      final exceeds = normalizedSpending > 0 || stressedSpendingInCents > 0;
      return BudgetStressTest(
        allocationInCents: 0,
        currentSpendingInCents: normalizedSpending,
        stressPercent: stressPercent,
        scenario: scenario,
        stressedSpendingInCents: stressedSpendingInCents,
        remainingInCents: 0,
        exceedsBudget: exceeds,
        utilizationPercent: exceeds ? 100.0 : 0.0,
        status: exceeds
            ? BudgetStressStatus.exceeded
            : BudgetStressStatus.withinBudget,
      );
    }

    final rawRemaining = allocationInCents - stressedSpendingInCents;
    final exceedsBudget =
        rawRemaining < 0 || stressedSpendingInCents >= allocationInCents;
    final remainingInCents = rawRemaining < 0 ? 0 : rawRemaining;
    final utilizationPercent =
        (stressedSpendingInCents / allocationInCents) * 100.0;

    BudgetStressStatus status;
    if (exceedsBudget || utilizationPercent >= 100.0) {
      status = BudgetStressStatus.exceeded;
    } else if (utilizationPercent >= 75.0) {
      status = BudgetStressStatus.nearLimit;
    } else {
      status = BudgetStressStatus.withinBudget;
    }

    return BudgetStressTest(
      allocationInCents: allocationInCents,
      currentSpendingInCents: normalizedSpending,
      stressPercent: stressPercent,
      scenario: scenario,
      stressedSpendingInCents: stressedSpendingInCents,
      remainingInCents: remainingInCents,
      exceedsBudget: exceedsBudget,
      utilizationPercent: utilizationPercent,
      status: status,
    );
  }
}
