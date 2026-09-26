import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/categories/data/datasources/category_local_datasource.dart';
import 'package:pocketledger/features/categories/domain/models/category.dart';
import 'package:pocketledger/features/categories/domain/repositories/category_repository.dart';
import 'package:pocketledger/features/categories/presentation/providers/category_providers.dart';
import 'package:pocketledger/features/data_vault/models/restore_result.dart';
import 'package:pocketledger/features/data_vault/services/data_vault_service.dart';
import 'package:pocketledger/features/search/presentation/screens/search_screen.dart';
import 'package:pocketledger/features/search/presentation/widgets/search_empty_state.dart';
import 'package:pocketledger/features/search/presentation/widgets/search_transaction_card.dart';
import 'package:pocketledger/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

class InMemoryTransactionDataSource implements TransactionLocalDataSource {
  final Map<String, Transaction> _map = {};

  InMemoryTransactionDataSource([List<Transaction>? initial]) {
    if (initial != null) {
      for (final tx in initial) {
        _map[tx.id] = tx;
      }
    }
  }

  @override
  Future<List<Transaction>> getTransactions() async => _map.values.toList();

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _map[transaction.id] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _map.remove(id);
  }
}

class InMemoryCategoryDataSource implements CategoryLocalDataSource {
  final Map<String, Category> _map = {};

  @override
  Future<List<Category>> getCategories() async {
    final all = <String, Category>{};
    for (final c in Category.defaultCategories) {
      all[c.id] = c;
    }
    for (final e in _map.entries) {
      all[e.key] = e.value;
    }
    return all.values.toList();
  }

  @override
  Future<void> saveCategory(Category category) async {
    _map[category.id] = category;
  }
}

class InMemoryCategoryRepository implements CategoryRepository {
  final CategoryLocalDataSource dataSource;
  InMemoryCategoryRepository(this.dataSource);

  @override
  Future<List<Category>> getCategories() => dataSource.getCategories();

  @override
  Future<void> addCategory(Category category) => dataSource.saveCategory(category);
}

void main() {
  final now = DateTime(2026, 9, 25, 12, 0);

  final initialTransactions = [
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
      note: 'Groceries store',
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

  group('Search & Data Vault — End-to-End Integration Tests (Day 5)', () {
    testWidgets(
      '1. UI -> Riverpod -> Repository: adding new transaction in repository updates search UI reactively',
      (tester) async {
        final txDataSource = InMemoryTransactionDataSource(initialTransactions);
        final catDataSource = InMemoryCategoryDataSource();
        final catRepo = InMemoryCategoryRepository(catDataSource);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionLocalDataSourceProvider.overrideWithValue(txDataSource),
              categoryLocalDataSourceProvider.overrideWithValue(catDataSource),
              categoryRepositoryProvider.overrideWithValue(catRepo),
            ],
            child: const MaterialApp(home: SearchScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initially 3 transactions
        expect(find.text('3 transactions'), findsOneWidget);
        expect(find.byType(SearchTransactionCard), findsNWidgets(3));

        // Add 4th transaction through the transaction list notifier
        final element = tester.element(find.byType(SearchScreen));
        final container = ProviderScope.containerOf(element);

        await container.read(transactionListProvider.notifier).addTransaction(
              Transaction(
                id: 'tx-4',
                type: TransactionType.expense,
                amountInCents: 8500, // $85.00
                category: 'transport',
                date: DateTime(2026, 9, 25),
                note: 'Train pass',
                createdAt: now,
              ),
            );

        await tester.pumpAndSettle();

        // Search screen reactively displays 4 transactions
        expect(find.text('4 transactions'), findsOneWidget);
        expect(find.byType(SearchTransactionCard), findsNWidgets(4));
        expect(find.text('Train pass'), findsOneWidget);
      },
    );

    testWidgets(
      '2. UI -> SearchService: typing query, filtering by quick tag, and clearing via button',
      (tester) async {
        final txDataSource = InMemoryTransactionDataSource(initialTransactions);
        final catDataSource = InMemoryCategoryDataSource();
        final catRepo = InMemoryCategoryRepository(catDataSource);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionLocalDataSourceProvider.overrideWithValue(txDataSource),
              categoryLocalDataSourceProvider.overrideWithValue(catDataSource),
              categoryRepositoryProvider.overrideWithValue(catRepo),
            ],
            child: const MaterialApp(home: SearchScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Search text: 'Salary'
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'Salary');
        await tester.pumpAndSettle(const Duration(milliseconds: 350));

        expect(find.textContaining('1 of 3 transactions'), findsOneWidget);
        expect(find.byType(SearchTransactionCard), findsOneWidget);
        expect(find.text('Monthly Salary'), findsOneWidget);

        // Tap Clear Button
        await tester.tap(find.byIcon(Icons.clear_rounded));
        await tester.pumpAndSettle();

        expect(find.text('3 transactions'), findsOneWidget);
        expect(find.byType(SearchTransactionCard), findsNWidgets(3));
      },
    );

    testWidgets(
      '3. Full Pipeline: Data Vault Backup -> Storage Wipe -> Search Empty State -> Restore -> Search Recovery',
      (tester) async {
        final txDataSource = InMemoryTransactionDataSource(initialTransactions);
        final catDataSource = InMemoryCategoryDataSource();
        final catRepo = InMemoryCategoryRepository(catDataSource);
        final vaultService = DataVaultService(
          transactionDataSource: txDataSource,
          categoryDataSource: catDataSource,
        );

        const passphrase = 'DataVaultIntegrationPassphrase2026!';

        // 1. Create encrypted backup
        final encryptedBackup = await vaultService.exportEncryptedBackup(
          passphrase: passphrase,
        );
        expect(encryptedBackup, isNotEmpty);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionLocalDataSourceProvider.overrideWithValue(txDataSource),
              categoryLocalDataSourceProvider.overrideWithValue(catDataSource),
              categoryRepositoryProvider.overrideWithValue(catRepo),
            ],
            child: const MaterialApp(home: SearchScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 transactions'), findsOneWidget);

        // 2. Wipe storage
        final element = tester.element(find.byType(SearchScreen));
        final container = ProviderScope.containerOf(element);

        await container.read(transactionListProvider.notifier).deleteTransaction('tx-1');
        await container.read(transactionListProvider.notifier).deleteTransaction('tx-2');
        await container.read(transactionListProvider.notifier).deleteTransaction('tx-3');

        await tester.pumpAndSettle();

        // Search screen now displays empty state
        expect(find.byType(SearchEmptyState), findsOneWidget);
        expect(find.text('No transactions found'), findsOneWidget);

        // 3. Restore backup
        final restoreResult = await vaultService.restoreFromEncrypted(
          encryptedData: encryptedBackup,
          passphrase: passphrase,
          mode: RestoreMode.overwrite,
        );

        expect(restoreResult.isSuccess, isTrue);
        expect(restoreResult.restoredTransactionsCount, 3);

        // Reload transactions into Riverpod state
        await container.read(transactionListProvider.notifier).loadTransactions();
        await tester.pumpAndSettle();

        // Search screen immediately recovers and displays all 3 restored transactions
        expect(find.text('3 transactions'), findsOneWidget);
        expect(find.byType(SearchTransactionCard), findsNWidgets(3));
      },
    );
  });
}
