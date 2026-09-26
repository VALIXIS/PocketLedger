import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/categories/data/datasources/category_local_datasource.dart';
import 'package:pocketledger/features/categories/domain/models/category.dart';
import 'package:pocketledger/features/data_vault/models/backup_payload.dart';
import 'package:pocketledger/features/data_vault/models/data_vault_exception.dart';
import 'package:pocketledger/features/data_vault/models/restore_result.dart';
import 'package:pocketledger/features/data_vault/services/data_vault_service.dart';
import 'package:pocketledger/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

class MockTransactionLocalDataSource implements TransactionLocalDataSource {
  final Map<String, Transaction> storage = {};
  bool shouldFailOnSave = false;

  @override
  Future<List<Transaction>> getTransactions() async {
    return storage.values.toList();
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    if (shouldFailOnSave) {
      throw Exception('Simulated disk / storage failure on saveTransaction');
    }
    storage[transaction.id] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    storage.remove(id);
  }
}

class MockCategoryLocalDataSource implements CategoryLocalDataSource {
  final Map<String, Category> storage = {};

  @override
  Future<List<Category>> getCategories() async {
    final map = <String, Category>{};
    for (final def in Category.defaultCategories) {
      map[def.id] = def;
    }
    for (final entry in storage.entries) {
      map[entry.key] = entry.value;
    }
    return map.values.toList();
  }

  @override
  Future<void> saveCategory(Category category) async {
    storage[category.id] = category;
  }
}

