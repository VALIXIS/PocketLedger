import 'package:uuid/uuid.dart';
import '../../features/transactions/domain/models/transaction.dart';
import '../../features/transactions/domain/models/transaction_type.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';

class DemoDataSeeder {
  static List<Transaction> get sampleTransactions {
    final now = DateTime.now();
    const uuid = Uuid();

    return [
      Transaction(
        id: uuid.v4(),
        type: TransactionType.income,
        amountInCents: Transaction.doubleToCents(4500.00),
        category: 'salary',
        date: now.subtract(const Duration(days: 28)),
        note: 'Monthly Salary - VALIXIS Tech',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.income,
        amountInCents: Transaction.doubleToCents(850.00),
        category: 'freelance',
        date: now.subtract(const Duration(days: 18)),
        note: 'UI/UX Design Project Milestone',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.income,
        amountInCents: Transaction.doubleToCents(220.00),
        category: 'investment',
        date: now.subtract(const Duration(days: 10)),
        note: 'Quarterly Stock Dividend',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(1200.00),
        category: 'bills',
        date: now.subtract(const Duration(days: 25)),
        note: 'Monthly Apartment Rent',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(245.50),
        category: 'food',
        date: now.subtract(const Duration(days: 20)),
        note: 'Weekly Grocery Supermarket',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(110.00),
        category: 'bills',
        date: now.subtract(const Duration(days: 15)),
        note: 'Electricity & Utility Bill',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(85.00),
        category: 'food',
        date: now.subtract(const Duration(days: 12)),
        note: 'Team Dinner & Drinks',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(149.99),
        category: 'shopping',
        date: now.subtract(const Duration(days: 8)),
        note: 'Wireless Ergonomic Keyboard',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(45.00),
        category: 'health',
        date: now.subtract(const Duration(days: 7)),
        note: 'Gym Monthly Membership',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(320.00),
        category: 'travel',
        date: now.subtract(const Duration(days: 4)),
        note: 'Weekend Getaway Flight',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(55.00),
        category: 'transport',
        date: now.subtract(const Duration(days: 2)),
        note: 'Car Fuel Refill',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amountInCents: Transaction.doubleToCents(14.50),
        category: 'food',
        date: now.subtract(const Duration(hours: 4)),
        note: 'Artisanal Coffee & Muffin',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  static Future<int> seedDemoData(TransactionRepository repository) async {
    final samples = sampleTransactions;
    for (final tx in samples) {
      await repository.saveTransaction(tx);
    }
    return samples.length;
  }

  static Future<void> clearAllData(TransactionRepository repository) async {
    final currentList = await repository.getTransactions();
    for (final tx in currentList) {
      await repository.deleteTransaction(tx.id);
    }
  }
}
