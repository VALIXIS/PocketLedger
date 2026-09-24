import '../entities/budget.dart';
import '../entities/budget_alert.dart';

/// Pure, deterministic service for evaluating multi-threshold budget alerts.
class BudgetAlertEngine {
  const BudgetAlertEngine();

  /// Evaluates a single [budget] against [spentInCents] to calculate its alert state.
  ///
  /// Throws [ArgumentError] if [spentInCents] is negative.
  BudgetAlert evaluateBudget({
    required Budget budget,
    required int spentInCents,
    DateTime? timestamp,
  }) {
    if (spentInCents < 0) {
      throw ArgumentError('Spent amount cannot be negative');
    }

    final budgetCents = budget.amountInCents;
    final remainingCents = budgetCents - spentInCents;

    BudgetAlertLevel level;
    double percentage;

    if (budgetCents == 0) {
      if (spentInCents > 0) {
        level = BudgetAlertLevel.exceeded;
        percentage = 100.0;
      } else {
        level = BudgetAlertLevel.none;
        percentage = 0.0;
      }
    } else {
      percentage = (spentInCents / budgetCents) * 100.0;

      // Integer cents precision comparison using exact integer arithmetic
      if (spentInCents * 100 >= budgetCents * 100) {
        level = BudgetAlertLevel.exceeded;
      } else if (spentInCents * 100 >= budgetCents * 90) {
        level = BudgetAlertLevel.danger;
      } else if (spentInCents * 100 >= budgetCents * 75) {
        level = BudgetAlertLevel.warning;
      } else {
        level = BudgetAlertLevel.none;
      }
    }

    final spentFormatted = (spentInCents / 100.0).toStringAsFixed(2);
    final allocatedFormatted = (budgetCents / 100.0).toStringAsFixed(2);
    final percentFormatted = percentage.toStringAsFixed(1);

    String message;
    switch (level) {
      case BudgetAlertLevel.exceeded:
        message =
            '${budget.name} budget exceeded! Spent \$$spentFormatted of \$$allocatedFormatted ($percentFormatted%)';
        break;
      case BudgetAlertLevel.danger:
        message =
            '${budget.name} budget critical! Spent \$$spentFormatted of \$$allocatedFormatted ($percentFormatted%)';
        break;
      case BudgetAlertLevel.warning:
        message =
            '${budget.name} budget warning! Spent \$$spentFormatted of \$$allocatedFormatted ($percentFormatted%)';
        break;
      case BudgetAlertLevel.none:
        message = '${budget.name} budget is within normal limits';
        break;
    }

    return BudgetAlert(
      budgetId: budget.id,
      budgetName: budget.name,
      categoryId: budget.categoryId,
      level: level,
      spentInCents: spentInCents,
      amountInCents: budgetCents,
      remainingInCents: remainingCents,
      percentageSpent: percentage,
      message: message,
      timestamp: timestamp,
    );
  }

  /// Evaluates multiple [budgets] with their corresponding spent amounts in [spentMap]
  /// and returns only active alerts (warning, danger, exceeded) sorted by priority.
  List<BudgetAlert> evaluateActiveAlerts(
    List<Budget> budgets,
    Map<String, int> spentMap, {
    DateTime? timestamp,
  }) {
    final List<BudgetAlert> activeAlerts = [];

    for (final budget in budgets) {
      final spent = spentMap[budget.id] ?? 0;
      final alert = evaluateBudget(
        budget: budget,
        spentInCents: spent,
        timestamp: timestamp,
      );

      if (alert.isActive) {
        activeAlerts.add(alert);
      }
    }

    // Sort by priority: Exceeded > Danger > Warning, then highest percentage spent
    activeAlerts.sort((a, b) {
      final levelCompare = b.level.index.compareTo(a.level.index);
      if (levelCompare != 0) return levelCompare;
      return b.percentageSpent.compareTo(a.percentageSpent);
    });

    return activeAlerts;
  }
}