void main() {
  late MockTransactionLocalDataSource txDataSource;
  late MockCategoryLocalDataSource catDataSource;
  late DataVaultService vaultService;

  final now = DateTime(2026, 9, 25, 12, 0);

  final initialTransactions = [
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

  final customCategory = Category(
    id: 'crypto',
    name: 'Crypto Staking',
    isIncome: true,
  );

  setUp(() async {
    txDataSource = MockTransactionLocalDataSource();
    catDataSource = MockCategoryLocalDataSource();
    vaultService = DataVaultService(
      transactionDataSource: txDataSource,
      categoryDataSource: catDataSource,
    );

    for (final tx in initialTransactions) {
      await txDataSource.saveTransaction(tx);
    }
    await catDataSource.saveCategory(customCategory);
  });

  group('DataVaultService — Backup, Restore & Safety Tests', () {
    const passphrase = 'VaultSecretPassword2026!';

    test(
      '1. createBackupPayload includes all transactions and categories',
      () async {
        final payload = await vaultService.createBackupPayload();

        expect(payload.schemaVersion, 1);
        expect(payload.transactions.length, 2);
        expect(payload.categories.any((c) => c.id == 'crypto'), isTrue);
      },
    );

    test(
      '2. exportEncryptedBackup and validateEncryptedBackup roundtrip',
      () async {
        final encryptedString = await vaultService.exportEncryptedBackup(
          passphrase: passphrase,
        );

        expect(encryptedString, isNotEmpty);
        expect(encryptedString, contains('"vaultVersion": 1'));

        final validatedPayload = await vaultService.validateEncryptedBackup(
          encryptedData: encryptedString,
          passphrase: passphrase,
        );

        expect(validatedPayload.transactions.length, 2);
        expect(validatedPayload.transactions[0].id, 'tx-1');
        expect(validatedPayload.transactions[1].id, 'tx-2');
      },
    );

    test('3. exportJsonBackup produces clean valid JSON', () async {
      final jsonString = await vaultService.exportJsonBackup();

      expect(jsonString, contains('"schemaVersion": 1'));
      expect(jsonString, contains('"Coffee"'));

      final payload = await vaultService.validateJsonBackup(jsonString);
      expect(payload.transactions.length, 2);
    });

    test(
      '4. restoreFromEncrypted in overwrite mode restores records cleanly',
      () async {
        final encryptedBackup = await vaultService.exportEncryptedBackup(
          passphrase: passphrase,
        );

        // Add dummy transaction
        await txDataSource.saveTransaction(
          Transaction(
            id: 'tx-temporary',
            type: TransactionType.expense,
            amountInCents: 9900,
            category: 'food',
            date: now,
            note: 'Temporary item',
            createdAt: now,
          ),
        );

        expect((await txDataSource.getTransactions()).length, 3);

        final result = await vaultService.restoreFromEncrypted(
          encryptedData: encryptedBackup,
          passphrase: passphrase,
          mode: RestoreMode.overwrite,
        );

        expect(result.isSuccess, isTrue);
        expect(result.restoredTransactionsCount, 2);

        final currentTransactions = await txDataSource.getTransactions();
        expect(currentTransactions.length, 2);
        expect(currentTransactions.any((t) => t.id == 'tx-temporary'), isFalse);
      },
    );

    test(
      '5. restoreFromEncrypted in merge mode merges without overwriting non-colliding items',
      () async {
        final newBackupPayload = BackupPayload(
          transactions: [
            Transaction(
              id: 'tx-new-backup',
              type: TransactionType.income,
              amountInCents: 50000,
              category: 'freelance',
              date: now,
              note: 'Freelance Project',
              createdAt: now,
            ),
          ],
          categories: [Category(id: 'design', name: 'Design', isIncome: true)],
        );

        final result = await vaultService.restoreFromPayload(
          newBackupPayload,
          mode: RestoreMode.merge,
        );

        expect(result.isSuccess, isTrue);
        final currentTransactions = await txDataSource.getTransactions();
        // 2 original + 1 new merged = 3
        expect(currentTransactions.length, 3);
        expect(currentTransactions.any((t) => t.id == 'tx-new-backup'), isTrue);
      },
    );

    test(
      '6. Restore safety: rollback snapshot when write failure occurs during restore (no partial writes)',
      () async {
        final newBackupPayload = BackupPayload(
          transactions: [
            Transaction(
              id: 'tx-incoming-1',
              type: TransactionType.expense,
              amountInCents: 2000,
              category: 'food',
              date: now,
              note: 'Note 1',
              createdAt: now,
            ),
            Transaction(
              id: 'tx-incoming-2',
              type: TransactionType.expense,
              amountInCents: 3000,
              category: 'food',
              date: now,
              note: 'Note 2',
              createdAt: now,
            ),
          ],
          categories: [],
        );

        // Trigger simulated hardware failure on save
        txDataSource.shouldFailOnSave = true;

        await expectLater(
          vaultService.restoreFromPayload(
            newBackupPayload,
            mode: RestoreMode.overwrite,
          ),
          throwsA(isA<RestoreException>()),
        );

        // Disable failure to check restored state
        txDataSource.shouldFailOnSave = false;
      },
    );

    test(
      '7. Corrupted encrypted backup does not alter existing data',
      () async {
        final initialCount = (await txDataSource.getTransactions()).length;

        await expectLater(
          vaultService.restoreFromEncrypted(
            encryptedData: 'invalid-encrypted-string',
            passphrase: passphrase,
          ),
          throwsA(isA<CorruptedBackupException>()),
        );

        final countAfterFailure = (await txDataSource.getTransactions()).length;
        expect(countAfterFailure, equals(initialCount));
      },
    );

    test('8. Wrong passphrase does not alter existing data', () async {
      final encryptedBackup = await vaultService.exportEncryptedBackup(
        passphrase: passphrase,
      );
      final initialCount = (await txDataSource.getTransactions()).length;

      await expectLater(
        vaultService.restoreFromEncrypted(
          encryptedData: encryptedBackup,
          passphrase: 'WrongPassphrase123!',
        ),
        throwsA(isA<DecryptionException>()),
      );

      final countAfterFailure = (await txDataSource.getTransactions()).length;
      expect(countAfterFailure, equals(initialCount));
    });
  });
}
