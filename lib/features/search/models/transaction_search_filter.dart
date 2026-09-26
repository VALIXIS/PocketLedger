import '../../transactions/domain/models/transaction_type.dart';

/// Immutable filter criteria model for searching and filtering transactions.
///
/// Supports note text search, category filtering, inclusive date range,
/// inclusive amount range, and transaction type matching.
class TransactionSearchFilter {
  /// Note text query (case-insensitive substring match).
  final String? query;

  /// Exact category ID to match.
  final String? categoryId;

  /// Inclusive start date for the transaction date range.
  final DateTime? startDate;

  /// Inclusive end date for the transaction date range.
  final DateTime? endDate;

  /// Inclusive minimum amount in main currency units (e.g., dollars/rupees).
  final double? minAmount;

  /// Inclusive maximum amount in main currency units (e.g., dollars/rupees).
  final double? maxAmount;

  /// Inclusive minimum amount in integer cents.
  final int? minAmountInCents;

  /// Inclusive maximum amount in integer cents.
  final int? maxAmountInCents;

  /// Exact transaction type (income or expense).
  final TransactionType? type;

  const TransactionSearchFilter({
    this.query,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.minAmountInCents,
    this.maxAmountInCents,
    this.type,
  });

  /// An empty filter representing no active search/filtering constraints.
  static const empty = TransactionSearchFilter();

  /// Returns `true` if all filter fields are null or whitespace-empty.
  bool get isEmpty {
    final hasQuery = query != null && query!.trim().isNotEmpty;
    final hasCategory = categoryId != null && categoryId!.trim().isNotEmpty;
    final hasStartDate = startDate != null;
    final hasEndDate = endDate != null;
    final hasMinAmount = minAmount != null || minAmountInCents != null;
    final hasMaxAmount = maxAmount != null || maxAmountInCents != null;
    final hasType = type != null;

    return !hasQuery &&
        !hasCategory &&
        !hasStartDate &&
        !hasEndDate &&
        !hasMinAmount &&
        !hasMaxAmount &&
        !hasType;
  }

  /// Returns `true` if at least one filter field is actively set.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this filter with the given fields replaced.
  TransactionSearchFilter copyWith({
    String? query,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int? minAmountInCents,
    int? maxAmountInCents,
    TransactionType? type,
    bool clearQuery = false,
    bool clearCategory = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearType = false,
  }) {
    return TransactionSearchFilter(
      query: clearQuery ? null : (query ?? this.query),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      minAmountInCents: clearMinAmount
          ? null
          : (minAmountInCents ?? this.minAmountInCents),
      maxAmountInCents: clearMaxAmount
          ? null
          : (maxAmountInCents ?? this.maxAmountInCents),
      type: clearType ? null : (type ?? this.type),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionSearchFilter &&
        other.query == query &&
        other.categoryId == categoryId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.minAmountInCents == minAmountInCents &&
        other.maxAmountInCents == maxAmountInCents &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(
    query,
    categoryId,
    startDate,
    endDate,
    minAmount,
    maxAmount,
    minAmountInCents,
    maxAmountInCents,
    type,
  );

  @override
  String toString() {
    return 'TransactionSearchFilter('
        'query: $query, '
        'categoryId: $categoryId, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'minAmount: $minAmount, '
        'maxAmount: $maxAmount, '
        'minAmountInCents: $minAmountInCents, '
        'maxAmountInCents: $maxAmountInCents, '
        'type: $type'
        ')';
  }
}
