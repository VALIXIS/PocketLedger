import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 4)
enum BudgetPeriod {
  @HiveField(0)
  weekly,

  @HiveField(1)
  monthly,

  @HiveField(2)
  yearly,
}

@HiveType(typeId: 3)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int amountInCents;

  @HiveField(4)
  final BudgetPeriod period;

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final bool rolloverEnabled;

  Budget({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.period,
    required this.startDate,
    this.categoryId = '',
    this.rolloverEnabled = false,
  });

  // Helper to convert double amount to integer cents safely
  static int doubleToCents(double amount) {
    return (amount * 100).round();
  }

  // Helper getter to get double representation of the amount
  double get amount => amountInCents / 100.0;

  // Helper copyWith method
  Budget copyWith({
    String? id,
    String? categoryId,
    String? name,
    int? amountInCents,
    BudgetPeriod? period,
    DateTime? startDate,
    bool? rolloverEnabled,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      amountInCents: amountInCents ?? this.amountInCents,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
    );
  }
}
