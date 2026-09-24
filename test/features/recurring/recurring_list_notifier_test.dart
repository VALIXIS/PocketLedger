import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';
import 'package:pocketledger/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:pocketledger/features/recurring/presentation/providers/recurring_list_notifier.dart';

class FakeRecurringRepository implements RecurringRepository {
  final Map<String, RecurringTransaction> _transactions = {};
  bool shouldThrow = false;

  @override
  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    if (shouldThrow) throw Exception('Simulated add failure');
    if (_transactions.containsKey(transaction.id)) {
      throw StateError('ID already exists');
    }
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    if (shouldThrow) throw Exception('Simulated update failure');
    if (!_transactions.containsKey(transaction.id)) {
      throw StateError('ID not found');
    }
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    if (shouldThrow) throw Exception('Simulated delete failure');
    _transactions.remove(id);
  }

  @override
  Future<RecurringTransaction?> getRecurringTransaction(String id) async {
    if (shouldThrow) throw Exception('Simulated get failure');
    return _transactions[id];
  }

  @override
  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    if (shouldThrow) throw Exception('Simulated get all failure');
    return _transactions.values.toList();
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsForUser(
    String userId,
  ) async {
    if (shouldThrow) throw Exception('Simulated get user failure');
    return _transactions.values.where((tx) => tx.userId == userId).toList();
  }

  @override
  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    if (shouldThrow) throw Exception('Simulated get active failure');
    return _transactions.values.where((tx) => tx.isActive).toList();
  }

  @override
  Future<List<RecurringTransaction>> getDueTransactions([
    DateTime? asOf,
  ]) async {
    if (shouldThrow) throw Exception('Simulated get due failure');
    final target = asOf ?? DateTime.now();
    return _transactions.values
        .where((tx) => tx.isActive && !tx.nextOccurrence.isAfter(target))
        .toList();
  }

  @override
  Future<bool> containsRecurringTransaction(String id) async {
    return _transactions.containsKey(id);
  }
}

void main() {
  late FakeRecurringRepository repository;
  late RecurringListNotifier notifier;

  setUp(() {
    repository = FakeRecurringRepository();
    notifier = RecurringListNotifier(repository: repository);
  });

  tearDown(() {
    notifier.dispose();
  });

  RecurringTransaction createTx({
    String id = 'rec-1',
    String name = 'Spotify',
    int amount = 1099,
    String userId = '',
    RecurringTransactionStatus status = RecurringTransactionStatus.active,
  }) {
    return RecurringTransaction(
      id: id,
      name: name,
      amountInCents: amount,
      category: 'entertainment',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 1, 1),
      nextOccurrence: DateTime(2026, 9, 25),
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      userId: userId,
    );
  }

  test(
    'Initial state loads recurring transactions into loaded state',
    () async {
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.status, RecurringListStatus.loaded);
      expect(notifier.state.transactions, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasError, isFalse);
    },
  );

  test('addRecurringTransaction stores and reloads state', () async {
    final tx = createTx();
    await notifier.addRecurringTransaction(tx);

    expect(notifier.state.transactions.length, 1);
    expect(notifier.state.transactions.first.id, 'rec-1');
    expect(notifier.state.transactions.first.name, 'Spotify');
  });

  test('updateRecurringTransaction modifies state', () async {
    final tx = createTx();
    await notifier.addRecurringTransaction(tx);

    final modified = tx.copyWith(name: 'Spotify Family', amountInCents: 1699);
    await notifier.updateRecurringTransaction(modified);

    expect(notifier.state.transactions.first.name, 'Spotify Family');
    expect(notifier.state.transactions.first.amountInCents, 1699);
  });

  test('deleteRecurringTransaction removes transaction from state', () async {
    final tx = createTx();
    await notifier.addRecurringTransaction(tx);
    expect(notifier.state.transactions.length, 1);

    await notifier.deleteRecurringTransaction('rec-1');
    expect(notifier.state.transactions, isEmpty);
  });

  test('pause, resume, and cancel update status properly', () async {
    final tx = createTx();
    await notifier.addRecurringTransaction(tx);

    // Pause
    await notifier.pauseRecurringTransaction('rec-1');
    expect(
      notifier.state.transactions.first.status,
      RecurringTransactionStatus.paused,
    );

    // Resume
    await notifier.resumeRecurringTransaction('rec-1');
    expect(
      notifier.state.transactions.first.status,
      RecurringTransactionStatus.active,
    );

    // Cancel
    await notifier.cancelRecurringTransaction('rec-1');
    expect(
      notifier.state.transactions.first.status,
      RecurringTransactionStatus.cancelled,
    );
  });

  test('user filtering separates user recurring transactions', () async {
    await repository.addRecurringTransaction(
      createTx(id: 'r-1', userId: 'user-alpha'),
    );
    await repository.addRecurringTransaction(
      createTx(id: 'r-2', userId: 'user-beta'),
    );

    notifier.setUserId('user-alpha');
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.transactions.length, 1);
    expect(notifier.state.transactions.first.id, 'r-1');

    notifier.setUserId('user-beta');
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.transactions.length, 1);
    expect(notifier.state.transactions.first.id, 'r-2');
  });

  test('error handling captures exceptions without crashing', () async {
    await notifier.addRecurringTransaction(createTx(id: 'r-1'));

    repository.shouldThrow = true;
    await notifier.loadRecurringTransactions();

    expect(notifier.state.status, RecurringListStatus.error);
    expect(notifier.state.hasError, isTrue);
    expect(notifier.state.errorMessage, isNotNull);
  });

  test('refresh reloads list', () async {
    await repository.addRecurringTransaction(createTx(id: 'r-1'));
    await notifier.refresh();

    expect(notifier.state.transactions.length, 1);
    expect(notifier.state.status, RecurringListStatus.loaded);
  });
}
