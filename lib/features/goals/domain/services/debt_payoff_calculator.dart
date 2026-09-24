import '../models/debt_payoff_item.dart';

/// Supported debt payoff strategies.
enum DebtPayoffStrategy { avalanche, snowball }

/// Represents the result of one debt during the payoff simulation.
class DebtPayoffResult {
  final String debtId;
  final String debtName;

  /// Order in which this debt was completely paid off.
  final int payoffOrder;

  /// Number of months required to completely pay off this debt.
  final int monthsToPayoff;

  /// Total interest paid on this debt.
  final int totalInterestPaidInCents;

  /// Total amount paid toward this debt.
  final int totalPaidInCents;

  /// Original debt balance.
  final int originalBalanceInCents;

  const DebtPayoffResult({
    required this.debtId,
    required this.debtName,
    required this.payoffOrder,
    required this.monthsToPayoff,
    required this.totalInterestPaidInCents,
    required this.totalPaidInCents,
    required this.originalBalanceInCents,
  });
}

/// Represents the complete result of an avalanche/snowball simulation.
class DebtPayoffPlan {
  final DebtPayoffStrategy strategy;

  final List<DebtPayoffResult> debts;

  /// Number of months required to eliminate all debts.
  final int totalMonths;

  /// Total interest paid across all debts.
  final int totalInterestPaidInCents;

  /// Total amount paid across all debts.
  final int totalPaidInCents;

  /// Extra monthly amount available above minimum payments.
  final int extraMonthlyPaymentInCents;

  const DebtPayoffPlan({
    required this.strategy,
    required this.debts,
    required this.totalMonths,
    required this.totalInterestPaidInCents,
    required this.totalPaidInCents,
    required this.extraMonthlyPaymentInCents,
  });

  bool get isDebtFree => debts.isNotEmpty;

  int get debtCount => debts.length;

  DebtPayoffResult? get firstDebtPaidOff {
    if (debts.isEmpty) {
      return null;
    }

    return debts.first;
  }

  DebtPayoffResult? get finalDebtPaidOff {
    if (debts.isEmpty) {
      return null;
    }

    return debts.last;
  }
}

/// Result for a single month's simulation.
class DebtPayoffMonthSnapshot {
  final int month;

  final Map<String, int> balancesInCents;

  final int interestPaidInCents;

  final int principalPaidInCents;

  final int totalPaymentInCents;

  const DebtPayoffMonthSnapshot({
    required this.month,
    required this.balancesInCents,
    required this.interestPaidInCents,
    required this.principalPaidInCents,
    required this.totalPaymentInCents,
  });

  int get totalRemainingBalanceInCents {
    return balancesInCents.values.fold(0, (sum, balance) => sum + balance);
  }
}

/// Smart debt payoff calculator.
///
/// Supports:
///
/// - Debt Avalanche
/// - Debt Snowball
/// - Monthly interest calculation
/// - Minimum payments
/// - Extra payment allocation
/// - Debt payoff ordering
/// - Total interest
/// - Total repayment
/// - Month-by-month simulation
///
/// Financial calculations use integer cents wherever possible.
class DebtPayoffCalculator {
  const DebtPayoffCalculator();

