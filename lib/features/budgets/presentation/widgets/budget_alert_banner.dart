import 'package:flutter/material.dart';
import '../../domain/entities/budget_alert.dart';

/// Material 3 alert banner displaying individual budget threshold warnings and exceeded states.
class BudgetAlertBanner extends StatelessWidget {
  final BudgetAlert alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const BudgetAlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onTap,
  });

  IconData _getAlertIcon(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.warning:
        return Icons.warning_amber_rounded;
      case BudgetAlertLevel.danger:
        return Icons.error_outline_rounded;
      case BudgetAlertLevel.exceeded:
        return Icons.gpp_maybe_rounded;
      case BudgetAlertLevel.none:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color _getBackgroundColor(BudgetAlertLevel level, ColorScheme colorScheme) {
    switch (level) {
      case BudgetAlertLevel.warning:
        return colorScheme.tertiaryContainer;
      case BudgetAlertLevel.danger:
        return colorScheme.errorContainer.withValues(alpha: 0.6);
      case BudgetAlertLevel.exceeded:
        return colorScheme.errorContainer;
      case BudgetAlertLevel.none:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getForegroundColor(BudgetAlertLevel level, ColorScheme colorScheme) {
    switch (level) {
      case BudgetAlertLevel.warning:
        return colorScheme.onTertiaryContainer;
      case BudgetAlertLevel.danger:
        return colorScheme.onErrorContainer;
      case BudgetAlertLevel.exceeded:
        return colorScheme.onErrorContainer;
      case BudgetAlertLevel.none:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getBadgeText(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.warning:
        return 'WARNING 75%';
      case BudgetAlertLevel.danger:
        return 'DANGER 90%';
      case BudgetAlertLevel.exceeded:
        return 'EXCEEDED 100%';
      case BudgetAlertLevel.none:
        return 'NORMAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = _getBackgroundColor(alert.level, colorScheme);
    final fgColor = _getForegroundColor(alert.level, colorScheme);
    final icon = _getAlertIcon(alert.level);
    final badgeText = _getBadgeText(alert.level);

    return Container(
      key: Key('budget_alert_banner_${alert.budgetId}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: fgColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: fgColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: fgColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.budgetName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: fgColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (alert.percentageSpent / 100.0).clamp(0.0, 1.0),
                          color: fgColor,
                          backgroundColor: fgColor.withValues(alpha: 0.2),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    key: Key('dismiss_alert_${alert.budgetId}'),
                    icon: Icon(Icons.close, color: fgColor, size: 20),
                    tooltip: 'Dismiss alert',
                    onPressed: onDismiss,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard section displaying active budget alert banners.
class BudgetAlertSection extends StatelessWidget {
  final List<BudgetAlert> alerts;
  final Function(BudgetAlert)? onAlertDismissed;
  final Function(BudgetAlert)? onAlertTap;

  const BudgetAlertSection({
    super.key,
    required this.alerts,
    this.onAlertDismissed,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const Key('budget_alert_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Budget Alerts (${alerts.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        ...alerts.map(
          (alert) => BudgetAlertBanner(
            alert: alert,
            onDismiss: onAlertDismissed != null ? () => onAlertDismissed!(alert) : null,
            onTap: onAlertTap != null ? () => onAlertTap!(alert) : null,
          ),
        ),
      ],
    );
  }
}
