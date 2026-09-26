/// Base exception for all DataVault errors.
sealed class DataVaultException implements Exception {
  final String message;
  final Object? details;

  const DataVaultException(this.message, [this.details]);

  @override
  String toString() => details != null ? '$message: $details' : message;
}

/// Thrown when decryption fails due to wrong passphrase, corrupted ciphertext, or MAC mismatch.
class DecryptionException extends DataVaultException {
  const DecryptionException(super.message, [super.details]);
}

/// Thrown when the backup JSON schema is missing, invalid, or unsupported.
class UnsupportedSchemaException extends DataVaultException {
  const UnsupportedSchemaException(super.message, [super.details]);
}

/// Thrown when payload structural or field validation fails (e.g. invalid date, amount, duplicate IDs).
class ValidationException extends DataVaultException {
  final String? field;

  const ValidationException(String message, {this.field, Object? details})
    : super(message, details);

  @override
  String toString() {
    if (field != null) {
      return 'Validation error on field "$field": $message';
    }
    return 'Validation error: $message';
  }
}

/// Thrown when the backup container is corrupted, truncated, or unparseable.
class CorruptedBackupException extends DataVaultException {
  const CorruptedBackupException(super.message, [super.details]);
}

/// Thrown when restoring transactions or categories fails.
class RestoreException extends DataVaultException {
  const RestoreException(super.message, [super.details]);
}
