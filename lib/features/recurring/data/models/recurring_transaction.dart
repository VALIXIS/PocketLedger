import 'package:hive/hive.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 7)
enum RecurrenceType {
  @HiveField(0)
  weekly,

  @HiveField(1)
  monthly,

  @HiveField(2)
  yearly,
}

@HiveType(typeId: 8)
enum RecurringTransactionStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  paused,

  @HiveField(2)
  cancelled,
}

@HiveType(typeId: 5)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int amountInCents;

  @HiveField(4)
  final bool isIncome;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final RecurrenceType recurrenceType;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime nextOccurrence;

  @HiveField(9)
  final DateTime? endDate;

  @HiveField(10)
  final RecurringTransactionStatus status;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String userId;

  @HiveField(14)
  final bool reminderEnabled;

  @HiveField(15)
  final int reminderDaysBefore;

  @HiveField(16)
  final String merchantName;

  @HiveField(17)
  final String iconName;

  RecurringTransaction({
    required this.id,
    required this.name,
    this.description = '',
    required this.amountInCents,
    this.isIncome = false,
    required this.category,
    required this.recurrenceType,
    required this.startDate,
    required this.nextOccurrence,
    this.endDate,
    this.status = RecurringTransactionStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.userId = '',
    this.reminderEnabled = false,
    this.reminderDaysBefore = 3,
    this.merchantName = '',
    this.iconName = 'repeat',
  }) : assert(amountInCents >= 0, 'Amount cannot be negative'),
       assert(
         reminderDaysBefore >= 0,
         'Reminder days before cannot be negative',
       );

  /// Helper to convert double amount to integer cents safely.
  static int doubleToCents(double amount) {
    return (amount * 100).round();
  }

  /// Helper getter to get double representation of the amount.
  double get amount => amountInCents / 100.0;

  /// Returns true if the transaction is active and has not passed its end date.
  bool get isActive => status == RecurringTransactionStatus.active && !hasEnded;

  /// Returns true if nextOccurrence has passed its end date.
  bool get hasEnded {
    if (endDate == null) return false;
    final normalizedNext = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
    );
    final normalizedEnd = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return normalizedNext.isAfter(normalizedEnd);
  }

  /// Calculates the next occurrence date based on recurrence type and calendar math.
  DateTime calculateNextOccurrence() {
    switch (recurrenceType) {
      case RecurrenceType.weekly:
        return DateTime(
          nextOccurrence.year,
          nextOccurrence.month,
          nextOccurrence.day + 7,
          nextOccurrence.hour,
          nextOccurrence.minute,
          nextOccurrence.second,
          nextOccurrence.millisecond,
          nextOccurrence.microsecond,
        );
      case RecurrenceType.monthly:
        return _addMonths(nextOccurrence, 1);
      case RecurrenceType.yearly:
        return _addMonths(nextOccurrence, 12);
    }
  }

  /// Advances to the next occurrence, updates status if past endDate, and updates updatedAt.
  RecurringTransaction advanceToNextOccurrence() {
    final next = calculateNextOccurrence();
    final isPastEndDate =
        endDate != null &&
        DateTime(
          next.year,
          next.month,
          next.day,
        ).isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day));

    return copyWith(
      nextOccurrence: next,
      status: isPastEndDate ? RecurringTransactionStatus.cancelled : status,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns true if the recurring transaction is active and due on the supplied date.
  bool isDueOn(DateTime date) {
    if (!isActive) return false;
    if (hasEnded) return false;

    return date.year == nextOccurrence.year &&
        date.month == nextOccurrence.month &&
        date.day == nextOccurrence.day;
  }

  /// Returns true if a reminder should be shown on the supplied date.
  bool shouldShowReminder(DateTime date) {
    if (!isActive) return false;
    if (!reminderEnabled) return false;

    final targetDate = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
    );
    final currentDate = DateTime(date.year, date.month, date.day);

    final differenceInDays = targetDate.difference(currentDate).inDays;
    return differenceInDays >= 0 && differenceInDays <= reminderDaysBefore;
  }

  /// Safe copyWith method allowing individual field updates and explicit clearing of endDate.
  RecurringTransaction copyWith({
    String? id,
    String? name,
    String? description,
    int? amountInCents,
    bool? isIncome,
    String? category,
    RecurrenceType? recurrenceType,
    DateTime? startDate,
    DateTime? nextOccurrence,
    DateTime? endDate,
    bool clearEndDate = false,
    RecurringTransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    String? merchantName,
    String? iconName,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amountInCents: amountInCents ?? this.amountInCents,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      startDate: startDate ?? this.startDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      merchantName: merchantName ?? this.merchantName,
      iconName: iconName ?? this.iconName,
    );
  }

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = (date.year * 12) + (date.month - 1) + monthsToAdd;
    final newYear = totalMonths ~/ 12;
    final newMonth = (totalMonths % 12) + 1;
    final daysInNewMonth = _daysInMonth(newYear, newMonth);
    final newDay = date.day > daysInNewMonth ? daysInNewMonth : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear =
          (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonths = [31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonths[month - 1];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          amountInCents == other.amountInCents &&
          isIncome == other.isIncome &&
          category == other.category &&
          recurrenceType == other.recurrenceType &&
          startDate == other.startDate &&
          nextOccurrence == other.nextOccurrence &&
          endDate == other.endDate &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          userId == other.userId &&
          reminderEnabled == other.reminderEnabled &&
          reminderDaysBefore == other.reminderDaysBefore &&
          merchantName == other.merchantName &&
          iconName == other.iconName;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      amountInCents.hashCode ^
      isIncome.hashCode ^
      category.hashCode ^
      recurrenceType.hashCode ^
      startDate.hashCode ^
      nextOccurrence.hashCode ^
      endDate.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      userId.hashCode ^
      reminderEnabled.hashCode ^
      reminderDaysBefore.hashCode ^
      merchantName.hashCode ^
      iconName.hashCode;

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, name: $name, amountInCents: $amountInCents, recurrenceType: $recurrenceType, nextOccurrence: $nextOccurrence, status: $status)';
  }
}
