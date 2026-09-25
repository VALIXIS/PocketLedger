import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;
import '../models/data_vault_exception.dart';
import '../models/encrypted_vault_envelope.dart';

/// Production-ready cryptographic service providing Authenticated Encryption
/// (AES-256-CBC + HMAC-SHA256 with PBKDF2 Key Derivation) for PocketLedger data backups.
class BackupCryptoService {
  static const int defaultIterations = 10000;
  static const int saltLengthBytes = 16;
  static const int ivLengthBytes = 16;
  static const int keyLengthBytes = 32; // 256 bits for AES
  static const int macKeyLengthBytes = 32; // 256 bits for HMAC

  const BackupCryptoService();

  /// Encrypts a plaintext JSON string with a user passphrase using AES-256-CBC and HMAC-SHA256.
  ///
  /// Returns a structured [EncryptedVaultEnvelope].
  Future<EncryptedVaultEnvelope> encrypt({
    required String plaintext,
    required String passphrase,
    int iterations = defaultIterations,
  }) async {
    if (passphrase.trim().isEmpty) {
      throw const ValidationException(
        'Passphrase cannot be empty for encrypted backup.',
        field: 'passphrase',
      );
    }

    if (iterations < 1000) {
      throw const ValidationException(
        'Iteration count must be at least 1000 for key derivation.',
        field: 'iterations',
      );
    }

    // 1. Generate cryptographically secure random Salt and IV
    final salt = _generateSecureRandomBytes(saltLengthBytes);
    final ivBytes = _generateSecureRandomBytes(ivLengthBytes);

    // 2. Derive Encryption and MAC keys using PBKDF2 HMAC-SHA256 (64 bytes total)
    final derivedKeys = _deriveKeys(passphrase, salt, iterations);
    final encKey = enc.Key(derivedKeys.sublist(0, keyLengthBytes));
    final macKey = derivedKeys.sublist(
      keyLengthBytes,
      keyLengthBytes + macKeyLengthBytes,
    );

    // 3. Encrypt plaintext using AES-256-CBC with PKCS7 padding
    final encrypter = enc.Encrypter(
      enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    );
    final iv = enc.IV(ivBytes);
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final ciphertextBytes = encrypted.bytes;

    // 4. Compute Authenticated MAC over (Salt || IV || Ciphertext)
    final mac = _computeMac(macKey, salt, ivBytes, ciphertextBytes);

    return EncryptedVaultEnvelope(
      iterations: iterations,
      saltBase64: base64Encode(salt),
      ivBase64: base64Encode(ivBytes),
      ciphertextBase64: base64Encode(ciphertextBytes),
      macBase64: base64Encode(mac),
    );
  }

  /// Decrypts an [EncryptedVaultEnvelope] using the user passphrase.
  ///
  /// Validates HMAC integrity before decryption to prevent padding oracle and tampering attacks.
  Future<String> decrypt({
    required EncryptedVaultEnvelope envelope,
    required String passphrase,
  }) async {
    if (passphrase.trim().isEmpty) {
      throw const DecryptionException(
        'Decryption failed: passphrase cannot be empty.',
      );
    }

    Uint8List salt;
    Uint8List ivBytes;
    Uint8List ciphertextBytes;
    Uint8List expectedMac;

    try {
      salt = Uint8List.fromList(base64Decode(envelope.saltBase64));
      ivBytes = Uint8List.fromList(base64Decode(envelope.ivBase64));
      ciphertextBytes = Uint8List.fromList(
        base64Decode(envelope.ciphertextBase64),
      );
      expectedMac = Uint8List.fromList(base64Decode(envelope.macBase64));
    } catch (e) {
      throw CorruptedBackupException(
        'Decryption failed: invalid base64 encoding in encrypted vault payload.',
        e,
      );
    }

    if (salt.length != saltLengthBytes || ivBytes.length != ivLengthBytes) {
      throw const CorruptedBackupException(
        'Decryption failed: invalid salt or IV parameters.',
      );
    }

    // 1. Derive Keys with envelope's iteration count
    final derivedKeys = _deriveKeys(passphrase, salt, envelope.iterations);
    final encKey = enc.Key(derivedKeys.sublist(0, keyLengthBytes));
    final macKey = derivedKeys.sublist(
      keyLengthBytes,
      keyLengthBytes + macKeyLengthBytes,
    );

    // 2. Verify MAC in constant-time
    final computedMac = _computeMac(macKey, salt, ivBytes, ciphertextBytes);
    if (!_constantTimeEquals(expectedMac, computedMac)) {
      throw const DecryptionException(
        'Decryption failed: invalid passphrase or corrupted payload signature.',
      );
    }

    // 3. Decrypt ciphertext
    try {
      final encrypter = enc.Encrypter(
        enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );
      final iv = enc.IV(ivBytes);
      final decrypted = encrypter.decrypt(
        enc.Encrypted(ciphertextBytes),
        iv: iv,
      );
      return decrypted;
    } catch (e) {
      throw DecryptionException(
        'Decryption failed: payload could not be decrypted.',
        e,
      );
    }
  }

  /// Helper to decrypt directly from an encoded envelope string (JSON or Base64).
  Future<String> decryptString({
    required String encryptedData,
    required String passphrase,
  }) async {
    final envelope = EncryptedVaultEnvelope.fromEncodedString(encryptedData);
    return decrypt(envelope: envelope, passphrase: passphrase);
  }

  /// Derives a 64-byte key (32 bytes AES + 32 bytes HMAC) using PBKDF2 HMAC-SHA256.
  Uint8List _deriveKeys(String passphrase, Uint8List salt, int iterations) {
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(
        pc.Pbkdf2Parameters(
          salt,
          iterations,
          keyLengthBytes + macKeyLengthBytes,
        ),
      );
    final passwordBytes = Uint8List.fromList(utf8.encode(passphrase));
    return pbkdf2.process(passwordBytes);
  }

  /// Computes HMAC-SHA256 over (Salt || IV || Ciphertext).
  Uint8List _computeMac(
    Uint8List macKey,
    Uint8List salt,
    Uint8List iv,
    Uint8List ciphertext,
  ) {
    final hmac = Hmac(sha256, macKey);
    final dataToSign = Uint8List(salt.length + iv.length + ciphertext.length)
      ..setRange(0, salt.length, salt)
      ..setRange(salt.length, salt.length + iv.length, iv)
      ..setRange(
        salt.length + iv.length,
        salt.length + iv.length + ciphertext.length,
        ciphertext,
      );
    final digest = hmac.convert(dataToSign);
    return Uint8List.fromList(digest.bytes);
  }

  /// Generates cryptographically secure random bytes using [Random.secure()].
  Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Performs constant-time comparison between two byte arrays to mitigate timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
