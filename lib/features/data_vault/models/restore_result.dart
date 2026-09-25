/// Strategy for restoring backed up transactions and categories into local storage.
enum RestoreMode {
  /// Clears existing local storage collections and replaces them atomically with backup contents.
  overwrite,

  /// Merges backup transactions and custom categories with existing records, preserving uniqueness.
  merge,
}

/// Comprehensive outcome report for a backup restore operation.
class RestoreResult {
  final bool isSuccess;
  final int restoredTransactionsCount;
  final int restoredCategoriesCount;
  final int restoredBudgetsCount;
  final String message;
  final DateTime timestamp;

  const RestoreResult({
    required this.isSuccess,
    required this.restoredTransactionsCount,
    required this.restoredCategoriesCount,
    this.restoredBudgetsCount = 0,
    required this.message,
    required this.timestamp,
  });

  factory RestoreResult.success({
    required int restoredTransactions,
    required int restoredCategories,
    int restoredBudgets = 0,
    String? message,
  }) {
    return RestoreResult(
      isSuccess: true,
      restoredTransactionsCount: restoredTransactions,
      restoredCategoriesCount: restoredCategories,
      restoredBudgetsCount: restoredBudgets,
      message:
          message ??
          'Successfully restored $restoredTransactions transactions and $restoredCategories categories.',
      timestamp: DateTime.now(),
    );
  }

  factory RestoreResult.failure(String errorMessage) {
    return RestoreResult(
      isSuccess: false,
      restoredTransactionsCount: 0,
      restoredCategoriesCount: 0,
      restoredBudgetsCount: 0,
      message: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RestoreResult(success: $isSuccess, transactions: $restoredTransactionsCount, categories: $restoredCategoriesCount, message: "$message")';
  }
}
