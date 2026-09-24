import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/recurring/data/models/recurring_transaction.dart';

void main() {
  group('RecurringTransaction Model & Domain Logic Tests', () {
    final baseCreatedAt = DateTime(2026, 1, 1, 10, 0);
    final baseUpdatedAt = DateTime(2026, 1, 1, 10, 0);
    final baseStartDate = DateTime(2026, 1, 15);

    test('1. Creation works and fields are populated properly', () {
      final rt = RecurringTransaction(
        id: 'rec-1',
        name: 'Spotify Premium',
        description: 'Family plan subscription',
        amountInCents: 1599,
        isIncome: false,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: baseStartDate,
        nextOccurrence: baseStartDate,
        endDate: DateTime(2026, 12, 31),
        status: RecurringTransactionStatus.active,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
        userId: 'user-1',
        reminderEnabled: true,
        reminderDaysBefore: 3,
        merchantName: 'Spotify',
        iconName: 'music_note',
      );

      expect(rt.id, 'rec-1');
      expect(rt.name, 'Spotify Premium');
      expect(rt.description, 'Family plan subscription');
      expect(rt.amountInCents, 1599);
      expect(rt.isIncome, isFalse);
      expect(rt.category, 'entertainment');
      expect(rt.recurrenceType, RecurrenceType.monthly);
      expect(rt.startDate, baseStartDate);
      expect(rt.nextOccurrence, baseStartDate);
      expect(rt.endDate, DateTime(2026, 12, 31));
      expect(rt.status, RecurringTransactionStatus.active);
      expect(rt.createdAt, baseCreatedAt);
      expect(rt.updatedAt, baseUpdatedAt);
      expect(rt.userId, 'user-1');
      expect(rt.reminderEnabled, isTrue);
      expect(rt.reminderDaysBefore, 3);
      expect(rt.merchantName, 'Spotify');
      expect(rt.iconName, 'music_note');
    });

    test('2. Amount uses integer cents correctly', () {
      final cents = RecurringTransaction.doubleToCents(49.99);
      expect(cents, 4999);

      final rt = RecurringTransaction(
        id: 'rec-2',
        name: 'Internet',
        amountInCents: cents,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: baseStartDate,
        nextOccurrence: baseStartDate,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(rt.amountInCents, isA<int>());
      expect(rt.amountInCents, 4999);
      expect(rt.amount, 49.99);
    });

    test('3. Weekly recurrence adds 7 days accurately', () {
      final rt = RecurringTransaction(
        id: 'rec-3',
        name: 'Weekly Allowance',
        amountInCents: 5000,
        isIncome: true,
        category: 'income_other',
        recurrenceType: RecurrenceType.weekly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      final next = rt.calculateNextOccurrence();
      expect(next, DateTime(2026, 9, 8));

      final advanced = rt.advanceToNextOccurrence();
      expect(advanced.nextOccurrence, DateTime(2026, 9, 8));
      expect(advanced.status, RecurringTransactionStatus.active);
    });

    test('4. Monthly recurrence handles standard dates across months', () {
      final rt = RecurringTransaction(
        id: 'rec-4',
        name: 'Gym Membership',
        amountInCents: 3000,
        category: 'health',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 3, 15),
        nextOccurrence: DateTime(2026, 3, 15),
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      final next = rt.calculateNextOccurrence();
      expect(next, DateTime(2026, 4, 15));

      final nextYearBoundary = rt.copyWith(nextOccurrence: DateTime(2026, 12, 15));
      expect(nextYearBoundary.calculateNextOccurrence(), DateTime(2027, 1, 15));
    });

    test('5. Monthly recurrence handles month-end dates and leap years correctly', () {
      // January 31 -> February 28 (non-leap year 2026)
      final rtJan31 = RecurringTransaction(
        id: 'rec-5a',
        name: 'Month End Sub',
        amountInCents: 1000,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 31),
        nextOccurrence: DateTime(2026, 1, 31),
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(rtJan31.calculateNextOccurrence(), DateTime(2026, 2, 28));

      // January 31 -> February 29 (leap year 2024)
      final rtJan31Leap = rtJan31.copyWith(nextOccurrence: DateTime(2024, 1, 31));
      expect(rtJan31Leap.calculateNextOccurrence(), DateTime(2024, 2, 29));

      // March 31 -> April 30 (30 days month)
      final rtMar31 = rtJan31.copyWith(nextOccurrence: DateTime(2026, 3, 31));
      expect(rtMar31.calculateNextOccurrence(), DateTime(2026, 4, 30));

      // August 31 -> September 30
      final rtAug31 = rtJan31.copyWith(nextOccurrence: DateTime(2026, 8, 31));
      expect(rtAug31.calculateNextOccurrence(), DateTime(2026, 9, 30));

      // October 31 -> November 30
      final rtOct31 = rtJan31.copyWith(nextOccurrence: DateTime(2026, 10, 31));
      expect(rtOct31.calculateNextOccurrence(), DateTime(2026, 11, 30));
    });

    test('6. Yearly recurrence works and handles leap year rollover safely', () {
      final rtAnnual = RecurringTransaction(
        id: 'rec-6a',
        name: 'Amazon Prime',
        amountInCents: 13900,
        category: 'shopping',
        recurrenceType: RecurrenceType.yearly,
        startDate: DateTime(2026, 6, 10),
        nextOccurrence: DateTime(2026, 6, 10),
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(rtAnnual.calculateNextOccurrence(), DateTime(2027, 6, 10));

      // Leap day Feb 29 (2024) -> Feb 28 (2025)
      final rtLeapYear = rtAnnual.copyWith(nextOccurrence: DateTime(2024, 2, 29));
      expect(rtLeapYear.calculateNextOccurrence(), DateTime(2025, 2, 28));
    });

    test('7. End dates are respected and transaction is automatically cancelled past end date', () {
      final rtWithEnd = RecurringTransaction(
        id: 'rec-7',
        name: 'Limited Lease',
        amountInCents: 150000,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 15),
        status: RecurringTransactionStatus.active,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(rtWithEnd.hasEnded, isFalse);
      expect(rtWithEnd.isActive, isTrue);

      // Advancing to April 1st exceeds March 15th endDate
      final advanced = rtWithEnd.advanceToNextOccurrence();
      expect(advanced.nextOccurrence, DateTime(2026, 4, 1));
      expect(advanced.status, RecurringTransactionStatus.cancelled);
      expect(advanced.hasEnded, isTrue);
      expect(advanced.isActive, isFalse);
    });

    test('8. isDueOn returns true only for active matching occurrences', () {
      final rt = RecurringTransaction(
        id: 'rec-8',
        name: 'Cloud Storage',
        amountInCents: 999,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 9, 25),
        nextOccurrence: DateTime(2026, 9, 25),
        endDate: DateTime(2026, 12, 31),
        status: RecurringTransactionStatus.active,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(rt.isDueOn(DateTime(2026, 9, 25)), isTrue);
      expect(rt.isDueOn(DateTime(2026, 9, 25, 14, 30)), isTrue);
      expect(rt.isDueOn(DateTime(2026, 9, 24)), isFalse);
      expect(rt.isDueOn(DateTime(2026, 9, 26)), isFalse);

      // Inactive / paused transaction is never due
      final pausedRt = rt.copyWith(status: RecurringTransactionStatus.paused);
      expect(pausedRt.isDueOn(DateTime(2026, 9, 25)), isFalse);

      // Ended transaction is never due
      final pastEndRt = rt.copyWith(endDate: DateTime(2026, 9, 20));
      expect(pastEndRt.isDueOn(DateTime(2026, 9, 25)), isFalse);
    });

    test('9. Reminder calculation calculates correct window for notification', () {
      final paymentDate = DateTime(2026, 9, 25);
      final rt = RecurringTransaction(
        id: 'rec-9',
        name: 'Utility Bill',
        amountInCents: 7500,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: paymentDate,
        nextOccurrence: paymentDate,
        reminderEnabled: true,
        reminderDaysBefore: 3,
        status: RecurringTransactionStatus.active,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      // September 21 -> 4 days before (false)
      expect(rt.shouldShowReminder(DateTime(2026, 9, 21)), isFalse);

      // September 22 -> 3 days before (true)
      expect(rt.shouldShowReminder(DateTime(2026, 9, 22)), isTrue);

      // September 23 -> 2 days before (true)
      expect(rt.shouldShowReminder(DateTime(2026, 9, 23)), isTrue);

      // September 24 -> 1 day before (true)
      expect(rt.shouldShowReminder(DateTime(2026, 9, 24)), isTrue);

      // September 25 -> 0 days before / due date (true)
      expect(rt.shouldShowReminder(DateTime(2026, 9, 25)), isTrue);

      // September 26 -> 1 day after (false)
      expect(rt.shouldShowReminder(DateTime(2026, 9, 26)), isFalse);
    });

    test('10. Inactive or reminder-disabled transactions do not show reminders', () {
      final rtDisabled = RecurringTransaction(
        id: 'rec-10a',
        name: 'Newspaper',
        amountInCents: 1200,
        category: 'bills',
        recurrenceType: RecurrenceType.monthly,
        startDate: DateTime(2026, 9, 25),
        nextOccurrence: DateTime(2026, 9, 25),
        reminderEnabled: false,
        reminderDaysBefore: 3,
        status: RecurringTransactionStatus.active,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
      );

      expect(rtDisabled.shouldShowReminder(DateTime(2026, 9, 24)), isFalse);

      final rtPaused = rtDisabled.copyWith(
        reminderEnabled: true,
        status: RecurringTransactionStatus.paused,
      );
      expect(rtPaused.shouldShowReminder(DateTime(2026, 9, 24)), isFalse);
    });

    test('11. copyWith preserves unchanged values and supports clearing endDate', () {
      final rt = RecurringTransaction(
        id: 'rec-11',
        name: 'Streaming',
        description: 'Monthly 4k',
        amountInCents: 1999,
        category: 'entertainment',
        recurrenceType: RecurrenceType.monthly,
        startDate: baseStartDate,
        nextOccurrence: baseStartDate,
        endDate: DateTime(2026, 12, 31),
        status: RecurringTransactionStatus.active,
        createdAt: baseCreatedAt,
        updatedAt: baseUpdatedAt,
        userId: 'user-777',
      );

      final updated = rt.copyWith(amountInCents: 2299);
      expect(updated.amountInCents, 2299);
      expect(updated.name, 'Streaming');
      expect(updated.endDate, DateTime(2026, 12, 31));

      final clearedEndDate = rt.copyWith(clearEndDate: true);
      expect(clearedEndDate.endDate, isNull);
      expect(clearedEndDate.name, 'Streaming');
    });
  });
}