  /// Calculates a complete debt payoff plan.
  ///
  /// [debts]
  /// List of debts to eliminate.
  ///
  /// [extraMonthlyPaymentInCents]
  /// Additional money available every month after minimum payments.
  ///
  /// [strategy]
  /// Avalanche or Snowball.
  DebtPayoffPlan calculate({
    required List<DebtPayoffItem> debts,
    required int extraMonthlyPaymentInCents,
    required DebtPayoffStrategy strategy,
  }) {
    if (extraMonthlyPaymentInCents < 0) {
      throw ArgumentError('extraMonthlyPaymentInCents cannot be negative.');
    }

    final validDebts = debts
        .where((debt) => debt.balanceInCents > 0)
        .map(
          (debt) => _SimulationDebt(
            id: debt.id,
            name: debt.name,
            originalBalanceInCents: debt.balanceInCents,
            balanceInCents: debt.balanceInCents,
            annualInterestRate: debt.annualInterestRate,
            minimumPaymentInCents: debt.minimumPaymentInCents,
          ),
        )
        .toList();

    if (validDebts.isEmpty) {
      return DebtPayoffPlan(
        strategy: strategy,
        debts: const [],
        totalMonths: 0,
        totalInterestPaidInCents: 0,
        totalPaidInCents: 0,
        extraMonthlyPaymentInCents: extraMonthlyPaymentInCents,
      );
    }

    final results = <DebtPayoffResult>[];

    var month = 0;
    var totalInterest = 0;
    var totalPaid = 0;

    while (validDebts.any((debt) => debt.balanceInCents > 0)) {
      month++;

      if (month > 1200) {
        throw StateError(
          'Debt payoff simulation exceeded 100 years. '
          'Check interest rates and payment amounts.',
        );
      }

      final activeDebts = validDebts
          .where((debt) => debt.balanceInCents > 0)
          .toList();

      // ------------------------------------------------------------
      // STEP 1 — Apply monthly interest.
      // ------------------------------------------------------------

      for (final debt in activeDebts) {
        final interest = _calculateMonthlyInterest(
          balanceInCents: debt.balanceInCents,
          annualInterestRate: debt.annualInterestRate,
        );

        debt.balanceInCents += interest;

        debt.monthlyInterestAccumulatedInCents += interest;

        totalInterest += interest;
      }

      // ------------------------------------------------------------
      // STEP 2 — Pay minimum payments.
      // ------------------------------------------------------------

      var availableExtra = extraMonthlyPaymentInCents;

      for (final debt in activeDebts) {
        if (debt.balanceInCents <= 0) {
          continue;
        }

        final minimumPayment = _safeMinimumPayment(
          balanceInCents: debt.balanceInCents,
          minimumPaymentInCents: debt.minimumPaymentInCents,
        );

        debt.balanceInCents -= minimumPayment;

        debt.totalPaidInCents += minimumPayment;

        totalPaid += minimumPayment;

        if (debt.balanceInCents <= 0) {
          debt.balanceInCents = 0;
        }
      }

      // ------------------------------------------------------------
      // STEP 3 — Determine target debt.
      // ------------------------------------------------------------

      while (availableExtra > 0) {
        final activeAfterMinimums = validDebts
            .where((debt) => debt.balanceInCents > 0)
            .toList();

        if (activeAfterMinimums.isEmpty) {
          break;
        }

        activeAfterMinimums.sort((a, b) => _compareDebts(a, b, strategy));

        final target = activeAfterMinimums.first;

        final payment = availableExtra > target.balanceInCents
            ? target.balanceInCents
            : availableExtra;

        target.balanceInCents -= payment;

        target.totalPaidInCents += payment;

        totalPaid += payment;

        availableExtra -= payment;

        if (target.balanceInCents == 0 && target.payoffMonth == null) {
          target.payoffMonth = month;
        }
      }

      // Record debts that became paid off through minimum
      // payments.
      for (final debt in validDebts) {
        if (debt.balanceInCents == 0 && debt.payoffMonth == null) {
          debt.payoffMonth = month;
        }
      }
    }

    final completedDebts = [...validDebts];

    completedDebts.sort((a, b) {
      final aMonth = a.payoffMonth ?? 0;
      final bMonth = b.payoffMonth ?? 0;

      if (aMonth != bMonth) {
        return aMonth.compareTo(bMonth);
      }

      return a.id.compareTo(b.id);
    });

    for (var index = 0; index < completedDebts.length; index++) {
      final debt = completedDebts[index];

      results.add(
        DebtPayoffResult(
          debtId: debt.id,
          debtName: debt.name,
          payoffOrder: index + 1,
          monthsToPayoff: debt.payoffMonth ?? month,
          totalInterestPaidInCents: debt.monthlyInterestAccumulatedInCents,
          totalPaidInCents: debt.totalPaidInCents,
          originalBalanceInCents: debt.originalBalanceInCents,
        ),
      );
    }

    return DebtPayoffPlan(
      strategy: strategy,
      debts: List.unmodifiable(results),
      totalMonths: month,
      totalInterestPaidInCents: totalInterest,
      totalPaidInCents: totalPaid,
      extraMonthlyPaymentInCents: extraMonthlyPaymentInCents,
    );
  }

