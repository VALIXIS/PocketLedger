/// Confidence level indicating degree of historical support for a budget recommendation.
enum RecommendationConfidence {
  /// 0 or 1 historical period
  low,

  /// 2 or 3 historical periods
  medium,

  /// 4 or more historical periods
  high,
}

extension RecommendationConfidenceX on RecommendationConfidence {
  String get label {
    switch (this) {
      case RecommendationConfidence.low:
        return 'Low Confidence';
      case RecommendationConfidence.medium:
        return 'Medium Confidence';
      case RecommendationConfidence.high:
        return 'High Confidence';
    }
  }
}

/// Immutable domain entity containing auto-recalibration budget recommendations.
class BudgetRecalibrationRecommendation {
  /// Current saved budget cap in integer cents
  final int currentBudgetInCents;

  /// Historical average spending across recorded periods in integer cents
  final int historicalAverageInCents;

  /// Peak historical spending in integer cents
  final int historicalMaximumInCents;

  /// Current active period spending in integer cents
  final int currentPeriodSpendingInCents;

  /// Applied stress buffer percentage (e.g. 20)
  final int stressBufferPercent;

  /// Proposed recommended budget cap in integer cents
  final int recommendedBudgetInCents;

  /// Variance between recommended and current budget (recommended - current)
  final int differenceInCents;

  /// Transparent justification explaining recommendation formula
  final String reason;

  /// Confidence rating based on historical period volume
  final RecommendationConfidence confidence;

  const BudgetRecalibrationRecommendation({
    required this.currentBudgetInCents,
    required this.historicalAverageInCents,
    required this.historicalMaximumInCents,
    required this.currentPeriodSpendingInCents,
    required this.stressBufferPercent,
    required this.recommendedBudgetInCents,
    required this.differenceInCents,
    required this.reason,
    required this.confidence,
  });

  /// Helper to convert currentBudgetInCents to double dollars
  double get currentBudget => currentBudgetInCents / 100.0;

  /// Helper to convert recommendedBudgetInCents to double dollars
  double get recommendedBudget => recommendedBudgetInCents / 100.0;

  /// Helper to convert differenceInCents to double dollars
  double get difference => differenceInCents / 100.0;

  /// Returns true if recommended budget differs from current saved budget
  bool get hasChange => differenceInCents != 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetRecalibrationRecommendation &&
          runtimeType == other.runtimeType &&
          currentBudgetInCents == other.currentBudgetInCents &&
          historicalAverageInCents == other.historicalAverageInCents &&
          historicalMaximumInCents == other.historicalMaximumInCents &&
          currentPeriodSpendingInCents == other.currentPeriodSpendingInCents &&
          stressBufferPercent == other.stressBufferPercent &&
          recommendedBudgetInCents == other.recommendedBudgetInCents &&
          differenceInCents == other.differenceInCents &&
          reason == other.reason &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      currentBudgetInCents.hashCode ^
      historicalAverageInCents.hashCode ^
      historicalMaximumInCents.hashCode ^
      currentPeriodSpendingInCents.hashCode ^
      stressBufferPercent.hashCode ^
      recommendedBudgetInCents.hashCode ^
      differenceInCents.hashCode ^
      reason.hashCode ^
      confidence.hashCode;
}
