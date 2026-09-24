import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/recurring/data/datasources/recurring_local_data_source.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';

void main() {
  late Directory tempDir;
  late HiveRecurringLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recurring_ds_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(RecurringTransactionStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(RecurringTransactionAdapter());
    }

    dataSource = HiveRecurringLocalDataSource();
    await dataSource.init();
  });

  tearDown(() async {
    await dataSource.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  RecurringTransaction createActiveDueTx() => RecurringTransaction(
        id: 'rec-1',
        name: 'Netflix Subscription',
        amountInCents: 1599,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 9, 20),
        status: RecurringTransactionStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        userId: 'user-alpha',
      );

  RecurringTransaction createActiveFutureTx() => RecurringTransaction(
        id: 'rec-2',
        name: 'Spotify Family',
        amountInCents: 1999,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 9, 30),
        status: RecurringTransactionStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        userId: 'user-beta',
      );

  RecurringTransaction createPausedTx() => RecurringTransaction(
        id: 'rec-3',
        name: 'Gym Membership',
        amountInCents: 4500,
        category: 'health',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 9, 15),
        status: RecurringTransactionStatus.paused,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        userId: 'user-alpha',
      );

  test('save, get, and contains work correctly', () async {
    expect(await dataSource.containsRecurringTransaction('rec-1'), isFalse);
    expect(await dataSource.getRecurringTransaction('rec-1'), isNull);

    final activeDueTx = createActiveDueTx();
    await dataSource.saveRecurringTransaction(activeDueTx);

    expect(await dataSource.containsRecurringTransaction('rec-1'), isTrue);
    final fetched = await dataSource.getRecurringTransaction('rec-1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'rec-1');
    expect(fetched.name, 'Netflix Subscription');
    expect(fetched.amountInCents, 1599);
  });

  test(
    'getAll, getRecurringTransactionsForUser, and getActiveRecurringTransactions work',
    () async {
      await dataSource.saveRecurringTransaction(createActiveDueTx());
      await dataSource.saveRecurringTransaction(createActiveFutureTx());
      await dataSource.saveRecurringTransaction(createPausedTx());

      final all = await dataSource.getAllRecurringTransactions();
      expect(all.length, 3);

      final userAlpha = await dataSource.getRecurringTransactionsForUser(
        'user-alpha',
      );
      expect(userAlpha.length, 2);

      final activeOnly = await dataSource.getActiveRecurringTransactions();
      expect(activeOnly.length, 2);
      expect(activeOnly.any((tx) => tx.id == 'rec-3'), isFalse);
    },
  );

  test(
    'getDueTransactions retrieves only active transactions on or before asOf date',
    () async {
      await dataSource.saveRecurringTransaction(createActiveDueTx()); // due Sept 20
      await dataSource.saveRecurringTransaction(createActiveFutureTx()); // due Sept 30
      await dataSource.saveRecurringTransaction(createPausedTx()); // paused Sept 15

      final asOfDate = DateTime(2026, 9, 24);
      final due = await dataSource.getDueTransactions(asOfDate);

      expect(due.length, 1);
      expect(due.first.id, 'rec-1');
    },
  );

  test('update and delete modify the box properly', () async {
    final activeDueTx = createActiveDueTx();
    await dataSource.saveRecurringTransaction(activeDueTx);

    final updated = activeDueTx.copyWith(name: 'Netflix 4K Ultra');
    await dataSource.updateRecurringTransaction(updated);

    final fetched = await dataSource.getRecurringTransaction('rec-1');
    expect(fetched!.name, 'Netflix 4K Ultra');

    await dataSource.deleteRecurringTransaction('rec-1');
    expect(await dataSource.containsRecurringTransaction('rec-1'), isFalse);
  });

  test('clear empties the recurring box', () async {
    await dataSource.saveRecurringTransaction(createActiveDueTx());
    await dataSource.saveRecurringTransaction(createActiveFutureTx());
    expect((await dataSource.getAllRecurringTransactions()).length, 2);

    await dataSource.clear();
    expect(await dataSource.getAllRecurringTransactions(), isEmpty);
  });
}
