import '../../budgets/domain/entities/budget.dart';
import '../../categories/domain/models/category.dart';
import '../../transactions/domain/models/transaction.dart';
import '../../transactions/domain/models/transaction_type.dart';

/// Structured schema payload representing a complete PocketLedger backup.
class BackupPayload {
  static const int currentSchemaVersion = 1;
  static const String appIdentifier = 'PocketLedger';

  final int schemaVersion;
  final String appName;
  final String appVersion;
  final DateTime createdAt;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Budget> budgets;

  BackupPayload({
    this.schemaVersion = currentSchemaVersion,
    this.appName = appIdentifier,
    this.appVersion = '1.0.0',
    DateTime? createdAt,
    required List<Transaction> transactions,
    required List<Category> categories,
    List<Budget>? budgets,
  }) : createdAt = createdAt ?? DateTime.now(),
       transactions = List.unmodifiable(transactions),
       categories = List.unmodifiable(categories),
       budgets = List.unmodifiable(budgets ?? const []);

  /// Serializes this [BackupPayload] into a standard JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'appName': appName,
      'appVersion': appVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'categories': categories
          .map((c) => {'id': c.id, 'name': c.name, 'isIncome': c.isIncome})
          .toList(),
      'transactions': transactions
          .map(
            (t) => {
              'id': t.id,
              'type': t.type.name,
              'amountInCents': t.amountInCents,
              'category': t.category,
              'date': t.date.toUtc().toIso8601String(),
              'note': t.note,
              'createdAt': t.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'budgets': budgets
          .map(
            (b) => {
              'id': b.id,
              'categoryId': b.categoryId,
              'name': b.name,
              'amountInCents': b.amountInCents,
              'period': b.period.name,
              'startDate': b.startDate.toUtc().toIso8601String(),
              'rolloverEnabled': b.rolloverEnabled,
            },
          )
          .toList(),
    };
  }

  /// Deserializes a validated JSON-compatible map into a [BackupPayload].
  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? currentSchemaVersion;
    final appName = json['appName'] as String? ?? appIdentifier;
    final appVersion = json['appVersion'] as String? ?? '1.0.0';
    final createdAt = DateTime.parse(json['createdAt'] as String);

    final categoriesList = (json['categories'] as List<dynamic>? ?? []).map((
      c,
    ) {
      final map = c as Map<String, dynamic>;
      return Category(
        id: map['id'] as String,
        name: map['name'] as String,
        isIncome: map['isIncome'] as bool,
      );
    }).toList();

    final transactionsList = (json['transactions'] as List<dynamic>? ?? []).map(
      (t) {
        final map = t as Map<String, dynamic>;
        final typeStr = map['type'] as String;
        final type = typeStr == 'income'
            ? TransactionType.income
            : TransactionType.expense;

        return Transaction(
          id: map['id'] as String,
          type: type,
          amountInCents: (map['amountInCents'] as num).toInt(),
          category: map['category'] as String,
          date: DateTime.parse(map['date'] as String),
          note: (map['note'] as String?) ?? '',
          createdAt: DateTime.parse(map['createdAt'] as String),
        );
      },
    ).toList();

    final budgetsList = (json['budgets'] as List<dynamic>? ?? []).map((b) {
      final map = b as Map<String, dynamic>;
      final periodStr = map['period'] as String? ?? 'monthly';
      final period = BudgetPeriod.values.firstWhere(
        (p) => p.name == periodStr,
        orElse: () => BudgetPeriod.monthly,
      );

      return Budget(
        id: map['id'] as String,
        name: map['name'] as String,
        amountInCents: (map['amountInCents'] as num).toInt(),
        period: period,
        startDate: DateTime.parse(map['startDate'] as String),
        categoryId: (map['categoryId'] as String?) ?? '',
        rolloverEnabled: (map['rolloverEnabled'] as bool?) ?? false,
      );
    }).toList();

    return BackupPayload(
      schemaVersion: schemaVersion,
      appName: appName,
      appVersion: appVersion,
      createdAt: createdAt,
      categories: categoriesList,
      transactions: transactionsList,
      budgets: budgetsList,
    );
  }

  @override
  String toString() {
    return 'BackupPayload(version: $schemaVersion, created: $createdAt, transactions: ${transactions.length}, categories: ${categories.length}, budgets: ${budgets.length})';
  }
}
