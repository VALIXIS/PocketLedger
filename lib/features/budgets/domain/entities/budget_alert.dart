/// Represents the threshold severity level of a budget alert.
enum BudgetAlertLevel {
  /// Spent < 75% (Normal spending)
  none,

  /// Spent >= 75% and < 90% (Warning threshold)
  warning,

  /// Spent >= 90% and < 100% (Critical danger threshold)
  danger,

  /// Spent >= 100% (Exceeded budget threshold)
  exceeded,
}

/// Domain entity encapsulating an evaluated budget alert state.
class BudgetAlert {
  /// Unique identifier of the budget
  final String budgetId;

  /// Display name of the budget
  final String budgetName;

  /// Associated category ID (if any)
  final String categoryId;

  /// Severity level of the alert
  final BudgetAlertLevel level;

  /// Total spent in integer cents
  final int spentInCents;

  /// Total allocated budget in integer cents
  final int amountInCents;

  /// Remaining budget in integer cents (can be negative if exceeded)
  final int remainingInCents;

  /// Exact percentage spent (e.g. 75.5 for 75.5%)
  final double percentageSpent;

  /// User-facing descriptive message for the alert
  final String message;

  /// Timestamp when this alert was generated
  final DateTime timestamp;

  BudgetAlert({
    required this.budgetId,
    required this.budgetName,
    required this.categoryId,
    required this.level,
    required this.spentInCents,
    required this.amountInCents,
    required this.remainingInCents,
    required this.percentageSpent,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Helper to convert spentInCents to double dollars
  double get spent => spentInCents / 100.0;

  /// Helper to convert amountInCents to double dollars
  double get amount => amountInCents / 100.0;

  /// Helper to convert remainingInCents to double dollars
  double get remaining => remainingInCents / 100.0;

  /// Returns true if this alert is active (warning, danger, or exceeded)
  bool get isActive => level != BudgetAlertLevel.none;

  BudgetAlert copyWith({
    String? budgetId,
    String? budgetName,
    String? categoryId,
    BudgetAlertLevel? level,
    int? spentInCents,
    int? amountInCents,
    int? remainingInCents,
    double? percentageSpent,
    String? message,
    DateTime? timestamp,
  }) {
    return BudgetAlert(
      budgetId: budgetId ?? this.budgetId,
      budgetName: budgetName ?? this.budgetName,
      categoryId: categoryId ?? this.categoryId,
      level: level ?? this.level,
      spentInCents: spentInCents ?? this.spentInCents,
      amountInCents: amountInCents ?? this.amountInCents,
      remainingInCents: remainingInCents ?? this.remainingInCents,
      percentageSpent: percentageSpent ?? this.percentageSpent,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
