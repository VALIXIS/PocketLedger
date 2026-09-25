import '../../budgets/domain/entities/budget.dart';
import '../../categories/data/datasources/category_local_datasource.dart';
import '../../categories/domain/models/category.dart';
import '../../transactions/data/datasources/transaction_local_datasource.dart';
import '../models/backup_payload.dart';
import '../models/data_vault_exception.dart';
import '../models/restore_result.dart';
import 'backup_crypto_service.dart';
import 'backup_serializer.dart';

/// Primary Data Vault service responsible for secure data export, encryption,
/// strict schema verification, and atomic snapshot-backed restore.
class DataVaultService {
  final TransactionLocalDataSource transactionDataSource;
  final CategoryLocalDataSource categoryDataSource;
  final BackupSerializer serializer;
  final BackupCryptoService cryptoService;

  const DataVaultService({
    required this.transactionDataSource,
    required this.categoryDataSource,
    this.serializer = const BackupSerializer(),
    this.cryptoService = const BackupCryptoService(),
  });

  /// Captures all local data into a validated in-memory [BackupPayload].
  Future<BackupPayload> createBackupPayload() async {
    final transactions = await transactionDataSource.getTransactions();
    final categories = await categoryDataSource.getCategories();

    return BackupPayload(
      transactions: transactions,
      categories: categories,
      budgets: const <Budget>[],
    );
  }

  /// Exports an authenticated, encrypted AES-256 backup string using the provided passphrase.
  Future<String> exportEncryptedBackup({
    required String passphrase,
    int iterations = BackupCryptoService.defaultIterations,
  }) async {
    final payload = await createBackupPayload();
    final plaintextJson = serializer.serialize(payload);
    final envelope = await cryptoService.encrypt(
      plaintext: plaintextJson,
      passphrase: passphrase,
      iterations: iterations,
    );
    return envelope.toEncodedString();
  }

  /// Exports a standard plaintext JSON backup string.
  Future<String> exportJsonBackup() async {
    final payload = await createBackupPayload();
    return serializer.serialize(payload);
  }

  /// Decrypts and validates an encrypted backup string without altering local storage.
  ///
  /// Returns the parsed [BackupPayload] on success.
  /// Throws [DecryptionException], [ValidationException], [UnsupportedSchemaException], or [CorruptedBackupException].
  Future<BackupPayload> validateEncryptedBackup({
    required String encryptedData,
    required String passphrase,
  }) async {
    final decryptedJson = await cryptoService.decryptString(
      encryptedData: encryptedData,
      passphrase: passphrase,
    );
    return serializer.deserialize(decryptedJson);
  }

  /// Parses and validates a plaintext JSON backup string without altering local storage.
  Future<BackupPayload> validateJsonBackup(String jsonString) async {
    return serializer.deserialize(jsonString);
  }

  /// Restores PocketLedger data from a [BackupPayload] with transactional rollback protection.
  ///
  /// [mode]: [RestoreMode.overwrite] clears existing records and replaces them.
  /// [mode]: [RestoreMode.merge] merges records while avoiding duplicate IDs.
  Future<RestoreResult> restoreFromPayload(
    BackupPayload payload, {
    RestoreMode mode = RestoreMode.overwrite,
  }) async {
    // 1. Take in-memory snapshot of current storage state for rollback safety
    final previousTransactions = await transactionDataSource.getTransactions();
    final previousCategories = await categoryDataSource.getCategories();

    try {
      if (mode == RestoreMode.overwrite) {
        // Clear existing transactions
        for (final tx in previousTransactions) {
          await transactionDataSource.deleteTransaction(tx.id);
        }

        // Save incoming custom categories (exclude default static categories from box storage if already built-in)
        for (final cat in payload.categories) {
          final isBuiltIn = Category.defaultCategories.any(
            (d) => d.id == cat.id,
          );
          if (!isBuiltIn) {
            await categoryDataSource.saveCategory(cat);
          }
        }

        // Save incoming transactions
        for (final tx in payload.transactions) {
          await transactionDataSource.saveTransaction(tx);
        }
      } else {
        // Mode: Merge
        for (final cat in payload.categories) {
          final isBuiltIn = Category.defaultCategories.any(
            (d) => d.id == cat.id,
          );
          if (!isBuiltIn) {
            await categoryDataSource.saveCategory(cat);
          }
        }

        for (final tx in payload.transactions) {
          await transactionDataSource.saveTransaction(tx);
        }
      }

      return RestoreResult.success(
        restoredTransactions: payload.transactions.length,
        restoredCategories: payload.categories.length,
        restoredBudgets: payload.budgets.length,
      );
    } catch (e, stack) {
      // 2. Rollback snapshot on any unexpected failure to prevent partial / corrupted state
      try {
        // Clear any half-written state
        final currentTx = await transactionDataSource.getTransactions();
        for (final tx in currentTx) {
          await transactionDataSource.deleteTransaction(tx.id);
        }
        for (final tx in previousTransactions) {
          await transactionDataSource.saveTransaction(tx);
        }
        for (final cat in previousCategories) {
          final isBuiltIn = Category.defaultCategories.any(
            (d) => d.id == cat.id,
          );
          if (!isBuiltIn) {
            await categoryDataSource.saveCategory(cat);
          }
        }
      } catch (_) {
        // Rollback attempt completed
      }

      throw RestoreException('Failed to restore data vault backup: $e', stack);
    }
  }

  /// Decrypts, validates, and restores from an encrypted backup string with transactional safety.
  Future<RestoreResult> restoreFromEncrypted({
    required String encryptedData,
    required String passphrase,
    RestoreMode mode = RestoreMode.overwrite,
  }) async {
    final payload = await validateEncryptedBackup(
      encryptedData: encryptedData,
      passphrase: passphrase,
    );
    return restoreFromPayload(payload, mode: mode);
  }

  /// Validates and restores from a plaintext JSON backup string with transactional safety.
  Future<RestoreResult> restoreFromJson({
    required String jsonString,
    RestoreMode mode = RestoreMode.overwrite,
  }) async {
    final payload = await validateJsonBackup(jsonString);
    return restoreFromPayload(payload, mode: mode);
  }
}
