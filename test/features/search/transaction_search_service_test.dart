import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/search/models/transaction_search_filter.dart';
import 'package:pocketledger/features/search/services/transaction_search_service.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

void main() {
  const service = TransactionSearchService();

  final baseDate = DateTime(2026, 9, 25, 12, 0, 0);

  final sampleTransactions = [
    Transaction(
      id: 'tx-1',
      type: TransactionType.expense,
      amountInCents: 1500, // $15.00
      category: 'food',
      date: DateTime(2026, 9, 20, 9, 30),
      note: 'Morning Coffee and Croissant',
      createdAt: baseDate,
    ),
    Transaction(
      id: 'tx-2',
      type: TransactionType.expense,
      amountInCents: 5000, // $50.00
      category: 'shopping',
      date: DateTime(2026, 9, 22, 14, 15),
      note: 'Grocery store items',
      createdAt: baseDate,
    ),
    Transaction(
      id: 'tx-3',
      type: TransactionType.income,
      amountInCents: 250000, // $2,500.00
      category: 'salary',
      date: DateTime(2026, 9, 25, 8, 0),
      note: 'Monthly Salary from Acme Corp',
      createdAt: baseDate,
    ),
    Transaction(
      id: 'tx-4',
      type: TransactionType.expense,
      amountInCents: 12000, // $120.00
      category: 'bills',
      date: DateTime(2026, 9, 25, 23, 45),
      note: 'Electric utility bill',
      createdAt: baseDate,
    ),
    Transaction(
      id: 'tx-5',
      type: TransactionType.income,
      amountInCents: 35000, // $350.00
      category: 'freelance',
      date: DateTime(2026, 9, 28, 16, 0),
      note: 'Mobile app design consulting',
      createdAt: baseDate,
    ),
    Transaction(
      id: 'tx-6',
      type: TransactionType.expense,
      amountInCents: 750, // $7.50
      category: 'transport',
      date: DateTime(2026, 9, 30, 19, 0),
      note: 'Subway ticket',
      createdAt: baseDate,
    ),
  ];

  group('TransactionSearchService — Multi-Parameter Search Engine (Day 1)', () {
    group('1. Empty and No Filters', () {
      test(
        'returns all transactions unmodified when no filters are applied',
        () {
          final result = service.search(sampleTransactions);
          expect(result.length, 6);
          expect(result.map((e) => e.id).toList(), [
            'tx-1',
            'tx-2',
            'tx-3',
            'tx-4',
            'tx-5',
            'tx-6',
          ]);
        },
      );

      test('returns all transactions when empty filter object is passed', () {
        final result = service.filter(
          sampleTransactions,
          TransactionSearchFilter.empty,
        );
        expect(result.length, 6);
      });

      test('returns empty list when input transaction list is empty', () {
        final result = service.search([], query: 'coffee');
        expect(result, isEmpty);
      });

      test('treats whitespace-only queries and empty categories as no-op', () {
        final result = service.search(
          sampleTransactions,
          query: '   ',
          categoryId: '   ',
        );
        expect(result.length, 6);
      });
    });

    group('2. Note Text Search', () {
      test('filters transactions by exact note substring', () {
        final result = service.search(sampleTransactions, query: 'Coffee');
        expect(result.length, 1);
        expect(result.first.id, 'tx-1');
      });

      test('matches notes case-insensitively', () {
        final lowerResult = service.search(
          sampleTransactions,
          query: 'grocery',
        );
        final upperResult = service.search(
          sampleTransactions,
          query: 'GROCERY',
        );
        final mixedResult = service.search(
          sampleTransactions,
          query: 'gRoCeRy',
        );

        expect(lowerResult.length, 1);
        expect(lowerResult.first.id, 'tx-2');
        expect(upperResult.length, 1);
        expect(upperResult.first.id, 'tx-2');
        expect(mixedResult.length, 1);
        expect(mixedResult.first.id, 'tx-2');
      });

      test('trims surrounding whitespace from note query', () {
        final result = service.search(
          sampleTransactions,
          query: '   Electric utility   ',
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-4');
      });

      test('matches multiple transactions with matching note substring', () {
        final result = service.search(sampleTransactions, query: 'e');
        // 'Coffee', 'Grocery', 'Acme', 'Electric', 'design/freelance', 'ticket' all contain 'e'
        expect(result.length, 6);
      });
    });

    group('3. Category Filtering', () {
      test('filters by exact category ID', () {
        final result = service.search(sampleTransactions, categoryId: 'food');
        expect(result.length, 1);
        expect(result.first.id, 'tx-1');
      });

      test('trims whitespace around category ID', () {
        final result = service.search(
          sampleTransactions,
          categoryId: '  salary  ',
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-3');
      });

      test('returns empty list when no transactions match category ID', () {
        final result = service.search(
          sampleTransactions,
          categoryId: 'entertainment',
        );
        expect(result, isEmpty);
      });
    });

    group('4. Date Filtering & Inclusive Boundaries', () {
      test('filters by inclusive start date', () {
        // Start date: 2026-09-25
        // Should include transactions on 2026-09-25 (tx-3, tx-4), 2026-09-28 (tx-5), 2026-09-30 (tx-6)
        final result = service.search(
          sampleTransactions,
          startDate: DateTime(2026, 9, 25),
        );
        expect(result.map((e) => e.id).toList(), [
          'tx-3',
          'tx-4',
          'tx-5',
          'tx-6',
        ]);
      });

      test('filters by inclusive end date', () {
        // End date: 2026-09-25
        // Should include transactions up through 2026-09-25 23:59:59 (tx-1, tx-2, tx-3, tx-4)
        final result = service.search(
          sampleTransactions,
          endDate: DateTime(2026, 9, 25),
        );
        expect(result.map((e) => e.id).toList(), [
          'tx-1',
          'tx-2',
          'tx-3',
          'tx-4',
        ]);
      });

      test(
        'includes all transactions on boundary dates regardless of time of day',
        () {
          // Single day filter on 2026-09-25
          // tx-3 is at 08:00, tx-4 is at 23:45
          final result = service.search(
            sampleTransactions,
            startDate: DateTime(2026, 9, 25),
            endDate: DateTime(2026, 9, 25),
          );
          expect(result.map((e) => e.id).toList(), ['tx-3', 'tx-4']);
        },
      );

      test('filters by date range spanning multiple days', () {
        // Range: 2026-09-21 to 2026-09-26
        // Includes tx-2 (Sep 22), tx-3 (Sep 25), tx-4 (Sep 25)
        final result = service.search(
          sampleTransactions,
          startDate: DateTime(2026, 9, 21),
          endDate: DateTime(2026, 9, 26),
        );
        expect(result.map((e) => e.id).toList(), ['tx-2', 'tx-3', 'tx-4']);
      });

      test('returns empty list when startDate is after endDate', () {
        final result = service.search(
          sampleTransactions,
          startDate: DateTime(2026, 9, 26),
          endDate: DateTime(2026, 9, 25),
        );
        expect(result, isEmpty);
      });
    });

    group('5. Amount Filtering & Range', () {
      test('filters by inclusive minimum amount (double & cents)', () {
        // Minimum amount: $50.00
        // Expected: tx-2 ($50), tx-3 ($2500), tx-4 ($120), tx-5 ($350)
        final result = service.search(sampleTransactions, minAmount: 50.0);
        expect(result.map((e) => e.id).toList(), [
          'tx-2',
          'tx-3',
          'tx-4',
          'tx-5',
        ]);

        final resultCents = service.search(
          sampleTransactions,
          minAmountInCents: 5000,
        );
        expect(resultCents.map((e) => e.id).toList(), [
          'tx-2',
          'tx-3',
          'tx-4',
          'tx-5',
        ]);
      });

      test('filters by inclusive maximum amount (double & cents)', () {
        // Maximum amount: $50.00
        // Expected: tx-1 ($15), tx-2 ($50), tx-6 ($7.50)
        final result = service.search(sampleTransactions, maxAmount: 50.0);
        expect(result.map((e) => e.id).toList(), ['tx-1', 'tx-2', 'tx-6']);

        final resultCents = service.search(
          sampleTransactions,
          maxAmountInCents: 5000,
        );
        expect(resultCents.map((e) => e.id).toList(), ['tx-1', 'tx-2', 'tx-6']);
      });

      test('filters by inclusive amount range', () {
        // Range: $15.00 to $120.00
        // Expected: tx-1 ($15.00), tx-2 ($50.00), tx-4 ($120.00)
        final result = service.search(
          sampleTransactions,
          minAmount: 15.0,
          maxAmount: 120.0,
        );
        expect(result.map((e) => e.id).toList(), ['tx-1', 'tx-2', 'tx-4']);
      });

      test('returns empty list when minAmount is greater than maxAmount', () {
        final result = service.search(
          sampleTransactions,
          minAmount: 100.0,
          maxAmount: 50.0,
        );
        expect(result, isEmpty);
      });
    });

    group('6. Transaction Type Filtering', () {
      test('filters by expense transaction type', () {
        final result = service.search(
          sampleTransactions,
          type: TransactionType.expense,
        );
        expect(result.length, 4);
        expect(result.map((e) => e.id).toList(), [
          'tx-1',
          'tx-2',
          'tx-4',
          'tx-6',
        ]);
      });

      test('filters by income transaction type', () {
        final result = service.search(
          sampleTransactions,
          type: TransactionType.income,
        );
        expect(result.length, 2);
        expect(result.map((e) => e.id).toList(), ['tx-3', 'tx-5']);
      });
    });

    group('7. Multiple Filters Simultaneously (AND Logic)', () {
      test('combines type, category, date, and amount filters', () {
        // Expense + bills + Sep 25 + min $100 -> tx-4
        final result = service.search(
          sampleTransactions,
          type: TransactionType.expense,
          categoryId: 'bills',
          startDate: DateTime(2026, 9, 25),
          endDate: DateTime(2026, 9, 25),
          minAmount: 100.0,
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-4');
      });

      test('combines note query and amount range', () {
        // Query 'consulting' + minAmount $300 + maxAmount $400 -> tx-5
        const filter = TransactionSearchFilter(
          query: 'CONSULTING',
          minAmount: 300.0,
          maxAmount: 400.0,
          type: TransactionType.income,
        );
        final result = service.filter(sampleTransactions, filter);
        expect(result.length, 1);
        expect(result.first.id, 'tx-5');
      });

      test('fails when any single condition in AND chain does not match', () {
        // Query matches tx-1 ('Coffee'), but category is 'transport' (tx-1 is 'food')
        final result = service.search(
          sampleTransactions,
          query: 'Coffee',
          categoryId: 'transport',
        );
        expect(result, isEmpty);
      });
    });

    group('8. Immutability & Original List Preservation', () {
      test('does not mutate original list or alter its order', () {
        final originalIds = sampleTransactions.map((e) => e.id).toList();
        final originalLength = sampleTransactions.length;

        final result = service.search(
          sampleTransactions,
          query: 'Coffee',
          type: TransactionType.expense,
        );

        expect(result.length, 1);
        expect(sampleTransactions.length, originalLength);
        expect(
          sampleTransactions.map((e) => e.id).toList(),
          equals(originalIds),
        );
      });
    });

    group('9. TransactionSearchFilter Model Tests', () {
      test('isEmpty and isNotEmpty work accurately', () {
        expect(TransactionSearchFilter.empty.isEmpty, isTrue);
        expect(TransactionSearchFilter.empty.isNotEmpty, isFalse);

        const filterWithQuery = TransactionSearchFilter(query: 'test');
        expect(filterWithQuery.isEmpty, isFalse);
        expect(filterWithQuery.isNotEmpty, isTrue);

        const filterWithWhitespace = TransactionSearchFilter(
          query: '   ',
          categoryId: '   ',
        );
        expect(filterWithWhitespace.isEmpty, isTrue);

        const filterWithType = TransactionSearchFilter(
          type: TransactionType.income,
        );
        expect(filterWithType.isEmpty, isFalse);
      });

      test('copyWith and clearing fields work as expected', () {
        const filter = TransactionSearchFilter(
          query: 'coffee',
          categoryId: 'food',
          minAmount: 10.0,
          maxAmount: 20.0,
          type: TransactionType.expense,
        );

        final updated = filter.copyWith(query: 'tea', minAmount: 12.0);
        expect(updated.query, 'tea');
        expect(updated.categoryId, 'food');
        expect(updated.minAmount, 12.0);
        expect(updated.maxAmount, 20.0);
        expect(updated.type, TransactionType.expense);

        final cleared = updated.copyWith(clearQuery: true, clearCategory: true);
        expect(cleared.query, isNull);
        expect(cleared.categoryId, isNull);
        expect(cleared.minAmount, 12.0);
      });

      test('equality, hashCode, and toString work correctly', () {
        const filter1 = TransactionSearchFilter(
          query: 'abc',
          categoryId: 'food',
          type: TransactionType.expense,
        );
        const filter2 = TransactionSearchFilter(
          query: 'abc',
          categoryId: 'food',
          type: TransactionType.expense,
        );
        const filter3 = TransactionSearchFilter(
          query: 'def',
          categoryId: 'food',
          type: TransactionType.expense,
        );

        expect(filter1, equals(filter2));
        expect(filter1.hashCode, equals(filter2.hashCode));
        expect(filter1, isNot(equals(filter3)));
        expect(filter1.toString(), contains('query: abc'));
      });
    });

    group('10. Static Helper Method', () {
      test('filterTransactions works identically to instance search', () {
        final result = TransactionSearchService.filterTransactions(
          sampleTransactions,
          query: 'salary',
          type: TransactionType.income,
        );
        expect(result.length, 1);
        expect(result.first.id, 'tx-3');
      });
    });

    group('11. Large Dataset & Edge Case Boundary Tests', () {
      test('efficiently filters a large list of 2,000 transactions', () {
        final largeDataset = List.generate(2000, (i) {
          final isEven = i.isEven;
          return Transaction(
            id: 'tx-$i',
            type: isEven ? TransactionType.expense : TransactionType.income,
            amountInCents: (i + 1) * 100, // $1 to $2000
            category: isEven ? 'food' : 'salary',
            date: DateTime(2026, 9, 1).add(Duration(hours: i)),
            note: 'Transaction record number $i with detailed note',
            createdAt: baseDate,
          );
        });

        final stopwatch = Stopwatch()..start();
        final results = service.search(
          largeDataset,
          query: 'number 150',
          type: TransactionType.expense,
          minAmount: 100.0,
          maxAmount: 2000.0,
        );
        stopwatch.stop();

        // Must execute swiftly in < 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(results, isNotEmpty);
        expect(results.every((t) => t.type == TransactionType.expense), isTrue);
      });
    });
  });
}
