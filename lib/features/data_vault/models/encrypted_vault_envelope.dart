import 'dart:convert';
import 'data_vault_exception.dart';

/// Cryptographically secure envelope container for encrypted PocketLedger backups.
///
/// Implements standard Authenticated Encryption envelope (Encrypt-then-MAC)
/// containing AES-256-CBC ciphertext and HMAC-SHA256 signature.
class EncryptedVaultEnvelope {
  static const int currentVaultVersion = 1;
  static const String defaultCipher = 'AES-256-CBC';
  static const String defaultKdf = 'PBKDF2/HMAC-SHA256';

  final int vaultVersion;
  final String cipher;
  final String kdf;
  final int iterations;
  final String saltBase64;
  final String ivBase64;
  final String ciphertextBase64;
  final String macBase64;

  const EncryptedVaultEnvelope({
    this.vaultVersion = currentVaultVersion,
    this.cipher = defaultCipher,
    this.kdf = defaultKdf,
    required this.iterations,
    required this.saltBase64,
    required this.ivBase64,
    required this.ciphertextBase64,
    required this.macBase64,
  });

  /// Converts this envelope to a standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'vaultVersion': vaultVersion,
      'cipher': cipher,
      'kdf': kdf,
      'iterations': iterations,
      'salt': saltBase64,
      'iv': ivBase64,
      'ciphertext': ciphertextBase64,
      'mac': macBase64,
    };
  }

  /// Encodes this envelope to a portable formatted JSON string.
  String toEncodedString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Parses an envelope from a JSON map with strict validation.
  factory EncryptedVaultEnvelope.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('vaultVersion') ||
        !json.containsKey('salt') ||
        !json.containsKey('iv') ||
        !json.containsKey('ciphertext') ||
        !json.containsKey('mac')) {
      throw const CorruptedBackupException(
        'Malformed encrypted vault envelope: missing required fields.',
      );
    }

    final vaultVersion = json['vaultVersion'];
    if (vaultVersion is! int) {
      throw const UnsupportedSchemaException(
        'Invalid vaultVersion format in encrypted envelope.',
      );
    }

    if (vaultVersion != currentVaultVersion) {
      throw UnsupportedSchemaException(
        'Unsupported vaultVersion ($vaultVersion). Expected $currentVaultVersion.',
      );
    }

    final iterations = json['iterations'] as int? ?? 10000;
    if (iterations < 1000) {
      throw const ValidationException(
        'KDF iterations too low for secure decryption.',
        field: 'iterations',
      );
    }

    return EncryptedVaultEnvelope(
      vaultVersion: vaultVersion,
      cipher: json['cipher'] as String? ?? defaultCipher,
      kdf: json['kdf'] as String? ?? defaultKdf,
      iterations: iterations,
      saltBase64: json['salt'] as String,
      ivBase64: json['iv'] as String,
      ciphertextBase64: json['ciphertext'] as String,
      macBase64: json['mac'] as String,
    );
  }

  /// Parses an envelope from an encoded JSON or Base64-JSON string.
  factory EncryptedVaultEnvelope.fromEncodedString(String encoded) {
    final trimmed = encoded.trim();
    if (trimmed.isEmpty) {
      throw const CorruptedBackupException('Encrypted backup string is empty.');
    }

    try {
      dynamic parsedJson;
      // First try standard JSON decode
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        parsedJson = jsonDecode(trimmed);
      } else {
        // Try decoding as Base64 JSON
        final decodedBytes = base64Decode(trimmed);
        final decodedStr = utf8.decode(decodedBytes);
        parsedJson = jsonDecode(decodedStr);
      }

      if (parsedJson is! Map<String, dynamic>) {
        throw const CorruptedBackupException(
          'Decoded vault payload is not a valid JSON object.',
        );
      }

      return EncryptedVaultEnvelope.fromJson(parsedJson);
    } on FormatException catch (e) {
      throw CorruptedBackupException('Invalid encrypted envelope format.', e);
    }
  }
}
