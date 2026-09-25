import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';

/// Presentation section for recent ledger transactions.
class RecentActivitySection extends StatelessWidget {
  /// Asynchronous transaction list.
  final List<Transaction> transactions;

  /// Currency code.
  final String currency;

  /// Maximum items to display in the dashboard preview. Defaults to 5.
  final int maxItems;

  const RecentActivitySection({
    super.key,
    required this.transactions,
    required this.currency,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark && theme.scaffoldBackgroundColor == AppColors.oledBackground;

    if (transactions.isEmpty) {
      return _buildEmptyState(context, isDark, isOled);
    }

    final displayList = transactions.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
            if (transactions.length > maxItems)
              Text(
                'Showing ${displayList.length} of ${transactions.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOled
                      ? AppColors.oledTextSecondary
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),

        // List of Transaction Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: displayList.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.space8),
          itemBuilder: (context, index) {
            final tx = displayList[index];
            return _buildTransactionTile(context, tx, isDark, isOled);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction tx,
    bool isDark,
    bool isOled,
  ) {
    final catIcon = CategoryUiHelper.getIcon(tx.category);
    final catColor = CategoryUiHelper.getColor(tx.category);
    final isIncome = tx.type == TransactionType.income;

    final categoryName = tx.category.isNotEmpty
        ? tx.category.substring(0, 1).toUpperCase() +
              tx.category.substring(1).replaceAll('_', ' ')
        : 'General';

    final formattedAmount = CurrencyFormatter.formatCents(
      tx.amountInCents,
      currency,
    );
    final amountText = '${isIncome ? '+' : '−'} $formattedAmount';

    final amountColor = isIncome
        ? (isDark ? AppColors.success : AppColors.successDark)
        : (isDark ? AppColors.error : AppColors.errorDark);

    final cardBg = isOled
        ? AppColors.oledCard
        : (isDark ? AppColors.darkCard : AppColors.lightCard);

    final border = isOled
        ? AppColors.oledBorder
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  TransactionFormScreen(transactionToEdit: tx),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.radius16),
            border: Border.all(color: border, width: 1),
            boxShadow: isOled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.02,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Category Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: catColor.withValues(alpha: 0.12),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.space12),

              // Title and Note / Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isOled
                            ? AppColors.oledTextPrimary
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      tx.note.isNotEmpty
                          ? tx.note
                          : CurrencyFormatter.formatDate(tx.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOled
                            ? AppColors.oledTextSecondary
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),

              // Amount
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isOled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space40,
      ),
      decoration: BoxDecoration(
        color: isOled
            ? AppColors.oledCard
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppRadius.radius20),
        border: Border.all(
          color: isOled
              ? AppColors.oledBorder
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: isOled
                  ? AppColors.oledSurfaceVariant
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: isOled
                  ? AppColors.oledTextSecondary
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOled
                  ? AppColors.oledTextPrimary
                  : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'Add your first transaction below to start tracking your net balance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isOled
                  ? AppColors.oledTextSecondary
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
