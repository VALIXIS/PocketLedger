import '../entities/budget_recalibration_recommendation.dart';
import 'budget_recalibration_engine.dart';

/// Abstract domain interface for AI-assisted budget recommendation advisors.
abstract interface class BudgetRecommendationAdvisor {
  Future<BudgetRecalibrationRecommendation> recommend({
    required int currentBudgetInCents,
    required List<int> historicalSpendingInCents,
    required int currentPeriodSpendingInCents,
    int stressBufferPercent = 20,
  });
}

/// Fallback deterministic implementation of [BudgetRecommendationAdvisor].
class DeterministicBudgetRecommendationAdvisor
    implements BudgetRecommendationAdvisor {
  final BudgetRecalibrationEngine engine;

  const DeterministicBudgetRecommendationAdvisor({
    this.engine = const BudgetRecalibrationEngine(),
  });

  @override
  Future<BudgetRecalibrationRecommendation> recommend({
    required int currentBudgetInCents,
    required List<int> historicalSpendingInCents,
    required int currentPeriodSpendingInCents,
    int stressBufferPercent = 20,
  }) async {
    return engine.recommend(
      currentBudgetInCents: currentBudgetInCents,
      historicalSpendingInCents: historicalSpendingInCents,
      currentPeriodSpendingInCents: currentPeriodSpendingInCents,
      stressBufferPercent: stressBufferPercent,
    );
  }
}
