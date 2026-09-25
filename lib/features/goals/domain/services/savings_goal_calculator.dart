/// Projection result for a savings goal.
class SavingsGoalProjection {
  final int targetAmountInCents;

  final int currentSavedAmountInCents;

  final int remainingAmountInCents;

  final int monthlyContributionInCents;

  final int monthsRequired;

  final DateTime projectedCompletionDate;

  final double progressPercentage;

  const SavingsGoalProjection({
    required this.targetAmountInCents,
    required this.currentSavedAmountInCents,
    required this.remainingAmountInCents,
    required this.monthlyContributionInCents,
    required this.monthsRequired,
    required this.projectedCompletionDate,
    required this.progressPercentage,
  });

  bool get isAlreadyCompleted => remainingAmountInCents <= 0;

  bool get isAchievable => monthlyContributionInCents > 0 || isAlreadyCompleted;
}

/// Calculator for savings-goal contribution planning.
class SavingsGoalCalculator {
  const SavingsGoalCalculator();

  /// Calculates how many months are required to reach
  /// a savings goal.
  ///
  /// Example:
  ///
  /// Target = ₹1,00,000
  /// Saved = ₹20,000
  /// Monthly contribution = ₹10,000
  ///
  /// Remaining = ₹80,000
  /// Required = 8 months
  SavingsGoalProjection calculate({
    required int targetAmountInCents,
    required int currentSavedAmountInCents,
    required int monthlyContributionInCents,
    DateTime? startDate,
  }) {
    if (targetAmountInCents < 0) {
      throw ArgumentError('targetAmountInCents cannot be negative.');
    }

    if (currentSavedAmountInCents < 0) {
      throw ArgumentError('currentSavedAmountInCents cannot be negative.');
    }

    if (monthlyContributionInCents < 0) {
      throw ArgumentError('monthlyContributionInCents cannot be negative.');
    }

    final remaining = targetAmountInCents - currentSavedAmountInCents;

    if (remaining <= 0) {
      return SavingsGoalProjection(
        targetAmountInCents: targetAmountInCents,
        currentSavedAmountInCents: currentSavedAmountInCents,
        remainingAmountInCents: 0,
        monthlyContributionInCents: monthlyContributionInCents,
        monthsRequired: 0,
        projectedCompletionDate: startDate ?? DateTime.now(),
        progressPercentage: 100,
      );
    }

    if (monthlyContributionInCents <= 0) {
      return SavingsGoalProjection(
        targetAmountInCents: targetAmountInCents,
        currentSavedAmountInCents: currentSavedAmountInCents,
        remainingAmountInCents: remaining,
        monthlyContributionInCents: monthlyContributionInCents,
        monthsRequired: 0,
        projectedCompletionDate: startDate ?? DateTime.now(),
        progressPercentage: _calculateProgress(
          currentSavedAmountInCents,
          targetAmountInCents,
        ),
      );
    }

    final monthsRequired =
        (remaining + monthlyContributionInCents - 1) ~/
        monthlyContributionInCents;

    final baseDate = startDate ?? DateTime.now();

    final projectedDate = _addMonths(baseDate, monthsRequired);

    return SavingsGoalProjection(
      targetAmountInCents: targetAmountInCents,
      currentSavedAmountInCents: currentSavedAmountInCents,
      remainingAmountInCents: remaining,
      monthlyContributionInCents: monthlyContributionInCents,
      monthsRequired: monthsRequired,
      projectedCompletionDate: projectedDate,
      progressPercentage: _calculateProgress(
        currentSavedAmountInCents,
        targetAmountInCents,
      ),
    );
  }

  /// Calculates the monthly amount required to reach a
  /// goal within a specified number of months.
  int requiredMonthlyContribution({
    required int targetAmountInCents,
    required int currentSavedAmountInCents,
    required int months,
  }) {
    if (months <= 0) {
      throw ArgumentError('months must be greater than zero.');
    }

    final remaining = targetAmountInCents - currentSavedAmountInCents;

    if (remaining <= 0) {
      return 0;
    }

    return (remaining + months - 1) ~/ months;
  }

  double _calculateProgress(int saved, int target) {
    if (target <= 0) {
      return 100;
    }

    final progress = saved / target * 100;

    if (progress < 0) {
      return 0;
    }

    if (progress > 100) {
      return 100;
    }

    return progress;
  }

  DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 + months;

    final year = totalMonths ~/ 12;

    final month = totalMonths % 12 + 1;

    final lastDay = DateTime(year, month + 1, 0).day;

    final day = date.day > lastDay ? lastDay : date.day;

    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
