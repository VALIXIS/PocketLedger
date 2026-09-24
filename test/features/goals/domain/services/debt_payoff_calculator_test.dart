import 'package:flutter_test/flutter_test.dart';

import 'package:pocketledger/features/goals/domain/models/debt_payoff_item.dart';
import 'package:pocketledger/features/goals/domain/services/debt_payoff_calculator.dart';

void main() {
  const calculator = DebtPayoffCalculator();

  group('DebtPayoffCalculator', () {
    final debts = [
      const DebtPayoffItem(
        id: 'credit_card',
        name: 'Credit Card',
        balanceInCents: 100000,
        annualInterestRate: 24,
        minimumPaymentInCents: 5000,
      ),
      const DebtPayoffItem(
        id: 'personal_loan',
        name: 'Personal Loan',
        balanceInCents: 300000,
        annualInterestRate: 10,
        minimumPaymentInCents: 10000,
      ),
      const DebtPayoffItem(
        id: 'education_loan',
        name: 'Education Loan',
        balanceInCents: 500000,
        annualInterestRate: 7,
        minimumPaymentInCents: 12000,
      ),
    ];

    test('avalanche prioritizes highest interest rate', () {
      final result = calculator.calculate(
        debts: debts,
        extraMonthlyPaymentInCents: 10000,
        strategy: DebtPayoffStrategy.avalanche,
      );

      expect(result.debts.first.debtId, 'credit_card');
      expect(result.debts.length, 3);
      expect(result.isDebtFree, isTrue);
      expect(result.firstDebtPaidOff?.debtId, 'credit_card');
      expect(result.finalDebtPaidOff?.debtId, isNotNull);
    });

    test('snowball prioritizes smallest balance', () {
      final result = calculator.calculate(
        debts: debts,
        extraMonthlyPaymentInCents: 10000,
        strategy: DebtPayoffStrategy.snowball,
      );

      expect(result.debts.first.debtId, 'credit_card');
      expect(result.strategy, DebtPayoffStrategy.snowball);
      expect(result.debtCount, 3);
    });

    test('snowball orders different balances correctly', () {
      const debtSmall = DebtPayoffItem(
        id: 'card_small',
        name: 'Card Small',
        balanceInCents: 50000,
        annualInterestRate: 5,
        minimumPaymentInCents: 2000,
      );
      const debtLarge = DebtPayoffItem(
        id: 'loan_large',
        name: 'Loan Large',
        balanceInCents: 200000,
        annualInterestRate: 20,
        minimumPaymentInCents: 5000,
      );

      final result = calculator.calculate(
        debts: [debtLarge, debtSmall],
        extraMonthlyPaymentInCents: 5000,
        strategy: DebtPayoffStrategy.snowball,
      );

      expect(result.debts.first.debtId, 'card_small');
      expect(result.debts.last.debtId, 'loan_large');
    });

    test('zero debts returns empty plan', () {
      final result = calculator.calculate(
        debts: const [],
        extraMonthlyPaymentInCents: 10000,
        strategy: DebtPayoffStrategy.avalanche,
      );

      expect(result.totalMonths, 0);
      expect(result.totalInterestPaidInCents, 0);
      expect(result.totalPaidInCents, 0);
      expect(result.isDebtFree, isFalse);
      expect(result.firstDebtPaidOff, isNull);
      expect(result.finalDebtPaidOff, isNull);
    });

    test('throws ArgumentError on negative extraMonthlyPaymentInCents', () {
      expect(
        () => calculator.calculate(
          debts: debts,
          extraMonthlyPaymentInCents: -1000,
          strategy: DebtPayoffStrategy.avalanche,
        ),
        throwsArgumentError,
      );

      expect(
        () => calculator.simulate(
          debts: debts,
          extraMonthlyPaymentInCents: -500,
          strategy: DebtPayoffStrategy.snowball,
        ),
        throwsArgumentError,
      );
    });

    test('payoff simulation eventually reaches zero', () {
      final result = calculator.simulate(
        debts: const [
          DebtPayoffItem(
            id: 'debt_1',
            name: 'Test Debt',
            balanceInCents: 50000,
            annualInterestRate: 0,
            minimumPaymentInCents: 10000,
          ),
        ],
        extraMonthlyPaymentInCents: 0,
        strategy: DebtPayoffStrategy.snowball,
      );

      expect(result.remainingBalanceInCents, 0);

      expect(result.totalMonths, 5);
      expect(result.latestSnapshot?.month, 5);
    });

    test('simulation produces monthly snapshots', () {
      final result = calculator.simulate(
        debts: const [
          DebtPayoffItem(
            id: 'debt_1',
            name: 'Test Debt',
            balanceInCents: 100000,
            annualInterestRate: 0,
            minimumPaymentInCents: 25000,
          ),
        ],
        extraMonthlyPaymentInCents: 0,
        strategy: DebtPayoffStrategy.snowball,
      );

      expect(result.snapshots.length, 4);

      expect(result.snapshots.last.totalRemainingBalanceInCents, 0);
    });

    test('empty simulation returns zeroed simulation', () {
      final result = calculator.simulate(
        debts: const [],
        extraMonthlyPaymentInCents: 1000,
        strategy: DebtPayoffStrategy.avalanche,
      );

      expect(result.snapshots, isEmpty);
      expect(result.totalMonths, 0);
      expect(result.latestSnapshot, isNull);
      expect(result.remainingBalanceInCents, 0);
    });

    test('DebtPayoffItem copyWith and isPaidOff check', () {
      const item = DebtPayoffItem(
        id: 'test',
        name: 'Item',
        balanceInCents: 500,
        annualInterestRate: 10.0,
        minimumPaymentInCents: 100,
        creditLimitInCents: 1000,
        category: 'Personal',
      );

      expect(item.isPaidOff, isFalse);

      final updated = item.copyWith(balanceInCents: 0, name: 'Item Paid');

      expect(updated.isPaidOff, isTrue);
      expect(updated.name, 'Item Paid');
      expect(updated.id, 'test');
      expect(updated.creditLimitInCents, 1000);
      expect(updated.category, 'Personal');
    });
  });
}
