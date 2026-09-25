import 'package:flutter/material.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../data/models/recurring_transaction.dart';
import 'recurring_form.dart';

class CancellationReminderCard extends StatelessWidget {
  final List<RecurringTransaction> transactions;
  final String currency;

  const CancellationReminderCard({
    super.key,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter transactions that have reminder enabled and are within the reminder window
    final reminders = transactions.where((tx) {
      if (!tx.isActive) return false;
      return tx.shouldShowReminder(now) ||
          (tx.endDate != null &&
              tx.endDate!.isAfter(now) &&
              tx.endDate!.difference(now).inDays <= tx.reminderDaysBefore);
    }).toList();

    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    final tx = reminders.first;
    final isEndingSoon =
        tx.endDate != null &&
        tx.endDate!.isAfter(now) &&
        tx.endDate!.difference(now).inDays <= tx.reminderDaysBefore;

    final title = isEndingSoon
        ? 'Subscription Ending Soon'
        : 'Subscription Reminder';
    final message = isEndingSoon
        ? '${tx.name} is set to end on ${CurrencyFormatter.formatDate(tx.endDate!)}.'
        : '${tx.name} renews on ${CurrencyFormatter.formatDate(tx.nextOccurrence)} (Reminder set for ${tx.reminderDaysBefore} days before).';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.amber.shade700.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.amber.shade800,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatCents(tx.amountInCents, currency),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => RecurringForm.showEdit(context, tx),
                  child: const Text('Review Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
