import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/categories/domain/models/category.dart';
import 'package:pocketledger/features/data_vault/models/backup_payload.dart';
import 'package:pocketledger/features/data_vault/models/data_vault_exception.dart';
import 'package:pocketledger/features/data_vault/services/backup_serializer.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

void main() {
  const serializer = BackupSerializer();
  final testDate = DateTime(2026, 9, 25, 10, 0, 0);

  final sampleTransactions = [
    Transaction(
      id: 'tx-1',
      type: TransactionType.expense,
      amountInCents: 1500,
      category: 'food',
      date: testDate,
      note: 'Coffee',
      createdAt: testDate,
    ),
    Transaction(
      id: 'tx-2',
      type: TransactionType.income,
      amountInCents: 250000,
      category: 'salary',
      date: testDate,
      note: 'Monthly salary',
      createdAt: testDate,
    ),
  ];

  final sampleCategories = [
    Category(id: 'food', name: 'Food', isIncome: false),
    Category(id: 'salary', name: 'Salary', isIncome: true),
  ];

  group('BackupSerializer — Schema & Validation Tests', () {
    test('1. Valid payload serializes and deserializes cleanly', () {
      final payload = BackupPayload(
        createdAt: testDate,
        transactions: sampleTransactions,
        categories: sampleCategories,
      );

      final jsonStr = serializer.serialize(payload);
      expect(jsonStr, contains('"schemaVersion": 1'));
      expect(jsonStr, contains('"Coffee"'));
      expect(jsonStr, contains('"Monthly salary"'));

      final restored = serializer.deserialize(jsonStr);
      expect(restored.schemaVersion, 1);
      expect(restored.transactions.length, 2);
      expect(restored.categories.length, 2);
      expect(restored.transactions[0].id, 'tx-1');
      expect(restored.transactions[0].amountInCents, 1500);
      expect(restored.transactions[0].type, TransactionType.expense);
      expect(restored.transactions[1].type, TransactionType.income);
    });

    test('2. Empty JSON string throws CorruptedBackupException', () {
      expect(
        () => serializer.deserialize(''),
        throwsA(isA<CorruptedBackupException>()),
      );
      expect(
        () => serializer.deserialize('   '),
        throwsA(isA<CorruptedBackupException>()),
      );
    });

    test('3. Malformed JSON syntax throws CorruptedBackupException', () {
      expect(
        () => serializer.deserialize('{ invalid json'),
        throwsA(isA<CorruptedBackupException>()),
      );
    });

    test('4. Non-map JSON top-level throws ValidationException', () {
      expect(
        () => serializer.deserialize('["some", "array"]'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('5. Missing schemaVersion throws UnsupportedSchemaException', () {
      const json =
          '{"createdAt":"2026-09-25T10:00:00Z","transactions":[],"categories":[]}';
      expect(
        () => serializer.deserialize(json),
        throwsA(isA<UnsupportedSchemaException>()),
      );
    });

    test('6. Unsupported schemaVersion throws UnsupportedSchemaException', () {
      const json =
          '{"schemaVersion":99,"createdAt":"2026-09-25T10:00:00Z","transactions":[],"categories":[]}';
      expect(
        () => serializer.deserialize(json),
        throwsA(isA<UnsupportedSchemaException>()),
      );
    });

    test('7. Missing or invalid createdAt throws ValidationException', () {
      const missingCreatedAt =
          '{"schemaVersion":1,"transactions":[],"categories":[]}';
      expect(
        () => serializer.deserialize(missingCreatedAt),
        throwsA(isA<ValidationException>()),
      );

      const invalidCreatedAt =
          '{"schemaVersion":1,"createdAt":"not-a-date","transactions":[],"categories":[]}';
      expect(
        () => serializer.deserialize(invalidCreatedAt),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      '8. Missing categories or transactions collections throws ValidationException',
      () {
        const missingCategories =
            '{"schemaVersion":1,"createdAt":"2026-09-25T10:00:00Z","transactions":[]}';
        expect(
          () => serializer.deserialize(missingCategories),
          throwsA(isA<ValidationException>()),
        );

        const missingTransactions =
            '{"schemaVersion":1,"createdAt":"2026-09-25T10:00:00Z","categories":[]}';
        expect(
          () => serializer.deserialize(missingTransactions),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('9. Invalid transaction type throws ValidationException', () {
      const invalidTypeJson = '''
      {
        "schemaVersion": 1,
        "createdAt": "2026-09-25T10:00:00Z",
        "categories": [],
        "transactions": [
          {
            "id": "tx-1",
            "type": "invalid_type",
            "amountInCents": 100,
            "category": "food",
            "date": "2026-09-25T10:00:00Z",
            "createdAt": "2026-09-25T10:00:00Z"
          }
        ]
      }
      ''';
      expect(
        () => serializer.deserialize(invalidTypeJson),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. Negative transaction amount throws ValidationException', () {
      const negativeAmountJson = '''
      {
        "schemaVersion": 1,
        "createdAt": "2026-09-25T10:00:00Z",
        "categories": [],
        "transactions": [
          {
            "id": "tx-1",
            "type": "expense",
            "amountInCents": -500,
            "category": "food",
            "date": "2026-09-25T10:00:00Z",
            "createdAt": "2026-09-25T10:00:00Z"
          }
        ]
      }
      ''';
      expect(
        () => serializer.deserialize(negativeAmountJson),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. Duplicate transaction IDs throw ValidationException', () {
      const duplicateTxJson = '''
      {
        "schemaVersion": 1,
        "createdAt": "2026-09-25T10:00:00Z",
        "categories": [],
        "transactions": [
          {
            "id": "duplicate-tx-id",
            "type": "expense",
            "amountInCents": 500,
            "category": "food",
            "date": "2026-09-25T10:00:00Z",
            "createdAt": "2026-09-25T10:00:00Z"
          },
          {
            "id": "duplicate-tx-id",
            "type": "income",
            "amountInCents": 1000,
            "category": "salary",
            "date": "2026-09-25T10:00:00Z",
            "createdAt": "2026-09-25T10:00:00Z"
          }
        ]
      }
      ''';
      expect(
        () => serializer.deserialize(duplicateTxJson),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. Duplicate category IDs throw ValidationException', () {
      const duplicateCatJson = '''
      {
        "schemaVersion": 1,
        "createdAt": "2026-09-25T10:00:00Z",
        "categories": [
          {"id": "cat-dup", "name": "Category 1", "isIncome": true},
          {"id": "cat-dup", "name": "Category 2", "isIncome": false}
        ],
        "transactions": []
      }
      ''';
      expect(
        () => serializer.deserialize(duplicateCatJson),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. Empty collections backup validates successfully', () {
      const emptyBackupJson = '''
      {
        "schemaVersion": 1,
        "createdAt": "2026-09-25T10:00:00Z",
        "categories": [],
        "transactions": []
      }
      ''';
      final payload = serializer.deserialize(emptyBackupJson);
      expect(payload.schemaVersion, 1);
      expect(payload.transactions, isEmpty);
      expect(payload.categories, isEmpty);
    });
  });
}
