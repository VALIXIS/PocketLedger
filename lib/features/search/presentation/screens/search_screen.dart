import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_sort_option.dart';
import '../providers/search_providers.dart';
import '../widgets/quick_filter_chips_bar.dart';
import '../widgets/search_empty_state.dart';
import '../widgets/search_transaction_card.dart';
import '../widgets/transaction_filter_bottom_sheet.dart';

/// Production-ready Search & Multi-Parameter Filter Screen.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchNotifierProvider).noteQuery;
    _searchController = TextEditingController(text: initialQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(searchNotifierProvider.notifier).setNoteQuery(value);
  }

  void _clearQuery() {
    _searchController.clear();
    ref.read(searchNotifierProvider.notifier).clearNoteQuery();
  }

  void _openFilterBottomSheet() {
    TransactionFilterBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final searchState = ref.watch(searchNotifierProvider);
    final results = searchState.filteredTransactions;
    final hasActiveFilters = searchState.hasActiveFilters;
    final isLoading = searchState.isLoading;
    final currentSort = searchState.sortOption;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transactions'),
        centerTitle: true,
        actions: [
          // Filter button with active indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter Options',
                onPressed: _openFilterBottomSheet,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Sorting Dropdown / Popup Menu
          PopupMenuButton<TransactionSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Results',
            initialValue: currentSort,
            onSelected: (option) {
              ref.read(searchNotifierProvider.notifier).setSortOption(option);
            },
            itemBuilder: (context) => TransactionSortOption.values.map((
              option,
            ) {
              return PopupMenuItem<TransactionSortOption>(
                value: option,
                child: Row(
                  children: [
                    if (option == currentSort)
                      Icon(Icons.check, size: 18, color: colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search by note text...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear query',
                          onPressed: _clearQuery,
                        )
                      : null,
                ),
              ),
            ),

            // 2. Multi-Tag Quick Filter Chips Bar
            const QuickFilterChipsBar(),

            // 3. Search Results Count Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasActiveFilters
                        ? '${results.length} of ${searchState.totalTransactionCount} transactions found'
                        : '${results.length} transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (hasActiveFilters)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(searchNotifierProvider.notifier)
                            .clearAllFilters();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        'Clear Filters',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // 4. Transaction Results or Empty State
            Expanded(
              child: results.isEmpty
                  ? SearchEmptyState(
                      hasActiveFilters: hasActiveFilters,
                      onClearFilters: () {
                        _searchController.clear();
                        ref
                            .read(searchNotifierProvider.notifier)
                            .clearAllFilters();
                      },
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      padding: const EdgeInsets.only(bottom: 24, top: 4),
                      itemBuilder: (context, index) {
                        return SearchTransactionCard(
                          transaction: results[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
