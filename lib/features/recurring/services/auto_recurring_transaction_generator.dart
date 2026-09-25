import 'dart:developer' as developer;
import '../../transactions/domain/models/transaction.dart';
import '../../transactions/domain/models/transaction_type.dart';
import '../../transactions/domain/repositories/transaction_repository.dart';
import '../data/models/recurring_transaction.dart';
import '../domain/repositories/recurring_repository.dart';

class AutoRecurringTransactionGenerator {
  final RecurringRepository recurringRepository;
  final TransactionRepository transactionRepository;

  AutoRecurringTransactionGenerator({
    required this.recurringRepository,
    required this.transactionRepository,
  });

  /// Generates a deterministic transaction ID for a given recurring transaction occurrence.
  static String generateTransactionId(String recurringId, DateTime date) {
    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'rec_${recurringId}_$formattedDate';
  }

  /// Processes all active due recurring transactions and generates corresponding PocketLedger transactions.
  ///
  /// Supports:
  /// - Catching up on multiple missed occurrences up to [asOf].
  /// - Idempotent execution preventing duplicate transactions.
  /// - Respecting [endDate] and automatically setting status to cancelled when recurrence ends.
  /// - Safe failure handling without advancing recurrence if transaction creation fails.
  /// - Preserving original occurrence dates and integer cents.
  Future<List<Transaction>> generateDueTransactions({
    DateTime? asOf,
    String? userId,
  }) async {
    final targetDate = asOf ?? DateTime.now();
    final normalizedTargetDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // Fetch active recurring transactions (filtered by userId if provided)
    final List<RecurringTransaction> activeList;
    if (userId != null && userId.isNotEmpty) {
      final userTransactions = await recurringRepository
          .getRecurringTransactionsForUser(userId);
      activeList = userTransactions.where((tx) => tx.isActive).toList();
    } else {
      activeList = await recurringRepository.getActiveRecurringTransactions();
    }

    // Load existing transactions to ensure duplicate prevention
    final existingTransactions = await transactionRepository.getTransactions();
    final existingTransactionIds = existingTransactions
        .map((tx) => tx.id)
        .toSet();

    final List<Transaction> generatedTransactions = [];

    for (final recurring in activeList) {
      RecurringTransaction current = recurring;

      while (current.status == RecurringTransactionStatus.active &&
          !current.hasEnded) {
        final occurrenceDate = current.nextOccurrence;
        final normalizedOccurrence = DateTime(
          occurrenceDate.year,
          occurrenceDate.month,
          occurrenceDate.day,
        );

        // Never generate future occurrences beyond asOf target date
        if (normalizedOccurrence.isAfter(normalizedTargetDate)) {
          break;
        }

        // Respect end date
        if (current.endDate != null) {
          final normalizedEnd = DateTime(
            current.endDate!.year,
            current.endDate!.month,
            current.endDate!.day,
          );
          if (normalizedOccurrence.isAfter(normalizedEnd)) {
            current = current.copyWith(
              status: RecurringTransactionStatus.cancelled,
              updatedAt: DateTime.now(),
            );
            await recurringRepository.updateRecurringTransaction(current);
            break;
          }
        }

        final txId = generateTransactionId(current.id, occurrenceDate);

        if (!existingTransactionIds.contains(txId)) {
          final newTransaction = Transaction(
            id: txId,
            type: current.isIncome
                ? TransactionType.income
                : TransactionType.expense,
            amountInCents: current.amountInCents,
            category: current.category,
            date: DateTime(
              occurrenceDate.year,
              occurrenceDate.month,
              occurrenceDate.day,
              occurrenceDate.hour,
              occurrenceDate.minute,
              occurrenceDate.second,
            ),
            note: current.name,
            createdAt: DateTime.now(),
          );

          try {
            await transactionRepository.saveTransaction(newTransaction);
            existingTransactionIds.add(txId);
            generatedTransactions.add(newTransaction);
          } catch (e, stackTrace) {
            developer.log(
              'Failed to create transaction for recurring transaction ${current.id} on $occurrenceDate: $e',
              name: 'AutoRecurringTransactionGenerator',
              error: e,
              stackTrace: stackTrace,
            );
            // On failure, do not advance the recurring transaction and do not lose the occurrence.
            break;
          }
        }

        // Advance to next occurrence after successful transaction creation / existence
        final next = current.advanceToNextOccurrence();
        current = next;
        await recurringRepository.updateRecurringTransaction(current);
      }
    }

    return generatedTransactions;
  }
}
