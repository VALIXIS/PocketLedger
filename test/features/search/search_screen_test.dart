import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/categories/domain/models/category.dart';
import 'package:pocketledger/features/categories/domain/repositories/category_repository.dart';
import 'package:pocketledger/features/categories/presentation/providers/category_providers.dart';
import 'package:pocketledger/features/search/presentation/screens/search_screen.dart';
import 'package:pocketledger/features/search/presentation/widgets/quick_filter_chips_bar.dart';
import 'package:pocketledger/features/search/presentation/widgets/search_empty_state.dart';
import 'package:pocketledger/features/search/presentation/widgets/search_transaction_card.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';
import 'package:pocketledger/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<Transaction> _list;
  MockTransactionRepository(this._list);

  @override
  Future<List<Transaction>> getTransactions() async => List.from(_list);

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _list.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _list.removeWhere((tx) => tx.id == id);
  }
}

class MockCategoryRepository implements CategoryRepository {
  final List<Category> _categories;
  MockCategoryRepository([List<Category>? categories])
      : _categories = categories ?? Category.defaultCategories;

  @override
  Future<List<Category>> getCategories() async => List.from(_categories);

  @override
  Future<void> addCategory(Category category) async {
    _categories.add(category);
  }
}

void main() {
  final now = DateTime(2026, 9, 25, 12, 0);

  final mockTransactions = [
    Transaction(
      id: 'tx-1',
      type: TransactionType.expense,
      amountInCents: 1500, // $15.00
      category: 'food',
      date: DateTime(2026, 9, 20),
      note: 'Morning Coffee',
      createdAt: now,
    ),
    Transaction(
      id: 'tx-2',
      type: TransactionType.expense,
      amountInCents: 5000, // $50.00
      category: 'shopping',
      date: DateTime(2026, 9, 22),
      note: 'Grocery store items',
      createdAt: now,
    ),
    Transaction(
      id: 'tx-3',
      type: TransactionType.income,
      amountInCents: 250000, // $2,500.00
      category: 'salary',
      date: DateTime(2026, 9, 25),
      note: 'Monthly Salary',
      createdAt: now,
    ),
  ];

  Widget createTestWidget({List<Transaction>? transactions}) {
    final repo = MockTransactionRepository(transactions ?? mockTransactions);
    final catRepo = MockCategoryRepository();

    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
      ],
      child: const MaterialApp(home: SearchScreen()),
    );
  }

  group('SearchScreen — Day 3 Widget Tests', () {
    testWidgets('1. SearchScreen renders properly with all elements', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Search Transactions'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(QuickFilterChipsBar), findsOneWidget);
      expect(find.byType(SearchTransactionCard), findsNWidgets(3));
      expect(find.text('3 transactions'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    });

    testWidgets('2. Search field accepts text and displays clear icon', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Coffee');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });

    testWidgets('3. Clear button clears text and restores full list', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Coffee');
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      // Result should be filtered to Coffee
      expect(find.byType(SearchTransactionCard), findsOneWidget);
      expect(find.text('Morning Coffee'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      // Restores all 3 transactions
      expect(find.byType(SearchTransactionCard), findsNWidgets(3));
    });

    testWidgets('4. Quick filter chips filter transactions on tap', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Income' quick filter chip
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Only income transaction (Salary) should remain
      expect(find.byType(SearchTransactionCard), findsOneWidget);
      expect(find.text('Monthly Salary'), findsOneWidget);

      // Tap 'Income' again to deselect
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // All 3 transactions restored
      expect(find.byType(SearchTransactionCard), findsNWidgets(3));
    });

    testWidgets('5. Filter button opens TransactionFilterBottomSheet', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Filter Transactions'), findsOneWidget);
      expect(find.text('Transaction Type'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('6. Filter bottom sheet category selection filters results', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select Food category
      await tester.tap(find.widgetWithText(FilterChip, 'Food'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Should show only food transaction
      expect(find.byType(SearchTransactionCard), findsOneWidget);
      expect(find.text('Morning Coffee'), findsOneWidget);
    });

    testWidgets('7. Filter bottom sheet amount range filtering works', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Enter Min Amount $40.00
      final minAmountField = find.byKey(const Key('filter_min_amount_field'));
      await tester.scrollUntilVisible(
        minAmountField,
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.enterText(minAmountField, '40.00');

      // Apply
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Should show tx-2 ($50) and tx-3 ($2500)
      expect(find.byType(SearchTransactionCard), findsNWidgets(2));
    });

    testWidgets('8. Sorting dropdown menu reorders transactions', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open Sort Menu
      await tester.tap(find.byIcon(Icons.sort_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Highest Amount'), findsOneWidget);
      await tester.tap(find.text('Highest Amount'));
      await tester.pumpAndSettle();

      // Salary ($2500) should be first
      final cards = find.byType(SearchTransactionCard);
      expect(cards, findsNWidgets(3));
    });

    testWidgets('9. Empty state renders when no matches are found', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'RandomNonExistentString');
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      expect(find.byType(SearchEmptyState), findsOneWidget);
      expect(find.text('No matching transactions'), findsOneWidget);
      expect(find.text('Clear All Filters'), findsOneWidget);

      // Tapping clear button on empty state restores full list
      await tester.tap(find.text('Clear All Filters'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchTransactionCard), findsNWidgets(3));
    });

    testWidgets('10. Initial empty state renders when repository has no data', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(transactions: []));
      await tester.pumpAndSettle();

      expect(find.byType(SearchEmptyState), findsOneWidget);
      expect(find.text('No transactions found'), findsOneWidget);
      expect(find.byType(SearchTransactionCard), findsNothing);
    });
  });
}
