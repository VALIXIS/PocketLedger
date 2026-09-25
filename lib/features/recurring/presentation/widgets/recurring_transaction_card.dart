import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/recurring_transaction.dart';
import '../providers/recurring_list_notifier.dart';
import '../providers/upcoming_payment_countdown.dart';
import 'recurrence_cycle_chip.dart';
import 'recurring_form.dart';

class RecurringTransactionCard extends ConsumerWidget {
  final RecurringTransaction transaction;
  final UpcomingPaymentCountdown? countdown;

  const RecurringTransactionCard({
    super.key,
    required this.transaction,
    this.countdown,
  });

  void _showCancelConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: Text(
          'Are you sure you want to cancel "${transaction.name}"?\nIt will no longer generate future recurring transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Subscription'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(recurringListNotifierProvider.notifier)
                    .cancelRecurringTransaction(transaction.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Subscription "${transaction.name}" cancelled',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Payment?'),
        content: Text(
          'This removes "${transaction.name}" permanently from PocketLedger.\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(recurringListNotifierProvider.notifier)
                    .deleteRecurringTransaction(transaction.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recurring payment "${transaction.name}" deleted',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    Color textColor;
    String label;

    switch (transaction.status) {
      case RecurringTransactionStatus.active:
        chipColor = Colors.teal.shade50;
        textColor = Colors.teal.shade800;
        label = 'ACTIVE';
        break;
      case RecurringTransactionStatus.paused:
        chipColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = 'PAUSED';
        break;
      case RecurringTransactionStatus.cancelled:
        chipColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = 'CANCELLED';
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      chipColor = chipColor.withValues(alpha: 0.15);
      textColor = textColor.withValues(alpha: 0.9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  String _getCountdownText() {
    if (countdown != null) {
      if (countdown!.isOverdue) return 'Payment Overdue';
      if (countdown!.isDueToday) return 'Due today';
      if (countdown!.days == 0) return 'Renews in ${countdown!.hours}h';
      if (countdown!.days == 1) return 'Renews in 1 day';
      return 'Renews in ${countdown!.days} days';
    }

    final now = DateTime.now();
    final diff = transaction.nextOccurrence.difference(now);
    if (diff.isNegative) return 'Payment Overdue';
    if (diff.inDays == 0) return 'Due today';
    return 'Renews in ${diff.inDays} days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(settingsProvider).currency;
    final catColor = CategoryUiHelper.getColor(transaction.category);
    final catIcon = CategoryUiHelper.getIcon(transaction.category);
    final countdownString = _getCountdownText();

    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar Icon, Name & Merchant, Status Chip & Popup Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: catColor.withValues(alpha: 0.15),
                  child: Icon(catIcon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (transaction.merchantName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.merchantName,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(context),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (action) async {
                        if (action == 'edit') {
                          RecurringForm.showEdit(context, transaction);
                        } else if (action == 'pause') {
                          await ref
                              .read(recurringListNotifierProvider.notifier)
                              .pauseRecurringTransaction(transaction.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${transaction.name}" paused'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else if (action == 'resume') {
                          await ref
                              .read(recurringListNotifierProvider.notifier)
                              .resumeRecurringTransaction(transaction.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${transaction.name}" resumed'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else if (action == 'cancel') {
                          _showCancelConfirmation(context, ref);
                        } else if (action == 'delete') {
                          _showDeleteConfirmation(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (transaction.status ==
                            RecurringTransactionStatus.active)
                          const PopupMenuItem(
                            value: 'pause',
                            child: Row(
                              children: [
                                Icon(Icons.pause_circle_outline, size: 18),
                                SizedBox(width: 10),
                                Text('Pause'),
                              ],
                            ),
                          ),
                        if (transaction.status ==
                            RecurringTransactionStatus.paused)
                          const PopupMenuItem(
                            value: 'resume',
                            child: Row(
                              children: [
                                Icon(Icons.play_circle_outline, size: 18),
                                SizedBox(width: 10),
                                Text('Resume'),
                              ],
                            ),
                          ),
                        if (transaction.status !=
                            RecurringTransactionStatus.cancelled)
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  size: 18,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Cancel Subscription',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount & Cycle Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      transaction.isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: transaction.isIncome
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${transaction.isIncome ? '+' : '-'} ${CurrencyFormatter.formatCents(transaction.amountInCents, currency)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: transaction.isIncome
                            ? Colors.green.shade600
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
                RecurrenceCycleChip(
                  recurrenceType: transaction.recurrenceType,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Next Due Date & Countdown Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Next: ${CurrencyFormatter.formatDate(transaction.nextOccurrence)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  countdownString,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        transaction.status == RecurringTransactionStatus.active
                        ? theme.colorScheme.primary
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            // Reminder status if enabled
            if (transaction.reminderEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 13,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reminder: ${transaction.reminderDaysBefore} days before',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Quick Actions Toolbar Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => RecurringForm.showEdit(context, transaction),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                ),
                if (transaction.status ==
                    RecurringTransactionStatus.active) ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(recurringListNotifierProvider.notifier)
                          .pauseRecurringTransaction(transaction.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Subscription "${transaction.name}" paused',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.pause_rounded, size: 16),
                    label: const Text('Pause'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                  ),
                ] else if (transaction.status ==
                    RecurringTransactionStatus.paused) ...[
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(recurringListNotifierProvider.notifier)
                          .resumeRecurringTransaction(transaction.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Subscription "${transaction.name}" resumed',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Resume'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
