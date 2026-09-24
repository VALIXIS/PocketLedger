import 'dart:math';
import '../entities/budget_recalibration_recommendation.dart';

/// Pure, deterministic engine calculating AI-assisted budget cap recalibration recommendations.
class BudgetRecalibrationEngine {
  const BudgetRecalibrationEngine();

  /// Step size for rounding recommendations upward (50,000 cents = ₹500)
  static const int stepInCents = 50000;

  /// Calculates a recommended budget cap based on historical spending, current period spending, and stress buffer.
  ///
  /// Safe against zero, negative, or missing historical data. DOES NOT mutate the saved budget.
  BudgetRecalibrationRecommendation recommend({
    required int currentBudgetInCents,
    required List<int> historicalSpendingInCents,
    required int currentPeriodSpendingInCents,
    int stressBufferPercent = 20,
  }) {
    // Normalize negative values safely
    final currentBudget = currentBudgetInCents < 0 ? 0 : currentBudgetInCents;
    final currentPeriodSpent = currentPeriodSpendingInCents < 0
        ? 0
        : currentPeriodSpendingInCents;
    final bufferPercent = stressBufferPercent < 0 ? 0 : stressBufferPercent;

    final cleanedHistory = historicalSpendingInCents
        .map((s) => s < 0 ? 0 : s)
        .toList();

    // Edge case: No history AND zero current spending -> retain current budget
    if (cleanedHistory.isEmpty && currentPeriodSpent == 0) {
      final formattedCap = (currentBudget / 100.0).toStringAsFixed(2);
      return BudgetRecalibrationRecommendation(
        currentBudgetInCents: currentBudget,
        historicalAverageInCents: 0,
        historicalMaximumInCents: 0,
        currentPeriodSpendingInCents: 0,
        stressBufferPercent: bufferPercent,
        recommendedBudgetInCents: currentBudget,
        differenceInCents: 0,
        reason:
            'No spending history recorded. Retaining current budget cap of \$$formattedCap.',
        confidence: RecommendationConfidence.low,
      );
    }

    int historicalAverage = 0;
    int historicalMaximum = 0;
    RecommendationConfidence confidence;

    if (cleanedHistory.isEmpty) {
      historicalAverage = 0;
      historicalMaximum = 0;
      confidence = RecommendationConfidence.low;
    } else {
      final totalSum = cleanedHistory.reduce((a, b) => a + b);
      historicalAverage = (totalSum / cleanedHistory.length).round();
      historicalMaximum = cleanedHistory.reduce(max);

      if (cleanedHistory.length == 1) {
        confidence = RecommendationConfidence.low;
      } else if (cleanedHistory.length <= 3) {
        confidence = RecommendationConfidence.medium;
      } else {
        confidence = RecommendationConfidence.high;
      }
    }

    // Determine baseline from highest signal
    int baseline = max(historicalAverage, currentPeriodSpent);
    if (baseline == 0 && currentBudget > 0) {
      baseline = currentBudget;
    }

    // Calculate raw recommendation with stress buffer
    final rawRecommended = baseline + ((baseline * bufferPercent) ~/ 100);

    // Round upward to nearest ₹500 (50,000 cents)
    int recommendedBudget = 0;
    if (rawRecommended > 0) {
      recommendedBudget =
          ((rawRecommended + stepInCents - 1) ~/ stepInCents) * stepInCents;
    } else if (currentBudget > 0) {
      recommendedBudget = currentBudget;
    }

    final differenceInCents = recommendedBudget - currentBudget;

    final formattedAvg = (historicalAverage / 100.0).toStringAsFixed(2);
    final formattedSpent = (currentPeriodSpent / 100.0).toStringAsFixed(2);
    final formattedRec = (recommendedBudget / 100.0).toStringAsFixed(2);

    String reason;
    if (cleanedHistory.isEmpty) {
      reason =
          'Based on current period spending (\$$formattedSpent) with a +$bufferPercent% stress buffer, rounded up to \$$formattedRec.';
    } else {
      reason =
          'Based on historical average (\$$formattedAvg), current spending (\$$formattedSpent), and +$bufferPercent% stress buffer, rounded up to \$$formattedRec.';
    }

    return BudgetRecalibrationRecommendation(
      currentBudgetInCents: currentBudget,
      historicalAverageInCents: historicalAverage,
      historicalMaximumInCents: historicalMaximum,
      currentPeriodSpendingInCents: currentPeriodSpent,
      stressBufferPercent: bufferPercent,
      recommendedBudgetInCents: recommendedBudget,
      differenceInCents: differenceInCents,
      reason: reason,
      confidence: confidence,
    );
  }
}
