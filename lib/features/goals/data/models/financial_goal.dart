import 'package:hive/hive.dart';

part 'financial_goal.g.dart';

@HiveType(typeId: 6)
enum GoalStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  completed,

  @HiveField(2)
  paused,

  @HiveField(3)
  cancelled,
}

@HiveType(typeId: 4)
class FinancialGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int targetAmountInCents;

  @HiveField(4)
  final int savedAmountInCents;

  @HiveField(5)
  final DateTime? targetDate;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final GoalStatus status;

  @HiveField(9)
  final String iconName;

  @HiveField(10)
  final int colorValue;

  @HiveField(11)
  final String userId;

  FinancialGoal({
    required this.id,
    required this.name,
    this.description = '',
    required this.targetAmountInCents,
    this.savedAmountInCents = 0,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.status = GoalStatus.active,
    this.iconName = 'savings',
    this.colorValue = 0xFF4CAF50,
    this.userId = '',
  })  : assert(targetAmountInCents >= 0, 'Target amount cannot be negative'),
        assert(savedAmountInCents >= 0, 'Saved amount cannot be negative');

  /// Helper to convert double amount to integer cents safely.
  static int doubleToCents(double amount) {
    return (amount * 100).round();
  }

  /// Helper to get double representation of target amount.
  double get targetAmount => targetAmountInCents / 100.0;

  /// Helper to get double representation of saved amount.
  double get savedAmount => savedAmountInCents / 100.0;

  /// Helper to get double representation of remaining amount.
  double get remainingAmount => remainingAmountInCents / 100.0;

  /// Remaining amount in cents until target is reached. Never returns a negative value.
  int get remainingAmountInCents {
    final diff = targetAmountInCents - savedAmountInCents;
    return diff > 0 ? diff : 0;
  }

  /// Progress ratio between 0.0 and 1.0.
  double get progress {
    if (targetAmountInCents <= 0) return 0.0;
    final value = savedAmountInCents / targetAmountInCents;
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }

  /// Progress as a percentage between 0 and 100.
  double get progressPercentage => progress * 100.0;

  /// A goal is completed when savedAmountInCents >= targetAmountInCents or its status is completed.
  bool get isCompleted =>
      status == GoalStatus.completed || savedAmountInCents >= targetAmountInCents;

  /// Returns a copy of this FinancialGoal with updated fields.
  FinancialGoal copyWith({
    String? id,
    String? name,
    String? description,
    int? targetAmountInCents,
    int? savedAmountInCents,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    GoalStatus? status,
    String? iconName,
    int? colorValue,
    String? userId,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmountInCents: targetAmountInCents ?? this.targetAmountInCents,
      savedAmountInCents: savedAmountInCents ?? this.savedAmountInCents,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      userId: userId ?? this.userId,
    );
  }

  /// Adds a contribution to the savings goal.
  /// Rejects zero and negative values.
  /// Automatically marks the goal completed when target is reached.
  FinancialGoal addContribution(int amountInCents) {
    if (amountInCents <= 0) {
      throw ArgumentError.value(
        amountInCents,
        'amountInCents',
        'Contribution amount must be greater than zero.',
      );
    }
    final newSavedAmount = savedAmountInCents + amountInCents;
    final isTargetReached = newSavedAmount >= targetAmountInCents;
    return copyWith(
      savedAmountInCents: newSavedAmount,
      status: isTargetReached ? GoalStatus.completed : status,
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a contribution from the savings goal.
  /// Rejects zero and negative values.
  /// Never allows saved amount below zero.
  /// Updates status appropriately if previously completed.
  FinancialGoal removeContribution(int amountInCents) {
    if (amountInCents <= 0) {
      throw ArgumentError.value(
        amountInCents,
        'amountInCents',
        'Amount to remove must be greater than zero.',
      );
    }
    final calculatedSaved = savedAmountInCents - amountInCents;
    final newSavedAmount = calculatedSaved < 0 ? 0 : calculatedSaved;

    GoalStatus newStatus = status;
    if (status == GoalStatus.completed && newSavedAmount < targetAmountInCents) {
      newStatus = GoalStatus.active;
    }

    return copyWith(
      savedAmountInCents: newSavedAmount,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          targetAmountInCents == other.targetAmountInCents &&
          savedAmountInCents == other.savedAmountInCents &&
          targetDate == other.targetDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          status == other.status &&
          iconName == other.iconName &&
          colorValue == other.colorValue &&
          userId == other.userId;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      targetAmountInCents.hashCode ^
      savedAmountInCents.hashCode ^
      targetDate.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      status.hashCode ^
      iconName.hashCode ^
      colorValue.hashCode ^
      userId.hashCode;

  @override
  String toString() {
    return 'FinancialGoal(id: $id, name: $name, targetAmountInCents: $targetAmountInCents, savedAmountInCents: $savedAmountInCents, status: $status)';
  }
}
