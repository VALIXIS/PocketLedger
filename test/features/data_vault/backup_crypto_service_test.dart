import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/data_vault/models/data_vault_exception.dart';
import 'package:pocketledger/features/data_vault/models/encrypted_vault_envelope.dart';
import 'package:pocketledger/features/data_vault/services/backup_crypto_service.dart';

void main() {
  const cryptoService = BackupCryptoService();

  group('BackupCryptoService — Cryptography & Security Tests', () {
    const samplePlaintext =
        '{"schemaVersion":1,"appName":"PocketLedger","transactions":[]}';
    const strongPassphrase = 'MySuperSecret#Passphrase123!';

    test('1. Valid encryption and decryption round trip succeeds', () async {
      final envelope = await cryptoService.encrypt(
        plaintext: samplePlaintext,
        passphrase: strongPassphrase,
      );

      expect(envelope.vaultVersion, 1);
      expect(envelope.cipher, 'AES-256-CBC');
      expect(envelope.kdf, 'PBKDF2/HMAC-SHA256');
      expect(envelope.saltBase64, isNotEmpty);
      expect(envelope.ivBase64, isNotEmpty);
      expect(envelope.ciphertextBase64, isNotEmpty);
      expect(envelope.macBase64, isNotEmpty);

      final decrypted = await cryptoService.decrypt(
        envelope: envelope,
        passphrase: strongPassphrase,
      );

      expect(decrypted, equals(samplePlaintext));
    });

    test(
      '2. Encrypting the same plaintext twice produces different ciphertexts (random IV/Salt)',
      () async {
        final envelope1 = await cryptoService.encrypt(
          plaintext: samplePlaintext,
          passphrase: strongPassphrase,
        );
        final envelope2 = await cryptoService.encrypt(
          plaintext: samplePlaintext,
          passphrase: strongPassphrase,
        );

        expect(envelope1.saltBase64, isNot(equals(envelope2.saltBase64)));
        expect(envelope1.ivBase64, isNot(equals(envelope2.ivBase64)));
        expect(
          envelope1.ciphertextBase64,
          isNot(equals(envelope2.ciphertextBase64)),
        );
      },
    );

    test(
      '3. Decrypting with wrong passphrase throws DecryptionException',
      () async {
        final envelope = await cryptoService.encrypt(
          plaintext: samplePlaintext,
          passphrase: strongPassphrase,
        );

        expect(
          () => cryptoService.decrypt(
            envelope: envelope,
            passphrase: 'WrongPassword!',
          ),
          throwsA(isA<DecryptionException>()),
        );
      },
    );

    test(
      '4. Empty passphrase is rejected for encryption and decryption',
      () async {
        expect(
          () => cryptoService.encrypt(
            plaintext: samplePlaintext,
            passphrase: '   ',
          ),
          throwsA(isA<ValidationException>()),
        );

        final envelope = await cryptoService.encrypt(
          plaintext: samplePlaintext,
          passphrase: strongPassphrase,
        );

        expect(
          () => cryptoService.decrypt(envelope: envelope, passphrase: ''),
          throwsA(isA<DecryptionException>()),
        );
      },
    );

    test('5. Iterations below minimum 1000 is rejected', () async {
      expect(
        () => cryptoService.encrypt(
          plaintext: samplePlaintext,
          passphrase: strongPassphrase,
          iterations: 500,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      '6. Tampering with ciphertext triggers MAC authentication failure',
      () async {
        final envelope = await cryptoService.encrypt(
          plaintext: samplePlaintext,
          passphrase: strongPassphrase,
        );

        // Flip byte in ciphertext
        final modifiedEnvelope = EncryptedVaultEnvelope(
          iterations: envelope.iterations,
          saltBase64: envelope.saltBase64,
          ivBase64: envelope.ivBase64,
          ciphertextBase64: 'AAAA${envelope.ciphertextBase64.substring(4)}',
          macBase64: envelope.macBase64,
        );

        expect(
          () => cryptoService.decrypt(
            envelope: modifiedEnvelope,
            passphrase: strongPassphrase,
          ),
          throwsA(isA<DecryptionException>()),
        );
      },
    );

    test('7. Tampering with IV triggers MAC authentication failure', () async {
      final envelope = await cryptoService.encrypt(
        plaintext: samplePlaintext,
        passphrase: strongPassphrase,
      );

      final modifiedEnvelope = EncryptedVaultEnvelope(
        iterations: envelope.iterations,
        saltBase64: envelope.saltBase64,
        ivBase64: 'AAAAAAAAAAAAAAAAAAAAAA==',
        ciphertextBase64: envelope.ciphertextBase64,
        macBase64: envelope.macBase64,
      );

      expect(
        () => cryptoService.decrypt(
          envelope: modifiedEnvelope,
          passphrase: strongPassphrase,
        ),
        throwsA(isA<DecryptionException>()),
      );
    });

    test(
      '8. Corrupted Base64 strings throw CorruptedBackupException',
      () async {
        const corruptedEnvelope = EncryptedVaultEnvelope(
          iterations: 10000,
          saltBase64: '!!!NotValidBase64@@@',
          ivBase64: '!!!NotValidBase64@@@',
          ciphertextBase64: '!!!NotValidBase64@@@',
          macBase64: '!!!NotValidBase64@@@',
        );

        expect(
          () => cryptoService.decrypt(
            envelope: corruptedEnvelope,
            passphrase: strongPassphrase,
          ),
          throwsA(isA<CorruptedBackupException>()),
        );
      },
    );

    test('9. decryptString handles full JSON envelope export', () async {
      final envelope = await cryptoService.encrypt(
        plaintext: samplePlaintext,
        passphrase: strongPassphrase,
      );
      final encodedStr = envelope.toEncodedString();

      final decrypted = await cryptoService.decryptString(
        encryptedData: encodedStr,
        passphrase: strongPassphrase,
      );

      expect(decrypted, equals(samplePlaintext));
    });
  });
}
