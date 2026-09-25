import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';
import 'package:pocketledger/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:pocketledger/features/recurring/presentation/providers/recurring_list_notifier.dart';
import 'package:pocketledger/features/recurring/presentation/providers/upcoming_payment_countdown.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/cancellation_reminder_card.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurrence_cycle_chip.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_empty_state.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_filter_bar.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_form.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_summary.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/recurring_transaction_card.dart';
import 'package:pocketledger/features/recurring/presentation/widgets/renewal_alert_card.dart';

class FakeRecurringRepository implements RecurringRepository {
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

Widget createRecurringTestApp({
  required Widget child,
  FakeRecurringRepository? repository,
}) {
  final repo = repository ?? FakeRecurringRepository();
  return ProviderScope(
    overrides: [recurringRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('RecurrenceCycleChip Tests', () {
    testWidgets('displays Weekly, Monthly, and Annual labels correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        createRecurringTestApp(
          child: const Column(
            children: [
              RecurrenceCycleChip(recurrenceType: RecurrenceType.weekly),
              RecurrenceCycleChip(recurrenceType: RecurrenceType.monthly),
              RecurrenceCycleChip(recurrenceType: RecurrenceType.yearly),
            ],
          ),
        ),
      );

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);
    });
  });

  group('RecurringSummary Cost Calculations Tests', () {
    test('calculates monthly and annual costs accurately in integer cents', () {
      final txWeekly = RecurringTransaction(
        id: 'w-1',
        name: 'Weekly Gym',
        amountInCents:
            1000, // $10/wk -> $520/yr -> $43/mo (integer: 1000 * 52 ~/ 12 = 4333 cents = $43.33)
        category: 'health',
        recurrenceType: RecurrenceType.weekly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 1, 8),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final txMonthly = RecurringTransaction(
        id: 'm-1',
        name: 'Netflix',
        amountInCents: 1500, // $15/mo -> $180/yr (1500 * 12 = 18000 cents)
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 1, 15),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final txYearly = RecurringTransaction(
        id: 'y-1',
        name: 'Amazon Prime',
        amountInCents: 12000, // $120/yr -> $10/mo (12000 ~/ 12 = 1000 cents)
        category: 'shopping',
        recurrenceType: RecurrenceType.yearly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2027, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final list = [txWeekly, txMonthly, txYearly];

      final monthlyCost = RecurringSummary.calculateMonthlyCostInCents(list);
      // (1000 * 52 ~/ 12) + 1500 + (12000 ~/ 12) = 4333 + 1500 + 1000 = 6833 cents ($68.33)
      expect(monthlyCost, 6833);

      final annualCost = RecurringSummary.calculateAnnualCostInCents(list);
      // (1000 * 52) + (1500 * 12) + 12000 = 52000 + 18000 + 12000 = 82000 cents ($820.00)
      expect(annualCost, 82000);
    });

    testWidgets('renders summary cards with active count and costs', (
      tester,
    ) async {
      final tx = RecurringTransaction(
        id: 'tx-1',
        name: 'Spotify',
        amountInCents: 999,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        createRecurringTestApp(
          child: RecurringSummary(transactions: [tx], currency: 'USD'),
        ),
      );

      expect(find.text('SUBSCRIPTIONS & RECURRING'), findsOneWidget);
      expect(find.text('1 Active'), findsOneWidget);
      expect(find.text('Monthly Cost'), findsOneWidget);
      expect(find.text('Annual Cost'), findsOneWidget);
    });
  });

  group('RenewalAlertCard Tests', () {
    testWidgets('renders due today and upcoming renewal alert states', (
      tester,
    ) async {
      final now = DateTime(2026, 9, 24, 12, 0);
      final tx = RecurringTransaction(
        id: 'tx-alert',
        name: 'Netflix Subscription',
        merchantName: 'Netflix Inc.',
        amountInCents: 1599,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: now,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final countdown = UpcomingPaymentCountdown.calculate(
        recurringTransaction: tx,
        now: now,
      );

      await tester.pumpWidget(
        createRecurringTestApp(
          child: RenewalAlertCard(countdown: countdown, currency: 'USD'),
        ),
      );

      expect(find.text('DUE TODAY'), findsOneWidget);
      expect(find.text('Netflix Subscription'), findsOneWidget);
      expect(find.text('Netflix Inc.'), findsOneWidget);
      expect(find.text('Renews today'), findsOneWidget);
    });
  });

  group('CancellationReminderCard Tests', () {
    testWidgets('displays reminder when within reminderDaysBefore window', (
      tester,
    ) async {
      final now = DateTime.now();
      final tx = RecurringTransaction(
        id: 'tx-remind',
        name: 'Gym Membership',
        amountInCents: 5000,
        category: 'health',
        recurrenceType: RecurrenceType.monthly,
        startDate: now.subtract(const Duration(days: 30)),
        nextOccurrence: now.add(const Duration(days: 2)),
        reminderEnabled: true,
        reminderDaysBefore: 3,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );

      await tester.pumpWidget(
        createRecurringTestApp(
          child: CancellationReminderCard(transactions: [tx], currency: 'USD'),
        ),
      );

      expect(find.text('SUBSCRIPTION REMINDER'), findsOneWidget);
      expect(find.textContaining('Gym Membership renews on'), findsOneWidget);
      expect(find.text('Review Settings'), findsOneWidget);
    });
  });

  group('RecurringTransactionCard Tests', () {
    testWidgets('displays transaction details and triggers action menu', (
      tester,
    ) async {
      final tx = RecurringTransaction(
        id: 'card-1',
        name: 'Internet Fiber',
        merchantName: 'Comcast',
        amountInCents: 7999,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 5),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        status: RecurringTransactionStatus.active,
      );

      await tester.pumpWidget(
        createRecurringTestApp(
          child: RecurringTransactionCard(transaction: tx),
        ),
      );

      expect(find.text('Internet Fiber'), findsOneWidget);
      expect(find.text('Comcast'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
    });
  });

  group('RecurringForm Tests', () {
    testWidgets('validates required fields and adds new recurring payment', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeRecurringRepository();

      await tester.pumpWidget(
        createRecurringTestApp(
          repository: repo,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RecurringForm.showAdd(ctx),
              child: const Text('Open Add'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Add'));
      await tester.pumpAndSettle();

      expect(find.text('New Recurring Payment'), findsOneWidget);

      // Tap Add Payment without filling -> validation error
      final addBtn = find.widgetWithText(FilledButton, 'Add Payment');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);

      // Enter name and amount
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subscription / Payment Name *'),
        'Disney+',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (USD) *'),
        '13.99',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Form closed and added to repository
      expect(find.text('New Recurring Payment'), findsNothing);
      expect(repo.transactions.length, 1);
      expect(repo.transactions.values.first.name, 'Disney+');
      expect(repo.transactions.values.first.amountInCents, 1399);
    });

    testWidgets('edits existing recurring transaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeRecurringRepository();
      final tx = RecurringTransaction(
        id: 'edit-tx',
        name: 'Old Subscription',
        amountInCents: 999,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.addRecurringTransaction(tx);

      await tester.pumpWidget(
        createRecurringTestApp(
          repository: repo,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RecurringForm.showEdit(ctx, tx),
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Recurring Payment'), findsOneWidget);
      expect(find.text('Old Subscription'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subscription / Payment Name *'),
        'Updated Prime Video',
      );
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Recurring Payment'), findsNothing);
      expect(repo.transactions['edit-tx']?.name, 'Updated Prime Video');
    });
  });

  group('RecurringEmptyState Tests', () {
    testWidgets('renders empty state and responds to CTA callback', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        createRecurringTestApp(
          child: RecurringEmptyState(onAddPressed: () => called = true),
        ),
      );

      expect(find.text('No Recurring Payments'), findsOneWidget);
      expect(find.text('Add Recurring Payment'), findsOneWidget);

      await tester.tap(find.text('Add Recurring Payment'));
      expect(called, isTrue);
    });
  });

  group('RecurringFilterBar Tests', () {
    testWidgets('triggers cycle and status change callbacks', (tester) async {
      CycleFilter? selectedCycle;
      StatusFilter? selectedStatus;

      await tester.pumpWidget(
        createRecurringTestApp(
          child: RecurringFilterBar(
            selectedCycle: CycleFilter.all,
            selectedStatus: StatusFilter.all,
            totalCount: 5,
            weeklyCount: 1,
            monthlyCount: 3,
            annualCount: 1,
            activeCount: 4,
            pausedCount: 1,
            cancelledCount: 0,
            onCycleChanged: (c) => selectedCycle = c,
            onStatusChanged: (s) => selectedStatus = s,
          ),
        ),
      );

      expect(find.text('All (5)'), findsOneWidget);
      expect(find.text('Monthly (3)'), findsOneWidget);

      await tester.tap(find.text('Monthly (3)'));
      expect(selectedCycle, CycleFilter.monthly);

      await tester.tap(find.text('Active (4)'));
      expect(selectedStatus, StatusFilter.active);
    });
  });
}
