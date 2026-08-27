import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/utilities/input_validators.dart';
import 'package:pocketledger/features/transactions/domain/models/transaction.dart';
import 'package:pocketledger/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  group('Financial Calculations & Cents conversions', () {
    test('doubleToCents converts double amount to integer cents safely', () {
      expect(Transaction.doubleToCents(10.50), 1050);
      expect(
        Transaction.doubleToCents(0.1 + 0.2),
        30,
      ); // 0.30 cents, avoids float errors!
      expect(Transaction.doubleToCents(19.99), 1999);
      expect(Transaction.doubleToCents(1000.00), 100000);
    });

    test(
      'DashboardStats correctly calculates income, expenses, and balance',
      () {
        final stats = DashboardStats(
          totalIncomeInCents: 100000, // $1000.00
          totalExpensesInCents: 15050, // $150.50
          balanceInCents: 84950, // $849.50
        );

        expect(stats.totalIncome, 1000.00);
        expect(stats.totalExpenses, 150.50);
        expect(stats.balance, 849.50);
      },
    );
  });

  group('Input Validators', () {
    test('validateAmount validates format and range', () {
      expect(InputValidators.validateAmount(''), 'Amount is required');
      expect(InputValidators.validateAmount('  '), 'Amount is required');
      expect(
        InputValidators.validateAmount('abc'),
        'Please enter a valid number',
      );
      expect(
        InputValidators.validateAmount('-10'),
        'Amount must be greater than zero',
      );
      expect(
        InputValidators.validateAmount('0'),
        'Amount must be greater than zero',
      );
      expect(InputValidators.validateAmount('10.50'), null);
      expect(
        InputValidators.validateAmount('10.555'),
        'Maximum 2 decimal places allowed',
      );
    });

    test('validateCategory validates existence', () {
      expect(InputValidators.validateCategory(''), 'Category is required');
      expect(InputValidators.validateCategory('food'), null);
    });
  });
}
