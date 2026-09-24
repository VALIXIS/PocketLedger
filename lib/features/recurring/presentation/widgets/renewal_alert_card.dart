import 'package:flutter/material.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../providers/upcoming_payment_countdown.dart';

class RenewalAlertCard extends StatelessWidget {
  final UpcomingPaymentCountdown countdown;
  final String currency;
  final VoidCallback? onViewPressed;

  const RenewalAlertCard({
    super.key,
    required this.countdown,
    required this.currency,
    this.onViewPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = countdown.recurringTransaction;

    Color alertColor;
    IconData alertIcon;
    String headerTitle;
    String countdownLabel;

    if (countdown.isOverdue) {
      alertColor = Colors.red.shade600;
      alertIcon = Icons.warning_amber_rounded;
      headerTitle = 'Payment Overdue';
      countdownLabel =
          'Scheduled for ${CurrencyFormatter.formatDate(countdown.occurrence)}';
    } else if (countdown.isDueToday) {
      alertColor = Colors.orange.shade700;
      alertIcon = Icons.notification_important_rounded;
      headerTitle = 'Due Today';
      countdownLabel = 'Renews today';
    } else if (countdown.days <= 2) {
      alertColor = Colors.amber.shade800;
      alertIcon = Icons.alarm_rounded;
      headerTitle = 'Renewal Due Soon';
      countdownLabel = countdown.days == 1
          ? 'Renews tomorrow (${countdown.hours}h left)'
          : 'Renews in ${countdown.days} days';
    } else if (countdown.days <= 6) {
      alertColor = Colors.teal.shade700;
      alertIcon = Icons.event_available_rounded;
      headerTitle = 'Upcoming Renewal';
      countdownLabel = 'Renews in ${countdown.days} days';
    } else {
      alertColor = Colors.blue.shade700;
      alertIcon = Icons.calendar_today_rounded;
      headerTitle = 'Upcoming Renewal';
      countdownLabel = 'Renews in ${countdown.days} days';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: alertColor.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alertIcon, color: alertColor, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  headerTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: alertColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service details & amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tx.merchantName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tx.merchantName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  CurrencyFormatter.formatCents(tx.amountInCents, currency),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tx.isIncome ? Colors.green.shade600 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Countdown & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      countdownLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: alertColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatDate(countdown.occurrence),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
