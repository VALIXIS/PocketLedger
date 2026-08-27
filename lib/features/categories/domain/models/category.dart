import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isIncome;

  Category({required this.id, required this.name, required this.isIncome});

  // Static list of default categories
  static List<Category> get defaultCategories => [
    // Income Categories
    Category(id: 'salary', name: 'Salary', isIncome: true),
    Category(id: 'freelance', name: 'Freelance', isIncome: true),
    Category(id: 'business', name: 'Business', isIncome: true),
    Category(id: 'investment', name: 'Investment', isIncome: true),
    Category(id: 'income_other', name: 'Other', isIncome: true),
    // Expense Categories
    Category(id: 'food', name: 'Food', isIncome: false),
    Category(id: 'transport', name: 'Transport', isIncome: false),
    Category(id: 'shopping', name: 'Shopping', isIncome: false),
    Category(id: 'bills', name: 'Bills', isIncome: false),
    Category(id: 'entertainment', name: 'Entertainment', isIncome: false),
    Category(id: 'education', name: 'Education', isIncome: false),
    Category(id: 'health', name: 'Health', isIncome: false),
    Category(id: 'travel', name: 'Travel', isIncome: false),
    Category(id: 'expense_other', name: 'Other', isIncome: false),
  ];
}
