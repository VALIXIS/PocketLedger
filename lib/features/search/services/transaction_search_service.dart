import '../../transactions/domain/models/transaction.dart';
import '../../transactions/domain/models/transaction_type.dart';
import '../models/transaction_search_filter.dart';

/// Production-ready engine for filtering and searching [Transaction] records
/// across multiple parameters using deterministic AND logic.
class TransactionSearchService {
  const TransactionSearchService();

  /// Filters [transactions] based on criteria specified in [filter] or individual optional parameters.
  ///
  /// Individual parameters take precedence over corresponding fields in [filter] if both are provided.
  ///
  /// Filtering rules:
  /// - [query]: Case-insensitive substring match against transaction note, whitespace-trimmed.
  /// - [categoryId]: Exact match against transaction category ID, whitespace-trimmed.
  /// - [startDate]: Inclusive date boundary (start of day: 00:00:00.000).
  /// - [endDate]: Inclusive date boundary (end of day: 23:59:59.999999).
  /// - [minAmount] / [minAmountInCents]: Inclusive minimum amount.
  /// - [maxAmount] / [maxAmountInCents]: Inclusive maximum amount.
  /// - [type]: Exact match against transaction type ([TransactionType.income] / [TransactionType.expense]).
  /// - If any filter criteria is null or empty string, that filter is ignored.
  /// - If multiple filters are provided, they are combined with AND logic.
  /// - The original [transactions] list is never mutated.
  /// - Returns a non-null [List<Transaction>], returning an empty list if no matches are found.
  List<Transaction> search(
    List<Transaction> transactions, {
    TransactionSearchFilter? filter,
    String? query,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int? minAmountInCents,
    int? maxAmountInCents,
    TransactionType? type,
  }) {
    if (transactions.isEmpty) {
      return const [];
    }

    final effectiveQuery = query ?? filter?.query;
    final effectiveCategoryId = categoryId ?? filter?.categoryId;
    final effectiveStartDate = startDate ?? filter?.startDate;
    final effectiveEndDate = endDate ?? filter?.endDate;
    final effectiveMinAmount = minAmount ?? filter?.minAmount;
    final effectiveMaxAmount = maxAmount ?? filter?.maxAmount;
    final effectiveMinAmountInCents =
        minAmountInCents ?? filter?.minAmountInCents;
    final effectiveMaxAmountInCents =
        maxAmountInCents ?? filter?.maxAmountInCents;
    final effectiveType = type ?? filter?.type;

    // Note query filter prep
    final String? trimmedQuery = effectiveQuery?.trim().toLowerCase();
    final bool applyQueryFilter =
        trimmedQuery != null && trimmedQuery.isNotEmpty;

    // Category filter prep
    final String? trimmedCategory = effectiveCategoryId?.trim();
    final bool applyCategoryFilter =
        trimmedCategory != null && trimmedCategory.isNotEmpty;

    // Date range filter prep
    DateTime? normStart;
    DateTime? normEnd;

    if (effectiveStartDate != null) {
      normStart = DateTime(
        effectiveStartDate.year,
        effectiveStartDate.month,
        effectiveStartDate.day,
        0,
        0,
        0,
        0,
        0,
      );
    }

    if (effectiveEndDate != null) {
      normEnd = DateTime(
        effectiveEndDate.year,
        effectiveEndDate.month,
        effectiveEndDate.day,
        23,
        59,
        59,
        999,
        999,
      );
    }

    // If normalized start date is after end date, no transaction can match
    if (normStart != null && normEnd != null && normStart.isAfter(normEnd)) {
      return const [];
    }

    // Amount range filter prep (converted safely to integer cents)
    final int? resolvedMinCents =
        effectiveMinAmountInCents ??
        (effectiveMinAmount != null
            ? Transaction.doubleToCents(effectiveMinAmount)
            : null);

    final int? resolvedMaxCents =
        effectiveMaxAmountInCents ??
        (effectiveMaxAmount != null
            ? Transaction.doubleToCents(effectiveMaxAmount)
            : null);

    // If min amount exceeds max amount, no transaction can match
    if (resolvedMinCents != null &&
        resolvedMaxCents != null &&
        resolvedMinCents > resolvedMaxCents) {
      return const [];
    }

    // Filter using AND logic across all active criteria
    return transactions.where((tx) {
      // 1. Note text query (case-insensitive substring match)
      if (applyQueryFilter) {
        if (!tx.note.toLowerCase().contains(trimmedQuery)) {
          return false;
        }
      }

      // 2. Category ID exact match
      if (applyCategoryFilter) {
        if (tx.category != trimmedCategory) {
          return false;
        }
      }

      // 3. Inclusive Start Date
      if (normStart != null && tx.date.isBefore(normStart)) {
        return false;
      }

      // 4. Inclusive End Date
      if (normEnd != null && tx.date.isAfter(normEnd)) {
        return false;
      }

      // 5. Inclusive Minimum Amount
      if (resolvedMinCents != null && tx.amountInCents < resolvedMinCents) {
        return false;
      }

      // 6. Inclusive Maximum Amount
      if (resolvedMaxCents != null && tx.amountInCents > resolvedMaxCents) {
        return false;
      }

      // 7. Exact Transaction Type
      if (effectiveType != null && tx.type != effectiveType) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Convenience method to filter transactions using a [TransactionSearchFilter] object.
  List<Transaction> filter(
    List<Transaction> transactions,
    TransactionSearchFilter filter,
  ) {
    return search(transactions, filter: filter);
  }

  /// Static helper for quick filtering without instantiating the service.
  static List<Transaction> filterTransactions(
    List<Transaction> transactions, {
    TransactionSearchFilter? filter,
    String? query,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int? minAmountInCents,
    int? maxAmountInCents,
    TransactionType? type,
  }) {
    return const TransactionSearchService().search(
      transactions,
      filter: filter,
      query: query,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      minAmountInCents: minAmountInCents,
      maxAmountInCents: maxAmountInCents,
      type: type,
    );
  }
}
