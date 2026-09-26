import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/categories/domain/models/category.dart';
import 'package:pocketledger/features/data_vault/models/backup_payload.dart';
import 'package:pocketledger/features/data_vault/models/restore_result.dart';
import 'package:pocketledger/features/data_vault/services/backup_crypto_service.dart';
import 'package:pocketledger/features/data_vault/services/backup_serializer.dart';
import 'package:pocketledger/features/data_vault/services/data_vault_service.dart';
import 'package:pocketledger/features/search/models/quick_filter_tag.dart';
import 'package:pocketledger/features/search/models/transaction_sort_option.dart';
import 'package:pocketledger/features/search/presentation/providers/search_providers.dart';
import 'package:pocketledger/features/search/services/transaction_search_service.dart';
import 'package:pocketledger/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:pocketledger/features/categories/data/datasources/category_local_datasource.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

class MockTxDataSource implements TransactionLocalDataSource {
  final Map<String, Transaction> data = {};

  @override
  Future<List<Transaction>> getTransactions() async => data.values.toList();

  @override
  Future<void> saveTransaction(Transaction tx) async {
    data[tx.id] = tx;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    data.remove(id);
  }
}

class MockCatDataSource implements CategoryLocalDataSource {
  final Map<String, Category> data = {};

  @override
  Future<List<Category>> getCategories() async {
    final list = <Category>[...Category.defaultCategories, ...data.values];
    return list;
  }

  @override
  Future<void> saveCategory(Category category) async {
    data[category.id] = category;
  }
}

