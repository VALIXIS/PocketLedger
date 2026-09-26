import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/analytics/domain/analytics_helper.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction_type.dart';

void main() {
  final now = DateTime(2026, 9, 24, 10, 0);

  group('AnalyticsHelper - Day 1 Telemetry Engine', () {
    group('1. Category Percentage (Category %)', () {
      test(
        'calculates correct percentages for multiple expense categories',
        () {
          final transactions = [
            Transaction(
              id: '1',
              type: TransactionType.expense,
              amountInCents: 500000, // ₹5,000
              category: 'Food',
              date: now,
              note: 'Grocery',
              createdAt: now,
            ),
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 300000, // ₹3,000
              category: 'Transport',
              date: now,
              note: 'Taxi',
              createdAt: now,
            ),
            Transaction(
              id: '3',
              type: TransactionType.expense,
              amountInCents: 200000, // ₹2,000
              category: 'Bills',
              date: now,
              note: 'Electric',
              createdAt: now,
            ),
          ];

          final pcts = AnalyticsHelper.calculateCategoryPercentages(
            transactions,
          );

          expect(pcts['Food'], closeTo(50.0, 0.001));
          expect(pcts['Transport'], closeTo(30.0, 0.001));
          expect(pcts['Bills'], closeTo(20.0, 0.001));
        },
      );

      test('handles zero total expenses safely without NaN or Infinity', () {
        final pcts = AnalyticsHelper.calculateCategoryPercentages([]);
        expect(pcts, isEmpty);

        final incomeOnly = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 100000,
            category: 'Salary',
            date: now,
            note: 'Salary',
            createdAt: now,
          ),
        ];

        final incomePcts = AnalyticsHelper.calculateCategoryPercentages(
          incomeOnly,
        );
        expect(incomePcts, isEmpty);
      });

      test('handles empty or missing category names with fallback', () {
        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.expense,
            amountInCents: 10000,
            category: '',
            date: now,
            note: 'No cat',
            createdAt: now,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 10000,
            category: '   ',
            date: now,
            note: 'Spaces cat',
            createdAt: now,
          ),
        ];

        final pcts = AnalyticsHelper.calculateCategoryPercentages(transactions);
        expect(pcts['Uncategorized'], 100.0);
      });
    });

    group('2. Cashflow Velocity', () {
      test(
        'calculates average net cashflow per day correctly over a multi-day period',
        () {
          final day1 = DateTime(2026, 9, 1);
          final day10 = DateTime(
            2026,
            9,
            10,
          ); // 10 days total (Sept 1 to Sept 10 inclusive)

          final transactions = [
            Transaction(
              id: '1',
              type: TransactionType.income,
              amountInCents: 500000, // +$5,000
              category: 'Salary',
              date: day1,
              note: 'Salary',
              createdAt: day1,
            ),
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 200000, // -$2,000 -> Net = +$3,000
              category: 'Rent',
              date: day10,
              note: 'Rent',
              createdAt: day10,
            ),
          ];

          // Net cashflow = 3000.0, Period days = 10 -> Cashflow Velocity = 300.0 / day
          final velocity = AnalyticsHelper.calculateCashflowVelocity(
            transactions,
          );
          expect(velocity, closeTo(300.0, 0.001));
        },
      );

      test('handles same-day transactions safely (minimum 1 day period)', () {
        final sameDay = DateTime(2026, 9, 24, 14, 0);

        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 50000, // +$500
            category: 'Freelance',
            date: sameDay,
            note: '',
            createdAt: sameDay,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 10000, // -$100 -> Net = +$400
            category: 'Food',
            date: sameDay,
            note: '',
            createdAt: sameDay,
          ),
        ];

        final days = AnalyticsHelper.calculatePeriodDays(transactions);
        expect(days, 1);

        final velocity = AnalyticsHelper.calculateCashflowVelocity(
          transactions,
        );
        expect(velocity, 400.0);
      });

      test(
        'returns 0.0 velocity for empty transactions or invalid date range',
        () {
          expect(AnalyticsHelper.calculateCashflowVelocity([]), 0.0);

          final invalidVelocity = AnalyticsHelper.calculateCashflowVelocity(
            [
              Transaction(
                id: '1',
                type: TransactionType.income,
                amountInCents: 10000,
                category: 'Salary',
                date: now,
                note: '',
                createdAt: now,
              ),
            ],
            startDate: DateTime(2026, 9, 25),
            endDate: DateTime(2026, 9, 20), // Start > End
          );
          expect(invalidVelocity, 0.0);
        },
      );
    });

    group('3. Income / Expense Ratio', () {
      test('calculates ratio correctly when income and expenses exist', () {
        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 500000, // $5,000
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 200000, // $2,000
            category: 'Rent',
            date: now,
            note: '',
            createdAt: now,
          ),
        ];

        final ratio = AnalyticsHelper.calculateIncomeExpenseRatio(transactions);
        expect(ratio, 2.5); // 5000 / 2000
      });

      test(
        'returns 0.0 safe value when expenses are zero (prevents division by zero)',
        () {
          final transactions = [
            Transaction(
              id: '1',
              type: TransactionType.income,
              amountInCents: 500000,
              category: 'Salary',
              date: now,
              note: '',
              createdAt: now,
            ),
          ];

          final ratio = AnalyticsHelper.calculateIncomeExpenseRatio(
            transactions,
          );
          expect(ratio, 0.0);
          expect(ratio.isNaN, false);
          expect(ratio.isInfinite, false);
        },
      );

      test('returns 0.0 for empty transaction list', () {
        final ratio = AnalyticsHelper.calculateIncomeExpenseRatio([]);
        expect(ratio, 0.0);
      });
    });

    group('4. Savings Rate', () {
      test('calculates savings rate percentage correctly', () {
        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 1000000, // $10,000
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 250000, // $2,500
            category: 'Expenses',
            date: now,
            note: '',
            createdAt: now,
          ),
        ];

        // Net = 7500, Rate = (7500 / 10000) * 100 = 75.0%
        final rate = AnalyticsHelper.calculateSavingsRate(transactions);
        expect(rate, 75.0);
      });

      test('returns 0.0 safe value when total income is zero', () {
        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.expense,
            amountInCents: 50000, // $500 expense, 0 income
            category: 'Food',
            date: now,
            note: '',
            createdAt: now,
          ),
        ];

        final rate = AnalyticsHelper.calculateSavingsRate(transactions);
        expect(rate, 0.0);
        expect(rate.isNaN, false);
        expect(rate.isInfinite, false);
      });

      test('handles net deficit correctly (negative savings rate)', () {
        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 100000, // $1,000
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 150000, // $1,500
            category: 'Emergency',
            date: now,
            note: '',
            createdAt: now,
          ),
        ];

        // (1000 - 1500)/1000 * 100 = -50%
        final rate = AnalyticsHelper.calculateSavingsRate(transactions);
        expect(rate, -50.0);
      });

      test('returns 0.0 for empty transaction list', () {
        final rate = AnalyticsHelper.calculateSavingsRate([]);
        expect(rate, 0.0);
      });
    });

    group('5. Supporting Calculations & Edge Cases', () {
      test('calculates supporting totals accurately', () {
        final transactions = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 300000, // $3,000
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            amountInCents: 100000, // $1,000
            category: 'Rent',
            date: now,
            note: '',
            createdAt: now,
          ),
        ];

        expect(AnalyticsHelper.calculateTotalIncome(transactions), 3000.0);
        expect(AnalyticsHelper.calculateTotalExpenses(transactions), 1000.0);
        expect(AnalyticsHelper.calculateNetCashflow(transactions), 2000.0);
      });

      test('filters transactions by date range correctly', () {
        final d1 = DateTime(2026, 9, 10);
        final d2 = DateTime(2026, 9, 15);
        final d3 = DateTime(2026, 9, 20);

        final list = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 100,
            category: '',
            date: d1,
            note: '',
            createdAt: d1,
          ),
          Transaction(
            id: '2',
            type: TransactionType.income,
            amountInCents: 200,
            category: '',
            date: d2,
            note: '',
            createdAt: d2,
          ),
          Transaction(
            id: '3',
            type: TransactionType.income,
            amountInCents: 300,
            category: '',
            date: d3,
            note: '',
            createdAt: d3,
          ),
        ];

        final filtered = AnalyticsHelper.filterTransactions(
          list,
          startDate: DateTime(2026, 9, 12),
          endDate: DateTime(2026, 9, 18),
        );

        expect(filtered.length, 1);
        expect(filtered.first.id, '2');
      });

      test(
        'generateReport produces comprehensive and accurate AnalyticsReport',
        () {
          final d1 = DateTime(2026, 9, 1);
          final d5 = DateTime(2026, 9, 5);

          final transactions = [
            Transaction(
              id: '1',
              type: TransactionType.income,
              amountInCents: 500000, // $5,000
              category: 'Salary',
              date: d1,
              note: '',
              createdAt: d1,
            ),
            Transaction(
              id: '2',
              type: TransactionType.expense,
              amountInCents: 100000, // $1,000
              category: 'Food',
              date: d5,
              note: '',
              createdAt: d5,
            ),
          ];

          final report = AnalyticsHelper.generateReport(transactions);

          expect(report.totalIncome, 5000.0);
          expect(report.totalExpenses, 1000.0);
          expect(report.netCashflow, 4000.0);
          expect(report.categoryPercentages['Food'], 100.0);
          expect(report.periodDays, 5);
          expect(report.cashflowVelocity, 800.0); // 4000 / 5
          expect(report.incomeExpenseRatio, 5.0); // 5000 / 1000
          expect(report.savingsRate, 80.0); // (4000 / 5000) * 100
          expect(report.transactionCount, 2);
        },
      );

      test('does not mutate original transaction list', () {
        final original = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            amountInCents: 10000,
            category: 'Salary',
            date: now,
            note: '',
            createdAt: now,
          ),
        ];

        final originalLength = original.length;
        AnalyticsHelper.generateReport(original);
        AnalyticsHelper.calculateCategoryPercentages(original);
        AnalyticsHelper.filterTransactions(original, startDate: now);

        expect(original.length, originalLength);
      });
    });
  });
}