  /// Generates month-by-month balances.
  DebtPayoffSimulation simulate({
    required List<DebtPayoffItem> debts,
    required int extraMonthlyPaymentInCents,
    required DebtPayoffStrategy strategy,
    int maxMonths = 1200,
  }) {
    if (extraMonthlyPaymentInCents < 0) {
      throw ArgumentError('extraMonthlyPaymentInCents cannot be negative.');
    }

    final simulationDebts = debts
        .where((debt) => debt.balanceInCents > 0)
        .map(
          (debt) => _SimulationDebt(
            id: debt.id,
            name: debt.name,
            originalBalanceInCents: debt.balanceInCents,
            balanceInCents: debt.balanceInCents,
            annualInterestRate: debt.annualInterestRate,
            minimumPaymentInCents: debt.minimumPaymentInCents,
          ),
        )
        .toList();

    final snapshots = <DebtPayoffMonthSnapshot>[];

    if (simulationDebts.isEmpty) {
      return const DebtPayoffSimulation(
        snapshots: [],
        totalMonths: 0,
        totalInterestPaidInCents: 0,
        totalPaidInCents: 0,
      );
    }

    var totalInterest = 0;
    var totalPaid = 0;

    for (var month = 1; month <= maxMonths; month++) {
      if (simulationDebts.every((debt) => debt.balanceInCents <= 0)) {
        break;
      }

      final activeDebts = simulationDebts
          .where((debt) => debt.balanceInCents > 0)
          .toList();

      var monthInterest = 0;
      var monthPrincipal = 0;
      var monthPayment = 0;

      // ------------------------------------------------------------
      // Interest
      // ------------------------------------------------------------

      for (final debt in activeDebts) {
        final interest = _calculateMonthlyInterest(
          balanceInCents: debt.balanceInCents,
          annualInterestRate: debt.annualInterestRate,
        );

        debt.balanceInCents += interest;

        monthInterest += interest;
        totalInterest += interest;
      }

      // ------------------------------------------------------------
      // Minimum payments
      // ------------------------------------------------------------

      for (final debt in activeDebts) {
        if (debt.balanceInCents <= 0) {
          continue;
        }

        final payment = _safeMinimumPayment(
          balanceInCents: debt.balanceInCents,
          minimumPaymentInCents: debt.minimumPaymentInCents,
        );

        debt.balanceInCents -= payment;

        monthPayment += payment;
        monthPrincipal += payment;

        totalPaid += payment;
      }

      // ------------------------------------------------------------
      // Extra payment
      // ------------------------------------------------------------

      var extra = extraMonthlyPaymentInCents;

      while (extra > 0) {
        final remaining = simulationDebts
            .where((debt) => debt.balanceInCents > 0)
            .toList();

        if (remaining.isEmpty) {
          break;
        }

        remaining.sort((a, b) => _compareDebts(a, b, strategy));

        final target = remaining.first;

        final payment = extra > target.balanceInCents
            ? target.balanceInCents
            : extra;

        target.balanceInCents -= payment;

        extra -= payment;

        monthPayment += payment;
        monthPrincipal += payment;

        totalPaid += payment;
      }

      final balances = <String, int>{
        for (final debt in simulationDebts) debt.id: debt.balanceInCents,
      };

      snapshots.add(
        DebtPayoffMonthSnapshot(
          month: month,
          balancesInCents: Map.unmodifiable(balances),
          interestPaidInCents: monthInterest,
          principalPaidInCents: monthPrincipal,
          totalPaymentInCents: monthPayment,
        ),
      );

      if (simulationDebts.every((debt) => debt.balanceInCents <= 0)) {
        break;
      }
    }

    return DebtPayoffSimulation(
      snapshots: List.unmodifiable(snapshots),
      totalMonths: snapshots.length,
      totalInterestPaidInCents: totalInterest,
      totalPaidInCents: totalPaid,
    );
  }

