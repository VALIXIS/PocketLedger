import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';

/// Clean Material 3 Card displaying a single search result transaction.
class SearchTransactionCard extends ConsumerWidget {
  final Transaction transaction;

  const SearchTransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isIncome = transaction.type == TransactionType.income;
    final catColor = CategoryUiHelper.getColor(transaction.category);
    final catIcon = CategoryUiHelper.getIcon(transaction.category);

    final categoryName = transaction.category.isNotEmpty
        ? transaction.category.substring(0, 1).toUpperCase() +
              transaction.category.substring(1).replaceAll('_', ' ')
        : 'Uncategorized';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TransactionFormScreen(transactionToEdit: transaction),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: catColor.withValues(alpha: 0.12),
          child: Icon(catIcon, color: catColor),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note.trim().isNotEmpty) ...[
              Text(
                transaction.note,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            Text(
              CurrencyFormatter.formatDate(transaction.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatCents(transaction.amountInCents, settings.currency)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}
