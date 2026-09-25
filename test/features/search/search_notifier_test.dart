import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/search/models/quick_filter_tag.dart';
import 'package:pocketledger/features/search/presentation/providers/search_providers.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';
import 'package:pocketledger/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _storage;
  FakeTransactionRepository(this._storage);

  @override
  Future<List<Transaction>> getTransactions() async =>
      List<Transaction>.from(_storage);

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _storage.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _storage.removeWhere((tx) => tx.id == id);
  }
}

void main() {
  final fixedNow = DateTime(2026, 9, 25, 14, 30, 0); // Friday, Sep 25, 2026

  final sampleTransactions = [
    Transaction(
      id: 'tx-1',
      type: TransactionType.expense,
      amountInCents: 1500, // $15.00
      category: 'food',
      date: DateTime(2026, 9, 20, 9, 30), // Last Sunday
      note: 'Morning Coffee',
      createdAt: fixedNow,
    ),
    Transaction(
      id: 'tx-2',
      type: TransactionType.expense,
      amountInCents: 5000, // $50.00
      category: 'shopping',
      date: DateTime(2026, 9, 22, 14, 15), // Tuesday (This week)
      note: 'Grocery store items',
      createdAt: fixedNow,
    ),
    Transaction(
      id: 'tx-3',
      type: TransactionType.income,
      amountInCents: 250000, // $2,500.00
      category: 'salary',
      date: DateTime(2026, 9, 25, 8, 0), // Today
      note: 'Monthly Salary from Acme',
      createdAt: fixedNow,
    ),
    Transaction(
      id: 'tx-4',
      type: TransactionType.expense,
      amountInCents: 12000, // $120.00
      category: 'bills',
      date: DateTime(2026, 9, 25, 23, 45), // Today
      note: 'Electric utility bill',
      createdAt: fixedNow,
    ),
    Transaction(
      id: 'tx-5',
      type: TransactionType.income,
      amountInCents: 35000, // $350.00
      category: 'freelance',
      date: DateTime(2026, 9, 28, 16, 0), // Next Monday (This month)
      note: 'Mobile app design consulting',
      createdAt: fixedNow,
    ),
  ];

  SearchNotifier createNotifier({
    List<Transaction>? transactions,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) {
    return SearchNotifier(
      initialTransactions: transactions ?? sampleTransactions,
      debounceDuration: debounceDuration,
      nowProvider: () => fixedNow,
    );
  }

  group('SearchNotifier — Riverpod Search State Layer (Day 2)', () {
    group('1. Initial State', () {
      test('initializes with all transactions and default filter values', () {
        final notifier = createNotifier();
        final state = notifier.state;

        expect(state.noteQuery, '');
        expect(state.categoryId, isNull);
        expect(state.startDate, isNull);
        expect(state.endDate, isNull);
        expect(state.minAmount, isNull);
        expect(state.maxAmount, isNull);
        expect(state.transactionType, isNull);
        expect(state.selectedQuickFilters, isEmpty);
        expect(state.filteredTransactions.length, 5);
        expect(state.totalTransactionCount, 5);
        expect(state.hasActiveFilters, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      });
    });

    group('2. Note Query & Debounce Behavior', () {
      test('immediate text search filters synchronously', () {
        final notifier = createNotifier();
        notifier.setNoteQuery('Coffee', immediate: true);

        expect(notifier.state.noteQuery, 'Coffee');
        expect(notifier.state.filteredTransactions.length, 1);
        expect(notifier.state.filteredTransactions.first.id, 'tx-1');
        expect(notifier.state.isLoading, isFalse);
      });

      test('debounces search and cancels previous pending query', () async {
        final notifier = createNotifier(
          debounceDuration: const Duration(milliseconds: 60),
        );

        // User types 'C'
        notifier.setNoteQuery('C');
        expect(notifier.state.isLoading, isTrue);
        expect(
          notifier.state.filteredTransactions.length,
          5,
        ); // not yet filtered

        // 20ms later, user types 'Co'
        await Future.delayed(const Duration(milliseconds: 20));
        notifier.setNoteQuery('Co');
        expect(notifier.state.isLoading, isTrue);
        expect(notifier.state.filteredTransactions.length, 5);

        // 20ms later, user types 'Coffee' (cancelling 'Co' timer)
        await Future.delayed(const Duration(milliseconds: 20));
        notifier.setNoteQuery('Coffee');
        expect(notifier.state.isLoading, isTrue);
        expect(notifier.state.filteredTransactions.length, 5);

        // 30ms elapsed (total 30ms since 'Coffee', debounce is 60ms)
        await Future.delayed(const Duration(milliseconds: 30));
        expect(notifier.state.isLoading, isTrue);
        expect(notifier.state.filteredTransactions.length, 5);

        // 45ms more (total > 60ms reached since 'Coffee')
        await Future.delayed(const Duration(milliseconds: 45));
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.filteredTransactions.length, 1);
        expect(notifier.state.filteredTransactions.first.id, 'tx-1');
      });

      test('clearing note query resets text search immediately', () {
        final notifier = createNotifier();
        notifier.setNoteQuery('Coffee', immediate: true);
        expect(notifier.state.filteredTransactions.length, 1);

        notifier.clearNoteQuery();
        expect(notifier.state.noteQuery, '');
        expect(notifier.state.filteredTransactions.length, 5);
        expect(notifier.state.hasActiveFilters, isFalse);
      });
    });

    group('3. Category Filter', () {
      test('filters by category ID and clears correctly', () {
        final notifier = createNotifier();
        notifier.setCategory('salary');

        expect(notifier.state.categoryId, 'salary');
        expect(notifier.state.filteredTransactions.length, 1);
        expect(notifier.state.filteredTransactions.first.id, 'tx-3');

        notifier.clearCategory();
        expect(notifier.state.categoryId, isNull);
        expect(notifier.state.filteredTransactions.length, 5);
      });
    });

    group('4. Amount Filter', () {
      test('filters by minimum, maximum, and amount range', () {
        final notifier = createNotifier();

        // Min amount $50 -> tx-2 ($50), tx-3 ($2500), tx-4 ($120), tx-5 ($350)
        notifier.setMinAmount(50.0);
        expect(notifier.state.filteredTransactions.length, 4);

        // Max amount $200 -> tx-2 ($50), tx-4 ($120)
        notifier.setMaxAmount(200.0);
        expect(notifier.state.filteredTransactions.length, 2);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-2',
          'tx-4',
        ]);

        // Clear amount range
        notifier.clearAmountRange();
        expect(notifier.state.minAmount, isNull);
        expect(notifier.state.maxAmount, isNull);
        expect(notifier.state.filteredTransactions.length, 5);
      });
    });

    group('5. Date Filter', () {
      test('filters by inclusive date range and clears correctly', () {
        final notifier = createNotifier();

        // Date range: Sep 22 to Sep 25 -> tx-2, tx-3, tx-4
        notifier.setDateRange(DateTime(2026, 9, 22), DateTime(2026, 9, 25));
        expect(notifier.state.filteredTransactions.length, 3);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-2',
          'tx-3',
          'tx-4',
        ]);

        notifier.clearDateRange();
        expect(notifier.state.startDate, isNull);
        expect(notifier.state.endDate, isNull);
        expect(notifier.state.filteredTransactions.length, 5);
      });
    });

    group('6. Transaction Type Filter', () {
      test('filters by income and expense types', () {
        final notifier = createNotifier();

        notifier.setTransactionType(TransactionType.income);
        expect(notifier.state.transactionType, TransactionType.income);
        expect(notifier.state.filteredTransactions.length, 2);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-3',
          'tx-5',
        ]);

        notifier.setTransactionType(TransactionType.expense);
        expect(notifier.state.filteredTransactions.length, 3);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-1',
          'tx-2',
          'tx-4',
        ]);

        notifier.clearTransactionType();
        expect(notifier.state.transactionType, isNull);
        expect(notifier.state.filteredTransactions.length, 5);
      });
    });

    group('7. Quick Filters & Multi-Tag Selection', () {
      test('toggling Income quick filter filters results', () {
        final notifier = createNotifier();
        notifier.toggleQuickFilter(QuickFilterTag.income);

        expect(
          notifier.state.selectedQuickFilters,
          contains(QuickFilterTag.income),
        );
        expect(notifier.state.filteredTransactions.length, 2);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-3',
          'tx-5',
        ]);
      });

      test('switching between Income and Expense is mutually exclusive', () {
        final notifier = createNotifier();
        notifier.toggleQuickFilter(QuickFilterTag.income);
        expect(
          notifier.state.selectedQuickFilters,
          contains(QuickFilterTag.income),
        );

        notifier.toggleQuickFilter(QuickFilterTag.expense);
        expect(
          notifier.state.selectedQuickFilters,
          contains(QuickFilterTag.expense),
        );
        expect(
          notifier.state.selectedQuickFilters,
          isNot(contains(QuickFilterTag.income)),
        );
        expect(notifier.state.filteredTransactions.length, 3);
      });

      test('Today quick filter returns transactions on the current day', () {
        final notifier = createNotifier();
        notifier.toggleQuickFilter(QuickFilterTag.today);

        // Sep 25 transactions: tx-3 (Salary), tx-4 (Bills)
        expect(notifier.state.filteredTransactions.length, 2);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-3',
          'tx-4',
        ]);
      });

      test('This Week quick filter returns transactions within the week', () {
        final notifier = createNotifier();
        notifier.toggleQuickFilter(QuickFilterTag.thisWeek);

        // Sep 21 to Sep 27: tx-2 (Sep 22), tx-3 (Sep 25), tx-4 (Sep 25)
        expect(notifier.state.filteredTransactions.length, 3);
        expect(notifier.state.filteredTransactions.map((e) => e.id).toList(), [
          'tx-2',
          'tx-3',
          'tx-4',
        ]);
      });

      test('This Month quick filter returns transactions in September', () {
        final notifier = createNotifier();
        notifier.toggleQuickFilter(QuickFilterTag.thisMonth);

        // All 5 transactions are in September 2026
        expect(notifier.state.filteredTransactions.length, 5);
      });

      test(
        'combines multiple quick filter tags (e.g. Expense + Today) with AND logic',
        () {
          final notifier = createNotifier();
          notifier.toggleQuickFilter(QuickFilterTag.expense);
          notifier.toggleQuickFilter(QuickFilterTag.today);

          // Expense on Sep 25 -> tx-4 ($120 Bills)
          expect(notifier.state.selectedQuickFilters, {
            QuickFilterTag.expense,
            QuickFilterTag.today,
          });
          expect(notifier.state.filteredTransactions.length, 1);
          expect(notifier.state.filteredTransactions.first.id, 'tx-4');
        },
      );

      test('clearing quick filters restores full list', () {
        final notifier = createNotifier();
        notifier.toggleQuickFilter(QuickFilterTag.expense);
        notifier.toggleQuickFilter(QuickFilterTag.today);
        expect(notifier.state.filteredTransactions.length, 1);

        notifier.clearQuickFilters();
        expect(notifier.state.selectedQuickFilters, isEmpty);
        expect(notifier.state.filteredTransactions.length, 5);
      });
    });

    group('8. Multi-Parameter Combination & Clear All', () {
      test(
        'combines note query, category, and quick filter with AND logic',
        () {
          final notifier = createNotifier();
          notifier.setNoteQuery('utility', immediate: true);
          notifier.setCategory('bills');
          notifier.toggleQuickFilter(QuickFilterTag.expense);

          expect(notifier.state.filteredTransactions.length, 1);
          expect(notifier.state.filteredTransactions.first.id, 'tx-4');
        },
      );

      test('clearAllFilters restores initial full state completely', () {
        final notifier = createNotifier();
        notifier.setNoteQuery('Acme', immediate: true);
        notifier.setCategory('salary');
        notifier.setMinAmount(2000.0);
        notifier.toggleQuickFilter(QuickFilterTag.income);
        expect(notifier.state.filteredTransactions.length, 1);
        expect(notifier.state.hasActiveFilters, isTrue);

        notifier.clearAllFilters();
        expect(notifier.state.noteQuery, '');
        expect(notifier.state.categoryId, isNull);
        expect(notifier.state.minAmount, isNull);
        expect(notifier.state.selectedQuickFilters, isEmpty);
        expect(notifier.state.hasActiveFilters, isFalse);
        expect(notifier.state.filteredTransactions.length, 5);
      });

      test(
        'returns empty results when no transaction matches all criteria',
        () {
          final notifier = createNotifier();
          notifier.setNoteQuery('NonExistentNote', immediate: true);
          expect(notifier.state.filteredTransactions, isEmpty);
          expect(notifier.state.matchCount, 0);
        },
      );
    });

    group('9. Riverpod Container Integration & Reactivity', () {
      test(
        'SearchNotifier reacts to transactionListProvider updates in ProviderContainer',
        () async {
          final fakeRepo = FakeTransactionRepository([
            Transaction(
              id: 'tx-1',
              type: TransactionType.expense,
              amountInCents: 1500,
              category: 'food',
              date: DateTime(2026, 9, 20),
              note: 'Coffee',
              createdAt: fixedNow,
            ),
          ]);

          final container = ProviderContainer(
            overrides: [
              transactionRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          );

          // Read notifier and wait for initial async load
          container.read(searchNotifierProvider);
          await pumpEventQueue();

          final searchState = container.read(searchNotifierProvider);
          expect(searchState.totalTransactionCount, 1);
          expect(searchState.filteredTransactions.length, 1);

          // Add transaction to underlying repository and notifier
          await container
              .read(transactionListProvider.notifier)
              .addTransaction(
                Transaction(
                  id: 'tx-2',
                  type: TransactionType.income,
                  amountInCents: 50000,
                  category: 'salary',
                  date: DateTime(2026, 9, 25),
                  note: 'Salary',
                  createdAt: fixedNow,
                ),
              );

          // Verify search state automatically updated
          final updatedSearchState = container.read(searchNotifierProvider);
          expect(updatedSearchState.totalTransactionCount, 2);
          expect(updatedSearchState.filteredTransactions.length, 2);

          // Verify granular selectors
          expect(container.read(searchResultsProvider).length, 2);
          expect(container.read(searchMatchCountProvider), 2);
          expect(container.read(searchTotalCountProvider), 2);
          expect(container.read(searchHasActiveFiltersProvider), isFalse);

          container.dispose();
        },
      );
    });
  });
}
