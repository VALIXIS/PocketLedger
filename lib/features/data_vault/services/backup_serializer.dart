import 'dart:convert';
import '../models/backup_payload.dart';
import '../models/data_vault_exception.dart';

/// Serializer and strict schema validator for PocketLedger backup payloads.
class BackupSerializer {
  static const int currentSchemaVersion = 1;
  static const List<int> supportedSchemaVersions = [1];

  const BackupSerializer();

  /// Serializes a [BackupPayload] into a formatted JSON string.
  String serialize(BackupPayload payload) {
    return const JsonEncoder.withIndent('  ').convert(payload.toJson());
  }

  /// Deserializes and validates a JSON string into a [BackupPayload].
  ///
  /// Throws [ValidationException], [UnsupportedSchemaException], or [CorruptedBackupException] on invalid input.
  BackupPayload deserialize(String jsonString) {
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      throw const CorruptedBackupException('Backup JSON string is empty.');
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw CorruptedBackupException('Invalid JSON syntax: ${e.message}', e);
    }

    if (parsed is! Map<String, dynamic>) {
      throw const ValidationException(
        'Top-level JSON backup must be an object map.',
      );
    }

    return validateAndParseJson(parsed);
  }

  /// Validates a raw JSON map against schema version and entity constraints, returning a clean [BackupPayload].
  BackupPayload validateAndParseJson(Map<String, dynamic> map) {
    // 1. Schema Version Validation
    if (!map.containsKey('schemaVersion')) {
      throw const UnsupportedSchemaException(
        'Missing "schemaVersion" in backup metadata.',
      );
    }

    final schemaVersion = map['schemaVersion'];
    if (schemaVersion is! int) {
      throw const UnsupportedSchemaException(
        'Field "schemaVersion" must be an integer.',
      );
    }

    if (!supportedSchemaVersions.contains(schemaVersion)) {
      throw UnsupportedSchemaException(
        'Unsupported schemaVersion ($schemaVersion). Supported versions: $supportedSchemaVersions.',
      );
    }

    // 2. Metadata / Creation Date Validation
    if (!map.containsKey('createdAt')) {
      throw const ValidationException(
        'Missing required metadata field "createdAt".',
        field: 'createdAt',
      );
    }

    final createdAtRaw = map['createdAt'];
    if (createdAtRaw is! String || DateTime.tryParse(createdAtRaw) == null) {
      throw const ValidationException(
        'Invalid ISO 8601 date string for "createdAt".',
        field: 'createdAt',
      );
    }

    // 3. Collections Presence Validation
    if (!map.containsKey('categories')) {
      throw const ValidationException(
        'Missing required collection "categories".',
        field: 'categories',
      );
    }
    if (map['categories'] is! List) {
      throw const ValidationException(
        'Collection "categories" must be a JSON array.',
        field: 'categories',
      );
    }

    if (!map.containsKey('transactions')) {
      throw const ValidationException(
        'Missing required collection "transactions".',
        field: 'transactions',
      );
    }
    if (map['transactions'] is! List) {
      throw const ValidationException(
        'Collection "transactions" must be a JSON array.',
        field: 'transactions',
      );
    }

    // 4. Categories Validation & Duplicate ID Check
    final categoriesList = map['categories'] as List<dynamic>;
    final categoryIds = <String>{};

    for (var i = 0; i < categoriesList.length; i++) {
      final item = categoriesList[i];
      if (item is! Map<String, dynamic>) {
        throw ValidationException(
          'Category at index $i is not a valid object.',
          field: 'categories[$i]',
        );
      }

      // ID
      final id = item['id'];
      if (id is! String || id.trim().isEmpty) {
        throw ValidationException(
          'Category at index $i has missing or empty "id".',
          field: 'categories[$i].id',
        );
      }
      if (categoryIds.contains(id)) {
        throw ValidationException(
          'Duplicate category id "$id" found at index $i.',
          field: 'categories[$i].id',
        );
      }
      categoryIds.add(id);

      // Name
      final name = item['name'];
      if (name is! String || name.trim().isEmpty) {
        throw ValidationException(
          'Category "$id" has missing or empty "name".',
          field: 'categories[$i].name',
        );
      }

      // isIncome
      final isIncome = item['isIncome'];
      if (isIncome is! bool) {
        throw ValidationException(
          'Category "$id" has non-boolean "isIncome".',
          field: 'categories[$i].isIncome',
        );
      }
    }

    // 5. Transactions Validation & Duplicate ID Check
    final transactionsList = map['transactions'] as List<dynamic>;
    final transactionIds = <String>{};

    for (var i = 0; i < transactionsList.length; i++) {
      final item = transactionsList[i];
      if (item is! Map<String, dynamic>) {
        throw ValidationException(
          'Transaction at index $i is not a valid object.',
          field: 'transactions[$i]',
        );
      }

      // ID
      final id = item['id'];
      if (id is! String || id.trim().isEmpty) {
        throw ValidationException(
          'Transaction at index $i has missing or empty "id".',
          field: 'transactions[$i].id',
        );
      }
      if (transactionIds.contains(id)) {
        throw ValidationException(
          'Duplicate transaction id "$id" found at index $i.',
          field: 'transactions[$i].id',
        );
      }
      transactionIds.add(id);

      // Type
      final type = item['type'];
      if (type is! String || (type != 'income' && type != 'expense')) {
        throw ValidationException(
          'Transaction "$id" has invalid type "$type". Must be "income" or "expense".',
          field: 'transactions[$i].type',
        );
      }

      // AmountInCents
      final amountInCents = item['amountInCents'];
      if (amountInCents is! num ||
          amountInCents.toInt() != amountInCents ||
          amountInCents < 0) {
        throw ValidationException(
          'Transaction "$id" has invalid amountInCents ($amountInCents). Must be a non-negative integer.',
          field: 'transactions[$i].amountInCents',
        );
      }

      // Category
      final cat = item['category'];
      if (cat is! String || cat.trim().isEmpty) {
        throw ValidationException(
          'Transaction "$id" has missing or empty "category".',
          field: 'transactions[$i].category',
        );
      }

      // Date
      final dateRaw = item['date'];
      if (dateRaw is! String || DateTime.tryParse(dateRaw) == null) {
        throw ValidationException(
          'Transaction "$id" has invalid date "$dateRaw". Must be an ISO 8601 string.',
          field: 'transactions[$i].date',
        );
      }

      // CreatedAt
      final createdRaw = item['createdAt'];
      if (createdRaw is! String || DateTime.tryParse(createdRaw) == null) {
        throw ValidationException(
          'Transaction "$id" has invalid createdAt "$createdRaw". Must be an ISO 8601 string.',
          field: 'transactions[$i].createdAt',
        );
      }

      // Note (optional, if present must be String)
      final note = item['note'];
      if (note != null && note is! String) {
        throw ValidationException(
          'Transaction "$id" has invalid note type.',
          field: 'transactions[$i].note',
        );
      }
    }

    // 6. Budgets Validation (if present)
    if (map.containsKey('budgets')) {
      final budgetsList = map['budgets'];
      if (budgetsList is! List) {
        throw const ValidationException(
          'Field "budgets" must be an array if provided.',
          field: 'budgets',
        );
      }
    }

    return BackupPayload.fromJson(map);
  }
}