void main() {
  const searchService = TransactionSearchService();
  final baseDate = DateTime(2026, 9, 25, 12, 0, 0);

  group('Master QA Matrix — Edge Cases, Scale & Robustness (Day 6)', () {
    group('1. Edge Cases: Extreme Amounts & Zero Values', () {
      final edgeTransactions = [
        Transaction(
          id: 'tx-zero',
          type: TransactionType.expense,
          amountInCents: 0, // $0.00
          category: 'food',
          date: baseDate,
          note: 'Free promotional coffee',
          createdAt: baseDate,
        ),
        Transaction(
          id: 'tx-billion',
          type: TransactionType.income,
          amountInCents: 100000000000, // $1,000,000,000.00 (1 Billion Dollars)
          category: 'business',
          date: baseDate,
          note: 'Acquisition payout',
          createdAt: baseDate,
        ),
      ];

      test(r'search handles $0.00 amount correctly', () {
        final result = searchService.search(
          edgeTransactions,
          minAmount: 0.0,
          maxAmount: 0.0,
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-zero');
      });

      test(
        'search handles billion dollar amount accurately without overflow',
        () {
          final result = searchService.search(
            edgeTransactions,
            minAmount: 500000000.0,
          );
          expect(result.length, 1);
          expect(result.first.id, 'tx-billion');
        },
      );
    });

    group('2. Edge Cases: Special Characters, Emojis & Long Strings', () {
      final unicodeTransactions = [
        Transaction(
          id: 'tx-emoji',
          type: TransactionType.expense,
          amountInCents: 2500,
          category: 'entertainment',
          date: baseDate,
          note: 'Movie night 🍿🎬 with friends! 🎉 #weekend',
          createdAt: baseDate,
        ),
        Transaction(
          id: 'tx-symbols',
          type: TransactionType.income,
          amountInCents: 12000,
          category: 'freelance',
          date: baseDate,
          note: 'Payment ref: [INV-2026-09] (100% done) <admin@valixis.com>',
          createdAt: baseDate,
        ),
        Transaction(
          id: 'tx-long',
          type: TransactionType.expense,
          amountInCents: 450,
          category: 'food',
          date: baseDate,
          note: 'A' * 1000, // 1,000 character note
          createdAt: baseDate,
        ),
      ];

      test('searches with emojis and unicode characters', () {
        final result = searchService.search(unicodeTransactions, query: '🍿');
        expect(result.length, 1);
        expect(result.first.id, 'tx-emoji');
      });

      test('searches with special regex/punctuation characters', () {
        final result = searchService.search(
          unicodeTransactions,
          query: '[INV-2026-09]',
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-symbols');
      });

      test('searches safely within very long 1,000-character notes', () {
        final result = searchService.search(
          unicodeTransactions,
          query: 'AAAAA',
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-long');
      });
    });

    group(
      '3. Edge Cases: Same-Day Boundary Times (00:00:00 vs 23:59:59.999)',
      () {
        final timeBoundaryTransactions = [
          Transaction(
            id: 'tx-start-of-day',
            type: TransactionType.expense,
            amountInCents: 1000,
            category: 'food',
            date: DateTime(2026, 9, 25, 0, 0, 0, 0, 0), // midnight
            note: 'Midnight snack',
            createdAt: baseDate,
          ),
          Transaction(
            id: 'tx-end-of-day',
            type: TransactionType.expense,
            amountInCents: 2000,
            category: 'transport',
            date: DateTime(2026, 9, 25, 23, 59, 59, 999), // end of day
            note: 'Late taxi home',
            createdAt: baseDate,
          ),
        ];

        test(
          'inclusive date filter captures both start-of-day and end-of-day transactions',
          () {
            final result = searchService.search(
              timeBoundaryTransactions,
              startDate: DateTime(2026, 9, 25),
              endDate: DateTime(2026, 9, 25),
            );
            expect(result.length, 2);
            expect(result.map((t) => t.id).toList(), [
              'tx-start-of-day',
              'tx-end-of-day',
            ]);
          },
        );
      },
    );

    group('4. Search State & Rapid Filter Mutations', () {
      test(
        'SearchNotifier survives rapid consecutive filter changes',
        () async {
          final notifier = SearchNotifier(
            initialTransactions: [
              Transaction(
                id: 'tx-1',
                type: TransactionType.expense,
                amountInCents: 1500,
                category: 'food',
                date: baseDate,
                note: 'Coffee',
                createdAt: baseDate,
              ),
            ],
            nowProvider: () => baseDate,
          );

          // Rapidly toggle tags
          notifier.toggleQuickFilter(QuickFilterTag.income);
          notifier.toggleQuickFilter(QuickFilterTag.expense);
          notifier.toggleQuickFilter(QuickFilterTag.today);
          notifier.setCategory('food');
          notifier.setAmountRange(minAmount: 10.0, maxAmount: 20.0);
          notifier.setSortOption(TransactionSortOption.highestAmount);

          expect(notifier.state.hasActiveFilters, isTrue);
          expect(notifier.state.filteredTransactions.length, 1);

          // Clear all
          notifier.clearAllFilters();
          expect(notifier.state.hasActiveFilters, isFalse);
          expect(notifier.state.filteredTransactions.length, 1);
        },
      );
    });

    group('5. Data Vault & Round Trip with Unicode & Extremes', () {
      test(
        'DataVault serializes, encrypts, decrypts, and restores unicode & extreme values',
        () async {
          final txDataSource = MockTxDataSource();
          final catDataSource = MockCatDataSource();
          final vaultService = DataVaultService(
            transactionDataSource: txDataSource,
            categoryDataSource: catDataSource,
          );

          final complexPayload = BackupPayload(
            transactions: [
              Transaction(
                id: 'tx-unicode',
                type: TransactionType.income,
                amountInCents: 9999999999, // $99.9M
                category: 'crypto_staking',
                date: baseDate,
                note:
                    '✨ Special Characters: <script>alert("test")</script> & Emojis 🚀 💵',
                createdAt: baseDate,
              ),
            ],
            categories: [
              Category(
                id: 'crypto_staking',
                name: 'Crypto 🚀 Staking',
                isIncome: true,
              ),
            ],
          );

          const password = 'StrongPassword!#2026_Vault';

          // 1. Direct Crypto roundtrip
          const cryptoService = BackupCryptoService();
          const serializer = BackupSerializer();
          final jsonStr = serializer.serialize(complexPayload);
          final envelope = await cryptoService.encrypt(
            plaintext: jsonStr,
            passphrase: password,
          );
          final decryptedJson = await cryptoService.decrypt(
            envelope: envelope,
            passphrase: password,
          );
          final parsedPayload = serializer.deserialize(decryptedJson);

          expect(
            parsedPayload.transactions.first.note,
            contains('✨ Special Characters'),
          );
          expect(parsedPayload.transactions.first.amountInCents, 9999999999);
          expect(parsedPayload.categories.first.name, 'Crypto 🚀 Staking');

          // 2. Service restore
          final result = await vaultService.restoreFromPayload(
            parsedPayload,
            mode: RestoreMode.overwrite,
          );
          expect(result.isSuccess, isTrue);
          expect((await txDataSource.getTransactions()).length, 1);
        },
      );
    });
  });
}
