import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';
import 'package:pocketledger/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:pocketledger/features/recurring/presentation/providers/recurring_list_notifier.dart';
import 'package:pocketledger/features/recurring/presentation/screens/recurring_manager_screen.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_empty_state.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_transaction_card.dart';

class MockRecurringRepository implements RecurringRepository {
  final Map<String, RecurringTransaction> transactions = {};

  @override
  Future<void> addRecurringTransaction(RecurringTransaction tx) async {
    transactions[tx.id] = tx;
  }

  @override
  Future<void> updateRecurringTransaction(RecurringTransaction tx) async {
    transactions[tx.id] = tx;
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    transactions.remove(id);
  }

  @override
  Future<RecurringTransaction?> getRecurringTransaction(String id) async =>
      transactions[id];

  @override
  Future<List<RecurringTransaction>> getAllRecurringTransactions() async =>
      transactions.values.toList();

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsForUser(
    String userId,
  ) async => transactions.values.where((tx) => tx.userId == userId).toList();

  @override
  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async =>
      transactions.values.where((tx) => tx.isActive).toList();

  @override
  Future<List<RecurringTransaction>> getDueTransactions([
    DateTime? asOf,
  ]) async {
    final date = asOf ?? DateTime.now();
    return transactions.values.where((tx) => tx.isDueOn(date)).toList();
  }

  @override
  Future<bool> containsRecurringTransaction(String id) async =>
      transactions.containsKey(id);
}

Widget createRecurringScreenApp({required MockRecurringRepository repository}) {
  return ProviderScope(
    overrides: [recurringRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: RecurringManagerScreen()),
  );
}

void main() {
  group('RecurringManagerScreen Widget Tests', () {
    testWidgets('renders empty state when no transactions exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockRecurringRepository();

      await tester.pumpWidget(createRecurringScreenApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions & Recurring'), findsOneWidget);
      expect(find.byType(RecurringEmptyState), findsOneWidget);
      expect(find.text('No Recurring Payments'), findsOneWidget);
    });

    testWidgets('renders top summary and transaction cards when data exists', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockRecurringRepository();
      final tx1 = RecurringTransaction(
        id: 'tx-1',
        name: 'Netflix Premium',
        amountInCents: 1999,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final tx2 = RecurringTransaction(
        id: 'tx-2',
        name: 'Gym Membership',
        amountInCents: 4500,
        category: 'health',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 5),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await repo.addRecurringTransaction(tx1);
      await repo.addRecurringTransaction(tx2);

      await tester.pumpWidget(createRecurringScreenApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('SUBSCRIPTIONS & RECURRING'), findsOneWidget);
      expect(find.text('2 Active'), findsOneWidget);
      expect(
        find.widgetWithText(RecurringTransactionCard, 'Netflix Premium'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RecurringTransactionCard, 'Gym Membership'),
        findsOneWidget,
      );
      expect(find.byType(RecurringTransactionCard), findsNWidgets(2));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('filters by recurrence cycle (Weekly, Monthly, Annual)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockRecurringRepository();
      final txWeekly = RecurringTransaction(
        id: 'tx-w',
        name: 'Weekly Milk Delivery',
        amountInCents: 1500,
        category: 'food',
        recurrenceType: RecurrenceType.weekly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final txMonthly = RecurringTransaction(
        id: 'tx-m',
        name: 'Monthly Spotify',
        amountInCents: 1099,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 15),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await repo.addRecurringTransaction(txWeekly);
      await repo.addRecurringTransaction(txMonthly);

      await tester.pumpWidget(createRecurringScreenApp(repository: repo));
      await tester.pumpAndSettle();

      // Filter Weekly
      await tester.tap(find.text('Weekly (1)'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(RecurringTransactionCard, 'Weekly Milk Delivery'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RecurringTransactionCard, 'Monthly Spotify'),
        findsNothing,
      );

      // Filter Monthly
      await tester.tap(find.text('Monthly (1)'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(RecurringTransactionCard, 'Weekly Milk Delivery'),
        findsNothing,
      );
      expect(
        find.widgetWithText(RecurringTransactionCard, 'Monthly Spotify'),
        findsOneWidget,
      );

      // Filter All
      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(RecurringTransactionCard, 'Weekly Milk Delivery'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RecurringTransactionCard, 'Monthly Spotify'),
        findsOneWidget,
      );
    });

    testWidgets('pull-to-refresh triggers reload cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockRecurringRepository();
      final tx = RecurringTransaction(
        id: 'tx-ref',
        name: 'Reload Test Subscription',
        amountInCents: 500,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addRecurringTransaction(tx);

      await tester.pumpWidget(createRecurringScreenApp(repository: repo));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          RecurringTransactionCard,
          'Reload Test Subscription',
        ),
        findsOneWidget,
      );

      await tester.fling(
        find.byType(RecurringTransactionCard).first,
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          RecurringTransactionCard,
          'Reload Test Subscription',
        ),
        findsOneWidget,
      );
    });
  });
}
