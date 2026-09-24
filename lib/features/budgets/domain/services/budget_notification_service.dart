import '../entities/budget_alert.dart';

/// Encapsulates notification details emitted when a budget alert state changes.
class BudgetNotificationPayload {
  /// The evaluated budget alert
  final BudgetAlert alert;

  /// The previous alert level prior to this state transition
  final BudgetAlertLevel previousLevel;

  /// Timestamp when the notification was emitted
  final DateTime notifiedAt;

  BudgetNotificationPayload({
    required this.alert,
    required this.previousLevel,
    DateTime? notifiedAt,
  }) : notifiedAt = notifiedAt ?? DateTime.now();
}

/// Notification service providing state transition deduplication and notification hooks.
class BudgetNotificationService {
  final Map<String, BudgetAlertLevel> _lastNotifiedLevels = {};
  final List<BudgetNotificationPayload> _notificationLog = [];

  BudgetNotificationService({Map<String, BudgetAlertLevel>? initialLevels}) {
    if (initialLevels != null) {
      _lastNotifiedLevels.addAll(initialLevels);
    }
  }

  /// Unmodifiable history of emitted notification payloads.
  List<BudgetNotificationPayload> get notificationLog =>
      List.unmodifiable(_notificationLog);

  /// Retrieves the recorded alert level for a given [budgetId].
  BudgetAlertLevel getLastNotifiedLevel(String budgetId) {
    return _lastNotifiedLevels[budgetId] ?? BudgetAlertLevel.none;
  }

  /// Processes a single [alert] and emits a [BudgetNotificationPayload] only if a state transition occurs.
  ///
  /// State transitions are deduplicated: staying within the same non-none level (e.g. 76% to 78% warning)
  /// will NOT emit a notification payload.
  BudgetNotificationPayload? processAlert(BudgetAlert alert) {
    final prevLevel = getLastNotifiedLevel(alert.budgetId);

    // If level changed to an active non-none level, emit notification payload
    if (alert.isActive && alert.level != prevLevel) {
      _lastNotifiedLevels[alert.budgetId] = alert.level;
      final payload = BudgetNotificationPayload(
        alert: alert,
        previousLevel: prevLevel,
      );
      _notificationLog.add(payload);
      return payload;
    }

    // If level de-escalated back to none, reset tracked state
    if (alert.level == BudgetAlertLevel.none &&
        prevLevel != BudgetAlertLevel.none) {
      _lastNotifiedLevels[alert.budgetId] = BudgetAlertLevel.none;
    }

    return null;
  }

  /// Processes a list of [alerts] and returns all newly emitted notification payloads.
  List<BudgetNotificationPayload> processAlerts(List<BudgetAlert> alerts) {
    final List<BudgetNotificationPayload> emitted = [];
    for (final alert in alerts) {
      final payload = processAlert(alert);
      if (payload != null) {
        emitted.add(payload);
      }
    }
    return emitted;
  }

  /// Resets state tracking for a specific budget or all budgets.
  void clearHistory({String? budgetId}) {
    if (budgetId != null) {
      _lastNotifiedLevels.remove(budgetId);
    } else {
      _lastNotifiedLevels.clear();
      _notificationLog.clear();
    }
  }
}
