import 'package:flutter/material.dart';
import '../../data/models/recurring_transaction.dart';

class RecurrenceCycleChip extends StatelessWidget {
  final RecurrenceType recurrenceType;
  final bool compact;

  const RecurrenceCycleChip({
    super.key,
    required this.recurrenceType,
    this.compact = false,
  });

  static String getLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Annual';
    }
  }

  static IconData getIcon(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.weekly:
        return Icons.calendar_view_week_rounded;
      case RecurrenceType.monthly:
        return Icons.calendar_month_rounded;
      case RecurrenceType.yearly:
        return Icons.event_repeat_rounded;
    }
  }

  static Color getColor(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.weekly:
        return const Color(0xFF0288D1); // Light Blue
      case RecurrenceType.monthly:
        return const Color(0xFF7B1FA2); // Purple
      case RecurrenceType.yearly:
        return const Color(0xFFE65100); // Orange
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = getColor(recurrenceType);
    final label = getLabel(recurrenceType);
    final icon = getIcon(recurrenceType);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
