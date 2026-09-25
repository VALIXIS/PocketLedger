import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../models/quick_filter_tag.dart';
import '../../models/search_state.dart';
import '../../services/transaction_search_service.dart';

/// Provider for the stateless [TransactionSearchService] engine.
final searchServiceProvider = Provider<TransactionSearchService>((ref) {
  return const TransactionSearchService();
});

/// StateNotifier managing transaction search state, debounced text search,
/// multi-parameter filtering, and quick tags.
class SearchNotifier extends StateNotifier<SearchState> {
  final Ref? ref;
  final TransactionSearchService searchService;
  final Duration debounceDuration;
  final DateTime Function() _nowProvider;
  Timer? _debounceTimer;
  List<Transaction> _sourceTransactions = const [];

  SearchNotifier({
    this.ref,
    List<Transaction>? initialTransactions,
    this.searchService = const TransactionSearchService(),
    this.debounceDuration = const Duration(milliseconds: 300),
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now,
       super(const SearchState()) {
    if (initialTransactions != null) {
      _sourceTransactions = initialTransactions;
      _applySearchImmediately();
    }

    final currentRef = ref;
    if (currentRef != null) {
      currentRef.listen<AsyncValue<List<Transaction>>>(transactionListProvider, (
        previous,
        next,
      ) {
        _onTransactionListUpdated(next);
      }, fireImmediately: true);
    }
  }

  void _onTransactionListUpdated(AsyncValue<List<Transaction>> next) {
    next.when(
      data: (transactions) {
        _sourceTransactions = transactions;
        _applySearchImmediately();
      },
      loading: () {
        if (_sourceTransactions.isEmpty) {
          state = state.copyWith(isLoading: true, clearErrorMessage: true);
        }
      },
      error: (err, stack) {
        state = state.copyWith(isLoading: false, errorMessage: err.toString());
      },
    );
  }

  /// Manually set source transactions (useful for isolated unit testing).
  void setSourceTransactions(List<Transaction> transactions) {
    _sourceTransactions = transactions;
    _applySearchImmediately();
  }

  /// Updates the note query string with debounced execution.
  ///
  /// Set [immediate] to `true` to bypass the 300ms debounce (e.g. on submit or clear).
  void setNoteQuery(String query, {bool immediate = false}) {
    _debounceTimer?.cancel();

    if (immediate || query.trim().isEmpty) {
      state = state.copyWith(noteQuery: query);
      _applySearchImmediately();
      return;
    }

    state = state.copyWith(noteQuery: query, isLoading: true);

    _debounceTimer = Timer(debounceDuration, () {
      _applySearchImmediately();
    });
  }

  /// Updates category ID filter.
  void setCategory(String? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategoryId: categoryId == null || categoryId.trim().isEmpty,
    );
    _applySearchImmediately();
  }

  /// Updates inclusive date boundaries.
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      clearStartDate: startDate == null,
      clearEndDate: endDate == null,
    );
    _applySearchImmediately();
  }

  /// Updates inclusive start date.
  void setStartDate(DateTime? startDate) {
    state = state.copyWith(
      startDate: startDate,
      clearStartDate: startDate == null,
    );
    _applySearchImmediately();
  }

  /// Updates inclusive end date.
  void setEndDate(DateTime? endDate) {
    state = state.copyWith(endDate: endDate, clearEndDate: endDate == null);
    _applySearchImmediately();
  }

  /// Updates inclusive amount boundaries.
  void setAmountRange({double? minAmount, double? maxAmount}) {
    state = state.copyWith(
      minAmount: minAmount,
      maxAmount: maxAmount,
      clearMinAmount: minAmount == null,
      clearMaxAmount: maxAmount == null,
    );
    _applySearchImmediately();
  }

  /// Updates inclusive minimum amount.
  void setMinAmount(double? minAmount) {
    state = state.copyWith(
      minAmount: minAmount,
      clearMinAmount: minAmount == null,
    );
    _applySearchImmediately();
  }

  /// Updates inclusive maximum amount.
  void setMaxAmount(double? maxAmount) {
    state = state.copyWith(
      maxAmount: maxAmount,
      clearMaxAmount: maxAmount == null,
    );
    _applySearchImmediately();
  }

  /// Updates exact transaction type.
  void setTransactionType(TransactionType? type) {
    state = state.copyWith(
      transactionType: type,
      clearTransactionType: type == null,
    );
    _applySearchImmediately();
  }

  /// Toggles a quick filter tag on or off.
  ///
  /// Enforces mutual exclusivity within type tags (Income vs Expense) and date tags (Today vs This Week vs This Month).
  void toggleQuickFilter(QuickFilterTag tag) {
    final currentTags = Set<QuickFilterTag>.from(state.selectedQuickFilters);

    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      if (tag == QuickFilterTag.income) {
        currentTags.remove(QuickFilterTag.expense);
      } else if (tag == QuickFilterTag.expense) {
        currentTags.remove(QuickFilterTag.income);
      }

      if (tag.isDateTag) {
        currentTags.removeWhere((t) => t.isDateTag);
      }

      currentTags.add(tag);
    }

    state = state.copyWith(selectedQuickFilters: currentTags);
    _applySearchImmediately();
  }

  /// Explicitly selects a quick filter tag.
  void selectQuickFilter(QuickFilterTag tag) {
    if (!state.selectedQuickFilters.contains(tag)) {
      toggleQuickFilter(tag);
    }
  }

  /// Explicitly removes a quick filter tag.
  void removeQuickFilter(QuickFilterTag tag) {
    if (state.selectedQuickFilters.contains(tag)) {
      toggleQuickFilter(tag);
    }
  }

  /// Clears active note query string immediately.
  void clearNoteQuery() {
    _debounceTimer?.cancel();
    state = state.copyWith(noteQuery: '');
    _applySearchImmediately();
  }

  /// Clears active category filter.
  void clearCategory() {
    state = state.copyWith(clearCategoryId: true);
    _applySearchImmediately();
  }

  /// Clears active date range filter and any date quick filter tags.
  void clearDateRange() {
    final updatedTags = state.selectedQuickFilters
        .where((t) => !t.isDateTag)
        .toSet();
    state = state.copyWith(
      clearStartDate: true,
      clearEndDate: true,
      selectedQuickFilters: updatedTags,
    );
    _applySearchImmediately();
  }

  /// Clears active amount range filter.
  void clearAmountRange() {
    state = state.copyWith(clearMinAmount: true, clearMaxAmount: true);
    _applySearchImmediately();
  }

  /// Clears active transaction type filter and any type quick filter tags.
  void clearTransactionType() {
    final updatedTags = state.selectedQuickFilters
        .where((t) => !t.isTypeTag)
        .toSet();
    state = state.copyWith(
      clearTransactionType: true,
      selectedQuickFilters: updatedTags,
    );
    _applySearchImmediately();
  }

  /// Clears all quick filter tags.
  void clearQuickFilters() {
    state = state.copyWith(selectedQuickFilters: const {});
    _applySearchImmediately();
  }

  /// Resets all search parameters, debounces, and filters, restoring the complete transaction list.
  void clearAllFilters() {
    _debounceTimer?.cancel();
    state = SearchState(
      noteQuery: '',
      totalTransactionCount: _sourceTransactions.length,
      filteredTransactions: List.unmodifiable(_sourceTransactions),
      isLoading: false,
    );
  }

  /// Applies active filters against current source transactions synchronously.
  void _applySearchImmediately() {
    _debounceTimer?.cancel();
    try {
      final filter = state.toFilter(referenceDate: _nowProvider());
      final results = searchService.filter(_sourceTransactions, filter);
      state = state.copyWith(
        filteredTransactions: results,
        totalTransactionCount: _sourceTransactions.length,
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Main StateNotifierProvider for transaction search and filtering state.
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      final searchService = ref.watch(searchServiceProvider);
      return SearchNotifier(ref: ref, searchService: searchService);
    });

/// Granular provider for current filtered transaction results.
final searchResultsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(
    searchNotifierProvider.select((s) => s.filteredTransactions),
  );
});

/// Granular provider for matching results count.
final searchMatchCountProvider = Provider<int>((ref) {
  return ref.watch(searchNotifierProvider.select((s) => s.matchCount));
});

/// Granular provider for total transactions count.
final searchTotalCountProvider = Provider<int>((ref) {
  return ref.watch(
    searchNotifierProvider.select((s) => s.totalTransactionCount),
  );
});

/// Granular provider indicating whether any active filters are applied.
final searchHasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(searchNotifierProvider.select((s) => s.hasActiveFilters));
});

/// Granular provider indicating search loading / debounce status.
final searchIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(searchNotifierProvider.select((s) => s.isLoading));
});

/// Granular provider for currently active quick filter tags.
final searchQuickFiltersProvider = Provider<Set<QuickFilterTag>>((ref) {
  return ref.watch(
    searchNotifierProvider.select((s) => s.selectedQuickFilters),
  );
});