  /// Calculates the monthly interest from APR.
  ///
  /// Formula:
  ///
  /// monthly interest =
  /// balance × (annual rate / 100) / 12
  ///
  /// Rounded to the nearest cent.
  int _calculateMonthlyInterest({
    required int balanceInCents,
    required double annualInterestRate,
  }) {
    if (balanceInCents <= 0 || annualInterestRate <= 0) {
      return 0;
    }

    final monthlyRate = annualInterestRate / 100 / 12;

    return (balanceInCents * monthlyRate).round();
  }

  int _safeMinimumPayment({
    required int balanceInCents,
    required int minimumPaymentInCents,
  }) {
    if (balanceInCents <= 0) {
      return 0;
    }

    if (minimumPaymentInCents <= 0) {
      return 0;
    }

    return minimumPaymentInCents > balanceInCents
        ? balanceInCents
        : minimumPaymentInCents;
  }

  /// Determines which debt receives the extra payment.
  ///
  /// Avalanche:
  /// highest interest rate first.
  ///
  /// Snowball:
  /// smallest balance first.
  ///
  /// Stable tie breakers are used so the algorithm
  /// remains deterministic.
  int _compareDebts(
    _SimulationDebt a,
    _SimulationDebt b,
    DebtPayoffStrategy strategy,
  ) {
    if (strategy == DebtPayoffStrategy.avalanche) {
      final interestComparison = b.annualInterestRate.compareTo(
        a.annualInterestRate,
      );

      if (interestComparison != 0) {
        return interestComparison;
      }

      final balanceComparison = a.balanceInCents.compareTo(b.balanceInCents);

      if (balanceComparison != 0) {
        return balanceComparison;
      }
    } else {
      final balanceComparison = a.balanceInCents.compareTo(b.balanceInCents);

      if (balanceComparison != 0) {
        return balanceComparison;
      }

      final interestComparison = b.annualInterestRate.compareTo(
        a.annualInterestRate,
      );

      if (interestComparison != 0) {
        return interestComparison;
      }
    }

    return a.id.compareTo(b.id);
  }
}

/// Month-by-month debt simulation.
class DebtPayoffSimulation {
  final List<DebtPayoffMonthSnapshot> snapshots;

  final int totalMonths;

  final int totalInterestPaidInCents;

  final int totalPaidInCents;

  const DebtPayoffSimulation({
    required this.snapshots,
    required this.totalMonths,
    required this.totalInterestPaidInCents,
    required this.totalPaidInCents,
  });

  DebtPayoffMonthSnapshot? get latestSnapshot {
    if (snapshots.isEmpty) {
      return null;
    }

    return snapshots.last;
  }

  int get remainingBalanceInCents {
    return latestSnapshot?.totalRemainingBalanceInCents ?? 0;
  }
}

/// Internal mutable representation used only during
/// calculations.
///
/// This is intentionally not a Hive model.
class _SimulationDebt {
  final String id;
  final String name;

  final int originalBalanceInCents;

  int balanceInCents;

  final double annualInterestRate;

  final int minimumPaymentInCents;

  int totalPaidInCents = 0;

  int monthlyInterestAccumulatedInCents = 0;

  int? payoffMonth;

  _SimulationDebt({
    required this.id,
    required this.name,
    required this.originalBalanceInCents,
    required this.balanceInCents,
    required this.annualInterestRate,
    required this.minimumPaymentInCents,
  });
}
