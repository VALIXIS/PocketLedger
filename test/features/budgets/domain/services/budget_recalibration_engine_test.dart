import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget.dart';
import 'package:pocketledger/features/budgets/domain/entities/budget_recalibration_recommendation.dart';
import 'package:pocketledger/features/budgets/domain/services/budget_recalibration_engine.dart';

void main() {
  group('BudgetRecalibrationEngine Unit Tests', () {
    const engine = BudgetRecalibrationEngine();

    test('1. Calculates historical average correctly', () {
      final rec = engine.recommend(
        currentBudgetInCents: 1000000, // $10,000.00
        historicalSpendingInCents: [800000, 900000, 1000000], // Avg = $9,000.00
        currentPeriodSpendingInCents: 700000,
        stressBufferPercent: 20,
      );

      expect(rec.historicalAverageInCents, equals(900000));
      expect(rec.historicalMaximumInCents, equals(1000000));
      expect(
        rec.confidence,
        equals(RecommendationConfidence.medium),
      ); // 3 periods
    });

    test(
      '2. Uses current period spending as baseline when higher than historical average',
      () {
        final rec = engine.recommend(
          currentBudgetInCents: 1000000,
          historicalSpendingInCents: [500000, 600000], // Avg = $5,500.00
          currentPeriodSpendingInCents: 850000, // $8,500.00 > $5,500.00
          stressBufferPercent: 20,
        );

        // Baseline = 850,000. Raw = 850,000 + 20% = 1,020,000.
        // Rounded up to nearest $500 (50,000 cents) = 1,050,000
        expect(rec.recommendedBudgetInCents, equals(1050000));
        expect(rec.differenceInCents, equals(50000)); // +$500.00
      },
    );

    test(
      '3. Applies stress buffer (+20%) correctly using integer arithmetic',
      () {
        final rec = engine.recommend(
          currentBudgetInCents: 1000000,
          historicalSpendingInCents: [800000], // Baseline = $8,000.00
          currentPeriodSpendingInCents: 500000,
          stressBufferPercent: 20,
        );

        // Raw = 800,000 + 160,000 = 960,000 ($9,600)
        // Rounded up to nearest $500 = 1,000,000 ($10,000)
        expect(rec.recommendedBudgetInCents, equals(1000000));
      },
    );

    test('4. Rounds recommendation upward to nearest \$500 (50,000 cents)', () {
      final rec = engine.recommend(
        currentBudgetInCents: 900000,
        historicalSpendingInCents: [830000], // $8,300.00
        currentPeriodSpendingInCents: 830000,
        stressBufferPercent: 20,
      );

      // Raw = 830,000 + 166,000 = 996,000 ($9,960.00)
      // Rounded up to nearest $500 = 1,000,000 ($10,000.00)
      expect(rec.recommendedBudgetInCents, equals(1000000));
    });

    test('5. Uses current period spending when no historical data exists', () {
      final rec = engine.recommend(
        currentBudgetInCents: 500000,
        historicalSpendingInCents: [],
        currentPeriodSpendingInCents: 400000,
        stressBufferPercent: 20,
      );

      // Baseline = 400,000. Raw = 480,000. Rounded = 500,000.
      expect(rec.historicalAverageInCents, equals(0));
      expect(rec.recommendedBudgetInCents, equals(500000));
      expect(rec.confidence, equals(RecommendationConfidence.low));
    });

    test(
      '6. Retains current budget when no history and zero current spending',
      () {
        final rec = engine.recommend(
          currentBudgetInCents: 750000, // $7,500.00
          historicalSpendingInCents: [],
          currentPeriodSpendingInCents: 0,
          stressBufferPercent: 20,
        );

        expect(rec.recommendedBudgetInCents, equals(750000));
        expect(rec.differenceInCents, equals(0));
        expect(rec.hasChange, isFalse);
      },
    );

    test('7. Normalizes negative values safely', () {
      final rec = engine.recommend(
        currentBudgetInCents: -5000,
        historicalSpendingInCents: [-1000, 500000],
        currentPeriodSpendingInCents: -2000,
        stressBufferPercent: -10,
      );

      expect(rec.currentBudgetInCents, equals(0));
      expect(rec.currentPeriodSpendingInCents, equals(0));
    });

    test(
      '8. Confidence levels scale deterministically based on historical period count',
      () {
        final low1 = engine.recommend(
          currentBudgetInCents: 1000,
          historicalSpendingInCents: [],
          currentPeriodSpendingInCents: 500,
        );
        expect(low1.confidence, equals(RecommendationConfidence.low));

        final low2 = engine.recommend(
          currentBudgetInCents: 1000,
          historicalSpendingInCents: [500],
          currentPeriodSpendingInCents: 500,
        );
        expect(low2.confidence, equals(RecommendationConfidence.low));

        final med = engine.recommend(
          currentBudgetInCents: 1000,
          historicalSpendingInCents: [500, 600, 700],
          currentPeriodSpendingInCents: 500,
        );
        expect(med.confidence, equals(RecommendationConfidence.medium));

        final high = engine.recommend(
          currentBudgetInCents: 1000,
          historicalSpendingInCents: [500, 600, 700, 800],
          currentPeriodSpendingInCents: 500,
        );
        expect(high.confidence, equals(RecommendationConfidence.high));
      },
    );

    test(
      '9. Handles current budget = 0 safely for both zero and non-zero spending',
      () {
        final zeroSpendingRec = engine.recommend(
          currentBudgetInCents: 0,
          historicalSpendingInCents: [],
          currentPeriodSpendingInCents: 0,
        );
        expect(zeroSpendingRec.recommendedBudgetInCents, equals(0));

        final activeSpendingRec = engine.recommend(
          currentBudgetInCents: 0,
          historicalSpendingInCents: [400000],
          currentPeriodSpendingInCents: 400000,
        );
        // Raw = 400,000 + 80,000 = 480,000. Rounded = 500,000.
        expect(activeSpendingRec.recommendedBudgetInCents, equals(500000));
        expect(activeSpendingRec.differenceInCents, equals(500000));
      },
    );

    test(
      '10. Recommendation calculation NEVER mutates original budget entity',
      () {
        final originalBudget = Budget(
          id: 'b1',
          name: 'Dining',
          amountInCents: 500000, // $5,000.00
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 1, 1),
        );

        final rec = engine.recommend(
          currentBudgetInCents: originalBudget.amountInCents,
          historicalSpendingInCents: [800000],
          currentPeriodSpendingInCents: 800000,
        );

        // Original budget properties must remain 100% unchanged
        expect(originalBudget.amountInCents, equals(500000));
        expect(rec.recommendedBudgetInCents, equals(1000000));
        expect(
          rec.recommendedBudgetInCents,
          isNot(equals(originalBudget.amountInCents)),
        );
      },
    );
  });
}
