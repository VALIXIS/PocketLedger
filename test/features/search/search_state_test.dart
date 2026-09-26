import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/search/models/quick_filter_tag.dart';
import 'package:pocketledger/features/search/models/search_state.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

void main() {
  final fixedNow = DateTime(2026, 9, 25, 12, 0);

  group('SearchState & QuickFilterTag Model Tests', () {
    test('QuickFilterTag helper properties work correctly', () {
      expect(QuickFilterTag.income.isTypeTag, isTrue);
      expect(QuickFilterTag.expense.isTypeTag, isTrue);
      expect(QuickFilterTag.today.isTypeTag, isFalse);
      expect(QuickFilterTag.today.isDateTag, isTrue);
      expect(QuickFilterTag.thisWeek.isDateTag, isTrue);
      expect(QuickFilterTag.thisMonth.isDateTag, isTrue);
      expect(QuickFilterTag.income.isDateTag, isFalse);
    });

    test('toFilter accurately resolves relative quick filters', () {
      // 1. Income quick filter
      const stateWithIncome = SearchState(
        selectedQuickFilters: {QuickFilterTag.income},
      );
      final filterIncome = stateWithIncome.toFilter(referenceDate: fixedNow);
      expect(filterIncome.type, TransactionType.income);

      // 2. Today quick filter
      const stateWithToday = SearchState(
        selectedQuickFilters: {QuickFilterTag.today},
      );
      final filterToday = stateWithToday.toFilter(referenceDate: fixedNow);
      expect(filterToday.startDate, DateTime(2026, 9, 25));
      expect(filterToday.endDate, DateTime(2026, 9, 25));

      // 3. This Week quick filter (Monday Sep 21 to Sunday Sep 27)
      const stateWithWeek = SearchState(
        selectedQuickFilters: {QuickFilterTag.thisWeek},
      );
      final filterWeek = stateWithWeek.toFilter(referenceDate: fixedNow);
      expect(filterWeek.startDate, DateTime(2026, 9, 21));
      expect(filterWeek.endDate, DateTime(2026, 9, 27));

      // 4. This Month quick filter (Sep 1 to Sep 30)
      const stateWithMonth = SearchState(
        selectedQuickFilters: {QuickFilterTag.thisMonth},
      );
      final filterMonth = stateWithMonth.toFilter(referenceDate: fixedNow);
      expect(filterMonth.startDate, DateTime(2026, 9, 1));
      expect(filterMonth.endDate, DateTime(2026, 9, 30));
    });

    test('copyWith handles field replacement and clear flags properly', () {
      final state = SearchState(
        noteQuery: 'coffee',
        categoryId: 'food',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        minAmount: 10.0,
        maxAmount: 50.0,
        transactionType: TransactionType.expense,
        selectedQuickFilters: const {QuickFilterTag.expense},
        filteredTransactions: [
          Transaction(
            id: '1',
            type: TransactionType.expense,
            amountInCents: 1000,
            category: 'food',
            date: fixedNow,
            note: 'coffee',
            createdAt: fixedNow,
          ),
        ],
        totalTransactionCount: 1,
        isLoading: false,
      );

      final cleared = state.copyWith(
        clearCategoryId: true,
        clearStartDate: true,
        clearEndDate: true,
        clearMinAmount: true,
        clearMaxAmount: true,
        clearTransactionType: true,
        clearErrorMessage: true,
      );

      expect(cleared.categoryId, isNull);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
      expect(cleared.transactionType, isNull);
      expect(cleared.noteQuery, 'coffee');
      expect(cleared.filteredTransactions.length, 1);
    });

    test('value equality, hashCode, and toString work correctly', () {
      const state1 = SearchState(
        noteQuery: 'test',
        categoryId: 'food',
        selectedQuickFilters: {QuickFilterTag.expense},
      );
      const state2 = SearchState(
        noteQuery: 'test',
        categoryId: 'food',
        selectedQuickFilters: {QuickFilterTag.expense},
      );
      const state3 = SearchState(
        noteQuery: 'test2',
        categoryId: 'food',
        selectedQuickFilters: {QuickFilterTag.expense},
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
      expect(state1.toString(), contains('query: "test"'));
    });
  });
}
