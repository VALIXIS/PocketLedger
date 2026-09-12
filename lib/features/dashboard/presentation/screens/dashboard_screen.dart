import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketLedger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.teal),
            tooltip: 'Gemini AI Assistant',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AIAssistantScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(transactionListProvider.notifier).loadTransactions();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            children: [
              // Summary card
              _buildSummaryCard(context, stats, settings.currency),
              const SizedBox(height: 24),

              // Recent Transactions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  transactionsAsync.maybeWhen(
                    data: (list) => list.length > 5
                        ? TextButton(
                            onPressed: () {
                              // Standard behavior for showing all transactions
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'All transactions are shown below',
                                  ),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent Transactions list
              transactionsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Limit dashboard view to 10 items
                  final displayList = list.take(10).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final tx = displayList[index];
                      final catIcon = CategoryUiHelper.getIcon(tx.category);
                      final catColor = CategoryUiHelper.getColor(tx.category);
                      final isIncome = tx.type == TransactionType.income;

                      // Map category ID to printable name
                      final categoryName =
                          tx.category.substring(0, 1).toUpperCase() +
                          tx.category.substring(1).replaceAll('_', ' ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TransactionFormScreen(
                                  transactionToEdit: tx,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: catColor.withValues(alpha: 0.12),
                            child: Icon(catIcon, color: catColor),
                          ),
                          title: Text(
                            categoryName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tx.note.isNotEmpty) ...[
                                Text(
                                  tx.note,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                CurrencyFormatter.formatDate(tx.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatCents(tx.amountInCents, settings.currency)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isIncome
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text('Error loading transactions: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    DashboardStats stats,
    String currency,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? const Color(0xFF1E1E1E)
          : Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'NET BALANCE',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatCents(stats.balanceInCents, currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatCents(
                                stats.totalIncomeInCents,
                                currency,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.white24),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatCents(
                                stats.totalExpensesInCents,
                                currency,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to add your first transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
