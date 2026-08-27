import 'package:hive/hive.dart';
import 'transaction_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final TransactionType type;

  @HiveField(2)
  final int amountInCents;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String note;

  @HiveField(6)
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amountInCents,
    required this.category,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  // Helper to convert double amount to integer cents safely
  static int doubleToCents(double amount) {
    // Round to avoid float precision issues, e.g. 19.99 * 100 -> 1999
    return (amount * 100).round();
  }

  // Helper to get double representation of the amount
  double get amount => amountInCents / 100.0;

  // Helper copyWith method
  Transaction copyWith({
    String? id,
    TransactionType? type,
    int? amountInCents,
    String? category,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountInCents: amountInCents ?? this.amountInCents,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
