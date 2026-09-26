import 'package:flutter/foundation.dart';
import '../../transactions/domain/models/transaction.dart';
import '../../transactions/domain/models/transaction_type.dart';
import 'quick_filter_tag.dart';
import 'transaction_search_filter.dart';
import 'transaction_sort_option.dart';

/// Immutable state representation for transaction search, multi-parameter filtering, and sorting.
@immutable
class SearchState {
  /// Active text query to search within transaction notes.
  final String noteQuery;

  /// Selected category identifier.
  final String? categoryId;

  /// Inclusive start date boundary.
  final DateTime? startDate;

  /// Inclusive end date boundary.
  final DateTime? endDate;

  /// Inclusive minimum amount in currency units.
  final double? minAmount;

  /// Inclusive maximum amount in currency units.
  final double? maxAmount;

  /// Filter for exact transaction type (income / expense).
  final TransactionType? transactionType;

  /// Set of currently selected quick filter tags.
  final Set<QuickFilterTag> selectedQuickFilters;

  /// Optional sorting strategy for search results.
  final TransactionSortOption? sortOption;

  /// Filtered list of transactions matching all active criteria.
  final List<Transaction> filteredTransactions;

  /// Total number of transactions available in data source before filtering.
  final int totalTransactionCount;

  /// True when a debounced search or data load is actively in progress.
  final bool isLoading;

  /// Non-null error message if an error occurred during search or data loading.
  final String? errorMessage;

  const SearchState({
    this.noteQuery = '',
    this.categoryId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.transactionType,
    this.selectedQuickFilters = const {},
    this.sortOption,
    this.filteredTransactions = const [],
    this.totalTransactionCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Returns `true` if any search query, category, date, amount, type, quick-filter, or sort is active.
  bool get hasActiveFilters {
    return noteQuery.trim().isNotEmpty ||
        (categoryId != null && categoryId!.trim().isNotEmpty) ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        transactionType != null ||
        selectedQuickFilters.isNotEmpty;
  }

  /// Total count of transactions currently matching active search criteria.
  int get matchCount => filteredTransactions.length;

  /// Resolves the current state and quick filter tags into a unified [TransactionSearchFilter].
  TransactionSearchFilter toFilter({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();

    // Resolve TransactionType: explicit parameter takes priority, otherwise check quick tags
    TransactionType? resolvedType = transactionType;
    if (resolvedType == null) {
      if (selectedQuickFilters.contains(QuickFilterTag.income) &&
          !selectedQuickFilters.contains(QuickFilterTag.expense)) {
        resolvedType = TransactionType.income;
      } else if (selectedQuickFilters.contains(QuickFilterTag.expense) &&
          !selectedQuickFilters.contains(QuickFilterTag.income)) {
        resolvedType = TransactionType.expense;
      }
    }

    // Resolve Date Boundaries: explicit dates take priority, otherwise check quick tags
    DateTime? resolvedStart = startDate;
    DateTime? resolvedEnd = endDate;

    if (resolvedStart == null && resolvedEnd == null) {
      if (selectedQuickFilters.contains(QuickFilterTag.today)) {
        resolvedStart = DateTime(now.year, now.month, now.day);
        resolvedEnd = DateTime(now.year, now.month, now.day);
      } else if (selectedQuickFilters.contains(QuickFilterTag.thisWeek)) {
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        resolvedStart = startOfWeek;
        resolvedEnd = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + 6,
        );
      } else if (selectedQuickFilters.contains(QuickFilterTag.thisMonth)) {
        resolvedStart = DateTime(now.year, now.month, 1);
        resolvedEnd = DateTime(now.year, now.month + 1, 0);
      }
    }

    return TransactionSearchFilter(
      query: noteQuery.trim().isEmpty ? null : noteQuery,
      categoryId: categoryId?.trim().isEmpty == true ? null : categoryId,
      startDate: resolvedStart,
      endDate: resolvedEnd,
      minAmount: minAmount,
      maxAmount: maxAmount,
      type: resolvedType,
    );
  }

  /// Creates a copy of this [SearchState] with the given fields replaced.
  SearchState copyWith({
    String? noteQuery,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    TransactionType? transactionType,
    Set<QuickFilterTag>? selectedQuickFilters,
    TransactionSortOption? sortOption,
    List<Transaction>? filteredTransactions,
    int? totalTransactionCount,
    bool? isLoading,
    String? errorMessage,
    bool clearCategoryId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearTransactionType = false,
    bool clearSortOption = false,
    bool clearErrorMessage = false,
  }) {
    return SearchState(
      noteQuery: noteQuery ?? this.noteQuery,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      selectedQuickFilters: selectedQuickFilters ?? this.selectedQuickFilters,
      sortOption: clearSortOption ? null : (sortOption ?? this.sortOption),
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      totalTransactionCount:
          totalTransactionCount ?? this.totalTransactionCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchState &&
        other.noteQuery == noteQuery &&
        other.categoryId == categoryId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.transactionType == transactionType &&
        setEquals(other.selectedQuickFilters, selectedQuickFilters) &&
        other.sortOption == sortOption &&
        listEquals(other.filteredTransactions, filteredTransactions) &&
        other.totalTransactionCount == totalTransactionCount &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    noteQuery,
    categoryId,
    startDate,
    endDate,
    minAmount,
    maxAmount,
    transactionType,
    Object.hashAll(selectedQuickFilters),
    sortOption,
    Object.hashAll(filteredTransactions),
    totalTransactionCount,
    isLoading,
    errorMessage,
  );

  @override
  String toString() {
    return 'SearchState('
        'query: "$noteQuery", '
        'categoryId: $categoryId, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'minAmount: $minAmount, '
        'maxAmount: $maxAmount, '
        'type: $transactionType, '
        'quickFilters: $selectedQuickFilters, '
        'sortOption: $sortOption, '
        'results: ${filteredTransactions.length}/$totalTransactionCount, '
        'isLoading: $isLoading, '
        'error: $errorMessage'
        ')';
  }
}
