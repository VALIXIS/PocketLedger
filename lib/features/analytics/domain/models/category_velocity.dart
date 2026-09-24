import 'package:flutter/foundation.dart';

@immutable
class CategoryVelocity {
  final String category;
  final String categoryName;
  final double totalSpending;
  final int transactionCount;
  final double dailyVelocity;
  final int periodDays;

  const CategoryVelocity({
    required this.category,
    required this.categoryName,
    required this.totalSpending,
    required this.transactionCount,
    required this.dailyVelocity,
    required this.periodDays,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryVelocity &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          categoryName == other.categoryName &&
          totalSpending == other.totalSpending &&
          transactionCount == other.transactionCount &&
          dailyVelocity == other.dailyVelocity &&
          periodDays == other.periodDays;

  @override
  int get hashCode =>
      category.hashCode ^
      categoryName.hashCode ^
      totalSpending.hashCode ^
      transactionCount.hashCode ^
      dailyVelocity.hashCode ^
      periodDays.hashCode;

  @override
  String toString() {
    return 'CategoryVelocity($categoryName: \$totalSpending total, \$dailyVelocity/day over $periodDays days)';
  }
}
