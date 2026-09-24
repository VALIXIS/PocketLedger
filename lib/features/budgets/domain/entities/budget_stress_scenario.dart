/// Deterministic stress testing scenario levels and percentage mappings.
enum BudgetStressScenario {
  /// Baseline spending (0% increase)
  baseline,

  /// Mild spending pressure (+10% increase)
  mild,

  /// Moderate spending pressure (+20% increase)
  moderate,

  /// Severe spending pressure (+35% increase)
  severe,

  /// Extreme spending pressure (+50% increase)
  extreme,
}

extension BudgetStressScenarioX on BudgetStressScenario {
  /// Returns explicit stress percentage value.
  int get stressPercent {
    switch (this) {
      case BudgetStressScenario.baseline:
        return 0;
      case BudgetStressScenario.mild:
        return 10;
      case BudgetStressScenario.moderate:
        return 20;
      case BudgetStressScenario.severe:
        return 35;
      case BudgetStressScenario.extreme:
        return 50;
    }
  }

  /// Human-readable label for UI selection controls.
  String get label {
    switch (this) {
      case BudgetStressScenario.baseline:
        return 'Baseline (0%)';
      case BudgetStressScenario.mild:
        return 'Mild (+10%)';
      case BudgetStressScenario.moderate:
        return 'Moderate (+20%)';
      case BudgetStressScenario.severe:
        return 'Severe (+35%)';
      case BudgetStressScenario.extreme:
        return 'Extreme (+50%)';
    }
  }

  /// Short display title.
  String get displayName {
    switch (this) {
      case BudgetStressScenario.baseline:
        return 'Baseline';
      case BudgetStressScenario.mild:
        return 'Mild';
      case BudgetStressScenario.moderate:
        return 'Moderate';
      case BudgetStressScenario.severe:
        return 'Severe';
      case BudgetStressScenario.extreme:
        return 'Extreme';
    }
  }
}
