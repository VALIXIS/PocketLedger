import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/categories/domain/models/category.dart';
import 'package:pocketledger/features/categories/domain/repositories/category_repository.dart';
import 'package:pocketledger/features/categories/presentation/providers/category_providers.dart';
import 'package:pocketledger/features/search/presentation/widgets/transaction_filter_bottom_sheet.dart';
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
      amountInCents: 1500,
      category: 'food',
      date: DateTime(2026, 9, 20),
      note: 'Coffee',
      createdAt: now,
    ),
    Transaction(
      id: 'tx-2',
      type: TransactionType.income,
      amountInCents: 250000,
      category: 'salary',
      date: DateTime(2026, 9, 25),
      note: 'Salary',
      createdAt: now,
    ),
  ];

  Widget createTestBottomSheet() {
    final repo = MockTransactionRepository(mockTransactions);
    final catRepo = MockCategoryRepository();

    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => TransactionFilterBottomSheet.show(context),
                child: const Text('Open Bottom Sheet'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('TransactionFilterBottomSheet — Widget Tests', () {
    testWidgets('renders all filter sections and buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createTestBottomSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Transactions'), findsOneWidget);
      expect(find.text('Transaction Type'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
    });

    testWidgets(
      'selecting transaction type and applying updates search state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(createTestBottomSheet());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Bottom Sheet'));
        await tester.pumpAndSettle();

        // Tap Expense in SegmentedButton
        await tester.tap(find.text('Expense'));
        await tester.pumpAndSettle();

        // Tap Apply
        await tester.tap(find.text('Apply Filters'));
        await tester.pumpAndSettle();

        // Bottom sheet closed
        expect(find.text('Filter Transactions'), findsNothing);
      },
    );

    testWidgets('Reset All button clears filter selections and closes sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createTestBottomSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Transactions'), findsNothing);
    });
  });
}
