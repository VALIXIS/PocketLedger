import 'package:flutter/material.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../data/models/recurring_transaction.dart';
import '../providers/upcoming_payment_countdown.dart';

class RecurringSummary extends StatelessWidget {
  final List<RecurringTransaction> transactions;
  final String currency;
  final UpcomingPaymentCountdown? nearestPayment;

  const RecurringSummary({
    super.key,
    required this.transactions,
    required this.currency,
    this.nearestPayment,
  });

  /// Calculates the monthly equivalent cost in integer cents.
  static int calculateMonthlyCostInCents(List<RecurringTransaction> list) {
    int total = 0;
    for (final tx in list) {
      if (!tx.isActive || tx.isIncome) continue;
      switch (tx.recurrenceType) {
        case RecurrenceType.weekly:
          // weekly amount * 52 / 12 with integer arithmetic
          total += (tx.amountInCents * 52) ~/ 12;
          break;
        case RecurrenceType.monthly:
          total += tx.amountInCents;
          break;
        case RecurrenceType.yearly:
          total += tx.amountInCents ~/ 12;
          break;
      }
    }
    return total;
  }

  /// Calculates the annual equivalent cost in integer cents.
  static int calculateAnnualCostInCents(List<RecurringTransaction> list) {
    int total = 0;
    for (final tx in list) {
      if (!tx.isActive || tx.isIncome) continue;
      switch (tx.recurrenceType) {
        case RecurrenceType.weekly:
          total += tx.amountInCents * 52;
          break;
        case RecurrenceType.monthly:
          total += tx.amountInCents * 12;
          break;
        case RecurrenceType.yearly:
          total += tx.amountInCents;
          break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeCount = transactions.where((tx) => tx.isActive).length;
    final monthlyCost = calculateMonthlyCostInCents(transactions);
    final annualCost = calculateAnnualCostInCents(transactions);

    String nextRenewalText = 'No upcoming renewals';
    if (nearestPayment != null) {
      final name = nearestPayment!.recurringTransaction.name;
      if (nearestPayment!.isDueToday) {
        nextRenewalText = 'Next: $name — Due Today';
      } else if (nearestPayment!.isOverdue) {
        nextRenewalText = 'Next: $name — Overdue';
      } else if (nearestPayment!.days == 0) {
        nextRenewalText = 'Next: $name — in ${nearestPayment!.hours}h';
      } else if (nearestPayment!.days == 1) {
        nextRenewalText = 'Next: $name — in 1 day';
      } else {
        nextRenewalText = 'Next: $name — in ${nearestPayment!.days} days';
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? const Color(0xFF1E1E1E)
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      color: isDark
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SUBSCRIPTIONS & RECURRING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark
                            ? Colors.grey.shade400
                            : theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.teal.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCount Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.tealAccent
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Cost Stats Grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : theme.colorScheme.onPrimaryContainer.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.formatCents(monthlyCost, currency)} / mo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annual Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : theme.colorScheme.onPrimaryContainer.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.formatCents(annualCost, currency)} / yr',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Next Renewal Line
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.tealAccent
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nextRenewalText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade300
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
