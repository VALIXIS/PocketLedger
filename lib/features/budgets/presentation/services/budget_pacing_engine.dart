import '../../domain/entities/budget.dart';

enum BudgetPacingStatus { onTrack, warning, projectedToExceed, exceeded }

class BudgetPacingResult {
  final int budgetAmountInCents;
  final int spentInCents;
  final int remainingInCents;
  final double elapsedFraction;
  final int dailySpendRateInCents;
  final int projectedSpendInCents;
  final int projectedRemainingInCents;
  final int daysRemaining;
  final bool isProjectedToExceed;
  final BudgetPacingStatus status;

  BudgetPacingResult({
    required this.budgetAmountInCents,
    required this.spentInCents,
    required this.remainingInCents,
    required this.elapsedFraction,
    required this.dailySpendRateInCents,
    required this.projectedSpendInCents,
    required this.projectedRemainingInCents,
    required this.daysRemaining,
    required this.isProjectedToExceed,
    required this.status,
  });
}

class BudgetPacingEngine {
  const BudgetPacingEngine();

  BudgetPacingResult calculatePacing({
    required Budget budget,
    required int spentInCents,
    DateTime? currentTime,
  }) {
    if (spentInCents < 0) {
      throw ArgumentError('Spent amount cannot be negative');
    }

    final now = currentTime ?? DateTime.now();
    final periodRange = getActivePeriodRange(budget, now);
    final periodStart = periodRange.start;
    final periodEnd = periodRange.end;

    final totalDurationMs =
        periodEnd.millisecondsSinceEpoch - periodStart.millisecondsSinceEpoch;
    final totalDays = (totalDurationMs / (1000 * 60 * 60 * 24)).ceil();

    // Days remaining calculation
    int daysRemaining = 0;
    if (now.isBefore(periodEnd)) {
      daysRemaining = periodEnd.difference(now).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    // Elapsed fraction calculation
    double elapsedFraction = 0.0;
    if (totalDurationMs > 0) {
      if (now.isAfter(periodEnd) || now.isAtSameMomentAs(periodEnd)) {
        elapsedFraction = 1.0;
      } else if (now.isBefore(periodStart)) {
        elapsedFraction = 0.0;
      } else {
        final elapsedMs =
            now.millisecondsSinceEpoch - periodStart.millisecondsSinceEpoch;
        elapsedFraction = elapsedMs / totalDurationMs;
        if (elapsedFraction < 0.0) elapsedFraction = 0.0;
        if (elapsedFraction > 1.0) elapsedFraction = 1.0;
      }
    }

    final budgetCents = budget.amountInCents;
    final remainingInCents = budgetCents - spentInCents;

    // Handle Zero Budget edge case
    if (budgetCents == 0) {
      final isExceeded = spentInCents > 0;
      return BudgetPacingResult(
        budgetAmountInCents: 0,
        spentInCents: spentInCents,
        remainingInCents: 0,
        elapsedFraction: elapsedFraction,
        dailySpendRateInCents: 0,
        projectedSpendInCents: spentInCents,
        projectedRemainingInCents: 0,
        daysRemaining: daysRemaining,
        isProjectedToExceed: isExceeded,
        status: isExceeded
            ? BudgetPacingStatus.exceeded
            : BudgetPacingStatus.onTrack,
      );
    }

    // Handle Completed Period or 100% Elapsed
    if (elapsedFraction >= 0.999 || !now.isBefore(periodEnd)) {
      final isExceeded = spentInCents > budgetCents;
      final dailyRate = totalDays > 0
          ? (spentInCents / totalDays).round()
          : spentInCents;

      return BudgetPacingResult(
        budgetAmountInCents: budgetCents,
        spentInCents: spentInCents,
        remainingInCents: remainingInCents,
        elapsedFraction: 1.0,
        dailySpendRateInCents: dailyRate,
        projectedSpendInCents: spentInCents,
        projectedRemainingInCents: remainingInCents,
        daysRemaining: 0,
        isProjectedToExceed: isExceeded,
        status: isExceeded
            ? BudgetPacingStatus.exceeded
            : BudgetPacingStatus.onTrack,
      );
    }

    // Handle Zero Spending
    if (spentInCents == 0) {
      return BudgetPacingResult(
        budgetAmountInCents: budgetCents,
        spentInCents: 0,
        remainingInCents: budgetCents,
        elapsedFraction: elapsedFraction,
        dailySpendRateInCents: 0,
        projectedSpendInCents: 0,
        projectedRemainingInCents: budgetCents,
        daysRemaining: daysRemaining,
        isProjectedToExceed: false,
        status: BudgetPacingStatus.onTrack,
      );
    }

    // Active period projections
    int projectedSpendInCents;
    int dailySpendRateInCents;

    if (elapsedFraction < 0.01) {
      // Early period: avoid unstable projection values
      projectedSpendInCents = spentInCents > budgetCents
          ? spentInCents
          : budgetCents;
      dailySpendRateInCents = 0;
    } else {
      projectedSpendInCents = (spentInCents / elapsedFraction).round();
      final elapsedDays = (now.difference(periodStart).inHours / 24.0);
      dailySpendRateInCents = elapsedDays > 0.05
          ? (spentInCents / elapsedDays).round()
          : (spentInCents / (totalDays * elapsedFraction)).round();
    }

    final projectedRemainingInCents = budgetCents - projectedSpendInCents;
    final isProjectedToExceed = projectedSpendInCents > budgetCents;

    BudgetPacingStatus status;
    if (spentInCents > budgetCents) {
      status = BudgetPacingStatus.exceeded;
    } else if (isProjectedToExceed) {
      status = BudgetPacingStatus.projectedToExceed;
    } else if (projectedSpendInCents > (budgetCents * 0.85).round()) {
      status = BudgetPacingStatus.warning;
    } else {
      status = BudgetPacingStatus.onTrack;
    }

    return BudgetPacingResult(
      budgetAmountInCents: budgetCents,
      spentInCents: spentInCents,
      remainingInCents: remainingInCents,
      elapsedFraction: elapsedFraction,
      dailySpendRateInCents: dailySpendRateInCents,
      projectedSpendInCents: projectedSpendInCents,
      projectedRemainingInCents: projectedRemainingInCents,
      daysRemaining: daysRemaining,
      isProjectedToExceed: isProjectedToExceed,
      status: status,
    );
  }

  static BudgetPeriodRange getActivePeriodRange(Budget budget, DateTime now) {
    final startDate = budget.startDate;
    if (now.isBefore(startDate)) {
      final end = getNextPeriodStartDate(startDate, budget.period);
      return BudgetPeriodRange(start: startDate, end: end);
    }

    switch (budget.period) {
      case BudgetPeriod.weekly:
        final daysDiff = now.difference(startDate).inDays;
        final weeksPassed = daysDiff ~/ 7;
        final periodStart = startDate.add(Duration(days: weeksPassed * 7));
        final periodEnd = periodStart.add(const Duration(days: 7));
        return BudgetPeriodRange(start: periodStart, end: periodEnd);

      case BudgetPeriod.monthly:
        DateTime pStart = startDate;
        while (true) {
          DateTime pNext = getNextPeriodStartDate(pStart, BudgetPeriod.monthly);
          if (now.isBefore(pNext)) {
            return BudgetPeriodRange(start: pStart, end: pNext);
          }
          pStart = pNext;
        }

      case BudgetPeriod.yearly:
        DateTime pStart = startDate;
        while (true) {
          DateTime pNext = getNextPeriodStartDate(pStart, BudgetPeriod.yearly);
          if (now.isBefore(pNext)) {
            return BudgetPeriodRange(start: pStart, end: pNext);
          }
          pStart = pNext;
        }
    }
  }

  static DateTime getNextPeriodStartDate(
    DateTime startDate,
    BudgetPeriod period,
  ) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        int year = startDate.year;
        int month = startDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        int lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        int day = startDate.day > lastDayOfNextMonth
            ? lastDayOfNextMonth
            : startDate.day;
        return DateTime(
          year,
          month,
          day,
          startDate.hour,
          startDate.minute,
          startDate.second,
        );
      case BudgetPeriod.yearly:
        int year = startDate.year + 1;
        int month = startDate.month;
        int lastDayOfMonth = DateTime(year, month + 1, 0).day;
        int day = startDate.day > lastDayOfMonth
            ? lastDayOfMonth
            : startDate.day;
        return DateTime(
          year,
          month,
          day,
          startDate.hour,
          startDate.minute,
          startDate.second,
        );
    }
  }
}

class BudgetPeriodRange {
  final DateTime start;
  final DateTime end;
  BudgetPeriodRange({required this.start, required this.end});
}
