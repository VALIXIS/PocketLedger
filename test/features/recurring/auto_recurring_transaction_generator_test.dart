import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocketledger/features/recurring/data/datasources/recurring_local_data_source.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';
import 'package:pocketledger/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:pocketledger/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:pocketledger/features/recurring/services/auto_recurring_transaction_generator.dart';
import 'package:pocketledger/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:pocketledger/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';
import 'package:pocketledger/features/transactions/domain/repositories/transaction_repository.dart';

class FailingTransactionRepository implements TransactionRepository {
  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<List<Transaction>> getTransactions() async => [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    throw Exception('Simulated database write error');
  }
}

void main() {
  late Directory tempDir;
  late RecurringLocalDataSource recurringDataSource;
  late RecurringRepository recurringRepository;
  late TransactionLocalDataSource transactionDataSource;
  late TransactionRepository transactionRepository;
  late AutoRecurringTransactionGenerator generator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('generator_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(RecurringTransactionStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(RecurringTransactionAdapter());
    }

    recurringDataSource = HiveRecurringLocalDataSource();
    await recurringDataSource.init();
    recurringRepository = RecurringRepositoryImpl(
      localDataSource: recurringDataSource,
    );

    transactionDataSource = HiveTransactionLocalDataSource();
    transactionRepository = TransactionRepositoryImpl(
      localDataSource: transactionDataSource,
    );

    generator = AutoRecurringTransactionGenerator(
      recurringRepository: recurringRepository,
      transactionRepository: transactionRepository,
    );
  });

  tearDown(() async {
    await recurringDataSource.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Due recurring transaction generates a normal transaction with exact properties',
    () async {
      final recurringTx = RecurringTransaction(
        id: 'rec-netflix-1',
        name: 'Netflix 4K',
        amountInCents: 1999,
        isIncome: false,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 8, 20),
        nextOccurrence: DateTime(2026, 9, 20),
        status: RecurringTransactionStatus.active,
        createdAt: DateTime(2026, 8, 20),
        updatedAt: DateTime(2026, 8, 20),
        userId: 'user-alice',
      );
      await recurringRepository.addRecurringTransaction(recurringTx);

      final generated = await generator.generateDueTransactions(
        asOf: DateTime(2026, 9, 24),
      );

      expect(generated.length, 1);
      final tx = generated.first;
      expect(tx.amountInCents, 1999);
      expect(tx.category, 'entertainment');
      expect(tx.type, TransactionType.expense);
      expect(tx.date.year, 2026);
      expect(tx.date.month, 9);
      expect(tx.date.day, 20);
      expect(tx.note, 'Netflix 4K');

      // Check normal transaction repository has stored it
      final savedTransactions = await transactionRepository.getTransactions();
      expect(savedTransactions.length, 1);
      expect(savedTransactions.first.id, tx.id);

      // Verify recurring transaction has advanced to next occurrence (October 20)
      final updatedRec = await recurringRepository.getRecurringTransaction(
        'rec-netflix-1',
      );
      expect(updatedRec!.nextOccurrence.year, 2026);
      expect(updatedRec.nextOccurrence.month, 10);
      expect(updatedRec.nextOccurrence.day, 20);
      expect(updatedRec.status, RecurringTransactionStatus.active);
    },
  );

  test('Income recurring transactions generate income transactions', () async {
    final incomeRec = RecurringTransaction(
      id: 'rec-salary-1',
      name: 'Client Retainer',
      amountInCents: 350000,
      isIncome: true,
      category: 'salary',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 8, 1),
      nextOccurrence: DateTime(2026, 9, 1),
      status: RecurringTransactionStatus.active,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await recurringRepository.addRecurringTransaction(incomeRec);

    final generated = await generator.generateDueTransactions(
      asOf: DateTime(2026, 9, 5),
    );

    expect(generated.length, 1);
    expect(generated.first.type, TransactionType.income);
    expect(generated.first.amountInCents, 350000);
  });

  test('Paused and cancelled recurring transactions are ignored', () async {
    final pausedRec = RecurringTransaction(
      id: 'rec-paused',
      name: 'Paused Service',
      amountInCents: 1000,
      category: 'bills',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 8, 1),
      nextOccurrence: DateTime(2026, 9, 1),
      status: RecurringTransactionStatus.paused,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    final cancelledRec = RecurringTransaction(
      id: 'rec-cancelled',
      name: 'Cancelled Service',
      amountInCents: 1000,
      category: 'bills',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 8, 1),
      nextOccurrence: DateTime(2026, 9, 1),
      status: RecurringTransactionStatus.cancelled,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    await recurringRepository.addRecurringTransaction(pausedRec);
    await recurringRepository.addRecurringTransaction(cancelledRec);

    final generated = await generator.generateDueTransactions(
      asOf: DateTime(2026, 9, 24),
    );
    expect(generated, isEmpty);

    final txs = await transactionRepository.getTransactions();
    expect(txs, isEmpty);
  });

  test('Future occurrences are not generated prematurely', () async {
    final futureRec = RecurringTransaction(
      id: 'rec-future',
      name: 'Future Bill',
      amountInCents: 5000,
      category: 'bills',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 10, 1),
      nextOccurrence: DateTime(2026, 10, 1),
      status: RecurringTransactionStatus.active,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );
    await recurringRepository.addRecurringTransaction(futureRec);

    final generated = await generator.generateDueTransactions(
      asOf: DateTime(2026, 9, 24),
    );
    expect(generated, isEmpty);

    final savedRec = await recurringRepository.getRecurringTransaction(
      'rec-future',
    );
    expect(savedRec!.nextOccurrence, DateTime(2026, 10, 1));
  });

  test(
    'Missed occurrences are completely caught up and scheduled accurately',
    () async {
      // Weekly payment starting Sept 1.
      // App opened on Sept 24.
      // Occurrences due: Sept 1, Sept 8, Sept 15, Sept 22 (4 occurrences)
      // Next occurrence should be Sept 29 (future)
      final weeklyRec = RecurringTransaction(
        id: 'rec-weekly-box',
        name: 'Meal Kit Subscription',
        amountInCents: 4500,
        category: 'food',
        recurrenceType: RecurrenceType.weekly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
        status: RecurringTransactionStatus.active,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      await recurringRepository.addRecurringTransaction(weeklyRec);

      final generated = await generator.generateDueTransactions(
        asOf: DateTime(2026, 9, 24),
      );

      expect(generated.length, 4);
      expect(generated[0].date.day, 1);
      expect(generated[1].date.day, 8);
      expect(generated[2].date.day, 15);
      expect(generated[3].date.day, 22);

      final updatedWeekly = await recurringRepository.getRecurringTransaction(
        'rec-weekly-box',
      );
      expect(updatedWeekly!.nextOccurrence.day, 29);
      expect(updatedWeekly.nextOccurrence.month, 9);
      expect(updatedWeekly.status, RecurringTransactionStatus.active);
    },
  );

  test(
    'EndDate is strictly respected and status marks cancelled when complete',
    () async {
      // Weekly recurrence with endDate = Sept 15.
      // Next occurrence: Sept 1.
      // App opened: Sept 24.
      // Expected generated occurrences: Sept 1, Sept 8, Sept 15 (3 occurrences, not Sept 22).
      final finiteRec = RecurringTransaction(
        id: 'rec-finite',
        name: 'Trial Period Gym',
        amountInCents: 3000,
        category: 'health',
        recurrenceType: RecurrenceType.weekly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 15),
        status: RecurringTransactionStatus.active,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      await recurringRepository.addRecurringTransaction(finiteRec);

      final generated = await generator.generateDueTransactions(
        asOf: DateTime(2026, 9, 24),
      );

      expect(generated.length, 3);
      expect(generated.map((tx) => tx.date.day).toList(), [1, 8, 15]);

      final updatedRec = await recurringRepository.getRecurringTransaction(
        'rec-finite',
      );
      expect(updatedRec!.status, RecurringTransactionStatus.cancelled);
      expect(updatedRec.isActive, isFalse);
    },
  );

  test(
    'Running generator repeatedly is idempotent and creates NO duplicates',
    () async {
      final recurringTx = RecurringTransaction(
        id: 'rec-spotify',
        name: 'Spotify Premium',
        amountInCents: 1099,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 9, 10),
        nextOccurrence: DateTime(2026, 9, 10),
        status: RecurringTransactionStatus.active,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      await recurringRepository.addRecurringTransaction(recurringTx);

      // First run
      final run1 = await generator.generateDueTransactions(
        asOf: DateTime(2026, 9, 24),
      );
      expect(run1.length, 1);

      // Second run immediately after
      final run2 = await generator.generateDueTransactions(
        asOf: DateTime(2026, 9, 24),
      );
      expect(run2.length, 0);

      // Verify total transactions in repository is still exactly 1
      final allTxs = await transactionRepository.getTransactions();
      expect(allTxs.length, 1);
    },
  );

  test('Transaction creation failure does NOT advance recurrence', () async {
    final failingGenerator = AutoRecurringTransactionGenerator(
      recurringRepository: recurringRepository,
      transactionRepository: FailingTransactionRepository(),
    );

    final initialDate = DateTime(2026, 9, 10);
    final recurringTx = RecurringTransaction(
      id: 'rec-failing',
      name: 'Failing Sub',
      amountInCents: 1000,
      category: 'bills',
      recurrenceType: RecurrenceType.monthly,
      startDate: initialDate,
      nextOccurrence: initialDate,
      status: RecurringTransactionStatus.active,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );
    await recurringRepository.addRecurringTransaction(recurringTx);

    final generated = await failingGenerator.generateDueTransactions(
      asOf: DateTime(2026, 9, 24),
    );
    expect(generated, isEmpty);

    // Recurrence should not have advanced
    final storedRec = await recurringRepository.getRecurringTransaction(
      'rec-failing',
    );
    expect(storedRec!.nextOccurrence, initialDate);
  });
}
