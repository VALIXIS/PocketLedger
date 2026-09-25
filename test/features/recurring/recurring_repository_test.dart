import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/recurring/data/datasources/recurring_local_data_source.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';
import 'package:pocketledger/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:pocketledger/features/recurring/domain/repositories/recurring_repository.dart';

void main() {
  late Directory tempDir;
  late RecurringLocalDataSource dataSource;
  late RecurringRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recurring_repo_test_');
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
    repository = RecurringRepositoryImpl(localDataSource: dataSource);
  });

  tearDown(() async {
    await dataSource.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  RecurringTransaction createSampleRecurring() => RecurringTransaction(
    id: 'sub-aws-1',
    name: 'AWS Cloud Hosting',
    amountInCents: 4500,
    isIncome: false,
    category: 'bills',
    recurrenceType: RecurrenceType.monthly,
    startDate: DateTime(2026, 1, 1),
    nextOccurrence: DateTime(2026, 9, 15),
    status: RecurringTransactionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userId: 'user-cloud',
  );

  test('addRecurringTransaction stores a record successfully', () async {
    final sample = createSampleRecurring();
    await repository.addRecurringTransaction(sample);

    expect(await repository.containsRecurringTransaction('sub-aws-1'), isTrue);
    final fetched = await repository.getRecurringTransaction('sub-aws-1');
    expect(fetched, isNotNull);
    expect(fetched!.name, 'AWS Cloud Hosting');
    expect(fetched.amountInCents, 4500);
  });

  test('addRecurringTransaction throws StateError on duplicate ID', () async {
    final sample = createSampleRecurring();
    await repository.addRecurringTransaction(sample);

    final duplicate = createSampleRecurring();
    expect(
      () => repository.addRecurringTransaction(duplicate),
      throwsStateError,
    );
  });

  test('updateRecurringTransaction modifies record successfully', () async {
    final sample = createSampleRecurring();
    await repository.addRecurringTransaction(sample);

    final modified = sample.copyWith(amountInCents: 5200);
    await repository.updateRecurringTransaction(modified);

    final fetched = await repository.getRecurringTransaction('sub-aws-1');
    expect(fetched!.amountInCents, 5200);
  });

  test(
    'updateRecurringTransaction throws StateError when record not found',
    () async {
      final sample = createSampleRecurring();
      expect(
        () => repository.updateRecurringTransaction(sample),
        throwsStateError,
      );
    },
  );

  test('user filtering and active/due queries work properly', () async {
    final recurringUser1 = createSampleRecurring();
    final recurringUser2 = RecurringTransaction(
      id: 'sub-salary-1',
      name: 'Monthly Client Retainer',
      amountInCents: 200000,
      isIncome: true,
      category: 'income_other',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 1, 1),
      nextOccurrence: DateTime(2026, 9, 28),
      status: RecurringTransactionStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      userId: 'user-client',
    );

    await repository.addRecurringTransaction(recurringUser1);
    await repository.addRecurringTransaction(recurringUser2);

    final all = await repository.getAllRecurringTransactions();
    expect(all.length, 2);

    final cloudTx = await repository.getRecurringTransactionsForUser(
      'user-cloud',
    );
    expect(cloudTx.length, 1);
    expect(cloudTx.first.id, 'sub-aws-1');

    final active = await repository.getActiveRecurringTransactions();
    expect(active.length, 2);

    final dueBySept20 = await repository.getDueTransactions(
      DateTime(2026, 9, 20),
    );
    expect(dueBySept20.length, 1);
    expect(dueBySept20.first.id, 'sub-aws-1');
  });

  test('deleteRecurringTransaction removes record safely', () async {
    final sample = createSampleRecurring();
    await repository.addRecurringTransaction(sample);
    expect(await repository.containsRecurringTransaction('sub-aws-1'), isTrue);

    await repository.deleteRecurringTransaction('sub-aws-1');
    expect(await repository.containsRecurringTransaction('sub-aws-1'), isFalse);
    expect(await repository.getRecurringTransaction('sub-aws-1'), isNull);
  });
}
