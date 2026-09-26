import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../services/backup_crypto_service.dart';
import '../../services/backup_serializer.dart';
import '../../services/data_vault_service.dart';

/// Provider for stateless cryptographic backup engine.
final backupCryptoServiceProvider = Provider<BackupCryptoService>((ref) {
  return const BackupCryptoService();
});

/// Provider for schema serializer and validator.
final backupSerializerProvider = Provider<BackupSerializer>((ref) {
  return const BackupSerializer();
});

/// Provider for the full Data Vault service orchestrating export, validation, and restore.
final dataVaultServiceProvider = Provider<DataVaultService>((ref) {
  final transactionDataSource = ref.watch(transactionLocalDataSourceProvider);
  final categoryDataSource = ref.watch(categoryLocalDataSourceProvider);
  final serializer = ref.watch(backupSerializerProvider);
  final cryptoService = ref.watch(backupCryptoServiceProvider);

  return DataVaultService(
    transactionDataSource: transactionDataSource,
    categoryDataSource: categoryDataSource,
    serializer: serializer,
    cryptoService: cryptoService,
  );
});
