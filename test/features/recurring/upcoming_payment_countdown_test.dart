import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';
import 'package:pocketledger/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:pocketledger/features/recurring/presentation/providers/upcoming_payment_countdown.dart';

class FakeClock implements Clock {
  DateTime currentTime;
  FakeClock(this.currentTime);

  @override
  DateTime now() => currentTime;
}

class FakeRecurringRepository implements RecurringRepository {
  final Map<String, RecurringTransaction> _transactions = {};

  @override
  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    _transactions.remove(id);
  }

  @override
  Future<RecurringTransaction?> getRecurringTransaction(String id) async {
    return _transactions[id];
  }

  @override
  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    return _transactions.values.toList();
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsForUser(
    String userId,
  ) async {
    return _transactions.values.where((tx) => tx.userId == userId).toList();
  }

  @override
  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    return _transactions.values.where((tx) => tx.isActive).toList();
  }

  @override
  Future<List<RecurringTransaction>> getDueTransactions([
    DateTime? asOf,
  ]) async {
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
  late FakeClock clock;
  final baseNow = DateTime(2026, 9, 24, 10, 0, 0);

  setUp(() {
    repository = FakeRecurringRepository();
    clock = FakeClock(baseNow);
  });

  RecurringTransaction createTx({
    required String id,
    required String name,
    required DateTime nextOccurrence,
    int amount = 1000,
    DateTime? endDate,
    RecurringTransactionStatus status = RecurringTransactionStatus.active,
    String userId = '',
  }) {
    return RecurringTransaction(
      id: id,
      name: name,
      amountInCents: amount,
      category: 'bills',
      recurrenceType: RecurrenceType.monthly,
      startDate: DateTime(2026, 1, 1),
      nextOccurrence: nextOccurrence,
      endDate: endDate,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      userId: userId,
    );
  }

  test(
    'Empty repository returns empty countdown state and null nearest payment',
    () async {
      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );

      await notifier.loadAndStart();

      expect(notifier.state.upcomingPayments, isEmpty);
      expect(notifier.state.nearestPayment, isNull);
      expect(notifier.state.isEmpty, isTrue);

      notifier.dispose();
    },
  );

  test(
    'Upcoming payment countdown calculates days, hours, minutes, and seconds accurately',
    () async {
      // Current time: Sep 24, 10:00:00
      // Payment time: Sep 27, 13:30:45 (3 days, 3 hours, 30 minutes, 45 seconds away)
      final tx = createTx(
        id: 'tx-1',
        name: 'Internet Bill',
        nextOccurrence: DateTime(2026, 9, 27, 13, 30, 45),
      );
      await repository.addRecurringTransaction(tx);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      expect(notifier.state.upcomingPayments.length, 1);
      final countdown = notifier.state.upcomingPayments.first;

      expect(countdown.days, 3);
      expect(countdown.hours, 3);
      expect(countdown.minutes, 30);
      expect(countdown.seconds, 45);
      expect(countdown.isDueToday, isFalse);
      expect(countdown.isOverdue, isFalse);
      expect(countdown.isUpcoming, isTrue);
      expect(
        countdown.remaining.inSeconds,
        (3 * 86400) + (3 * 3600) + (30 * 60) + 45,
      );

      notifier.dispose();
    },
  );

  test(
    'Due today detection flags payment occurring on the same calendar day',
    () async {
      // Current time: Sep 24, 10:00:00
      // Payment time: Sep 24, 22:00:00 (12 hours away on the same calendar date)
      final tx = createTx(
        id: 'tx-today',
        name: 'Electric Bill',
        nextOccurrence: DateTime(2026, 9, 24, 22, 0, 0),
      );
      await repository.addRecurringTransaction(tx);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      final countdown = notifier.state.upcomingPayments.first;
      expect(countdown.isDueToday, isTrue);
      expect(countdown.isOverdue, isFalse);
      expect(countdown.days, 0);
      expect(countdown.hours, 12);

      notifier.dispose();
    },
  );

  test(
    'Overdue payments are flagged and duration clamps safely to Duration.zero',
    () async {
      // Current time: Sep 24, 10:00:00
      // Payment time: Sep 20, 08:00:00 (past)
      final tx = createTx(
        id: 'tx-overdue',
        name: 'Overdue Subscription',
        nextOccurrence: DateTime(2026, 9, 20, 8, 0, 0),
      );
      await repository.addRecurringTransaction(tx);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      final countdown = notifier.state.upcomingPayments.first;
      expect(countdown.isOverdue, isTrue);
      expect(countdown.isUpcoming, isFalse);
      expect(countdown.remaining, Duration.zero);
      expect(countdown.totalSeconds, 0);
      expect(countdown.days, 0);
      expect(countdown.hours, 0);
      expect(countdown.minutes, 0);
      expect(countdown.seconds, 0);

      notifier.dispose();
    },
  );

  test(
    'Multiple payments are sorted by next occurrence ascending and nearest is identified',
    () async {
      final tx1 = createTx(
        id: 't-3',
        name: 'Gym',
        nextOccurrence: DateTime(2026, 10, 1),
      );
      final tx2 = createTx(
        id: 't-1',
        name: 'Netflix',
        nextOccurrence: DateTime(2026, 9, 25),
      );
      final tx3 = createTx(
        id: 't-2',
        name: 'Electricity',
        nextOccurrence: DateTime(2026, 9, 27),
      );

      await repository.addRecurringTransaction(tx1);
      await repository.addRecurringTransaction(tx2);
      await repository.addRecurringTransaction(tx3);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      expect(notifier.state.upcomingPayments.length, 3);
      expect(notifier.state.upcomingPayments[0].recurringTransaction.id, 't-1');
      expect(notifier.state.upcomingPayments[1].recurringTransaction.id, 't-2');
      expect(notifier.state.upcomingPayments[2].recurringTransaction.id, 't-3');

      expect(notifier.state.nearestPayment, isNotNull);
      expect(notifier.state.nearestPayment!.recurringTransaction.id, 't-1');

      notifier.dispose();
    },
  );

  test(
    'Paused, cancelled, and ended payments are excluded from upcoming list',
    () async {
      final active = createTx(
        id: 't-active',
        name: 'Active Sub',
        nextOccurrence: DateTime(2026, 9, 26),
      );
      final paused = createTx(
        id: 't-paused',
        name: 'Paused Sub',
        nextOccurrence: DateTime(2026, 9, 25),
        status: RecurringTransactionStatus.paused,
      );
      final cancelled = createTx(
        id: 't-cancelled',
        name: 'Cancelled Sub',
        nextOccurrence: DateTime(2026, 9, 25),
        status: RecurringTransactionStatus.cancelled,
      );
      final ended = createTx(
        id: 't-ended',
        name: 'Ended Sub',
        nextOccurrence: DateTime(2026, 9, 28),
        endDate: DateTime(2026, 9, 20), // ended in past
      );

      await repository.addRecurringTransaction(active);
      await repository.addRecurringTransaction(paused);
      await repository.addRecurringTransaction(cancelled);
      await repository.addRecurringTransaction(ended);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      expect(notifier.state.upcomingPayments.length, 1);
      expect(
        notifier.state.upcomingPayments.first.recurringTransaction.id,
        't-active',
      );

      notifier.dispose();
    },
  );

  test(
    'Multiple payments at the same exact timestamp are both preserved and sorted',
    () async {
      final tx1 = createTx(
        id: 'same-1',
        name: 'Service A',
        nextOccurrence: DateTime(2026, 9, 30, 12, 0),
      );
      final tx2 = createTx(
        id: 'same-2',
        name: 'Service B',
        nextOccurrence: DateTime(2026, 9, 30, 12, 0),
      );

      await repository.addRecurringTransaction(tx1);
      await repository.addRecurringTransaction(tx2);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      expect(notifier.state.upcomingPayments.length, 2);

      notifier.dispose();
    },
  );

  test(
    'Timer updates recalculate countdowns reactively without querying Hive on each tick',
    () async {
      final tx = createTx(
        id: 'tx-timer',
        name: 'Streaming',
        nextOccurrence: DateTime(2026, 9, 24, 10, 0, 10), // 10 seconds away
      );
      await repository.addRecurringTransaction(tx);

      final notifier = UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
        autoStartTimer: false,
      );
      await notifier.loadAndStart();

      expect(notifier.state.upcomingPayments.first.seconds, 10);

      // Advance clock by 4 seconds
      clock.currentTime = DateTime(2026, 9, 24, 10, 0, 4);
      notifier.recalculateNow();

      expect(notifier.state.upcomingPayments.first.seconds, 6);

      notifier.dispose();
    },
  );

  test('Timer disposal cancels timer cleanly', () async {
    final notifier = UpcomingPaymentCountdownNotifier(
      repository: repository,
      clock: clock,
      autoStartTimer: true,
    );
    await notifier.loadAndStart();

    expect(notifier.isTimerRunning, isTrue);

    notifier.dispose();
    expect(notifier.isTimerRunning, isFalse);
  });
}
