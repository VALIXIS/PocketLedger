import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/financial_context_engine.dart';
import '../../../../core/utilities/demo_data_seeder.dart';
import '../../../../core/utilities/report_export_helper.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final repository = ref.read(transactionRepositoryProvider);

    final currencies = [
      {'code': 'USD', 'name': r'US Dollar ($)'},
      {'code': 'EUR', 'name': 'Euro (€)'},
      {'code': 'INR', 'name': 'Indian Rupee (₹)'},
      {'code': 'GBP', 'name': 'British Pound (£)'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Preferences Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      value: settings.currency,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          settingsNotifier.setCurrency(newValue);
                        }
                      },
                      items: currencies.map<DropdownMenuItem<String>>((
                        currency,
                      ) {
                        return DropdownMenuItem<String>(
                          value: currency['code'],
                          child: Text(currency['name']!),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (bool isDark) {
                        settingsNotifier.setThemeMode(
                          isDark ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Data Management Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Management & Demo Utilities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.12),
                    child: const Icon(Icons.dataset_outlined, color: Colors.teal),
                  ),
                  title: const Text('Seed Demo Transactions'),
                  subtitle: const Text('Populate 12+ realistic sample transactions'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final count = await DemoDataSeeder.seedDemoData(repository);
                    await ref.read(transactionListProvider.notifier).loadTransactions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully seeded $count sample transactions!'),
                          backgroundColor: Colors.teal.shade700,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                    child: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                  ),
                  title: const Text('Clear All Transactions'),
                  subtitle: const Text('Reset local database to initial empty state'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset All Transactions?'),
                        content: const Text('This will delete all stored transactions from Hive.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await DemoDataSeeder.clearAllData(repository);
                              await ref.read(transactionListProvider.notifier).loadTransactions();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Database reset successfully!')),
                                );
                              }
                            },
                            child: const Text('Reset', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // AI Telemetry Report Export Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Financial Report Export',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                    child: const Icon(Icons.copy_all_outlined, color: Colors.indigo),
                  ),
                  title: const Text('Copy AI Health Report'),
                  subtitle: const Text('Export telemetry summary to markdown format'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final txs = ref.read(transactionListProvider).value ?? [];
                    final telemetry = FinancialContextEngine.aggregate(txs);
                    await ReportExportHelper.copyReportToClipboard(telemetry);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('AI Financial Report copied to clipboard!'),
                          backgroundColor: Colors.indigo.shade700,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // About section
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About PocketLedger',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PocketLedger is an enterprise-grade AI personal finance management engine developed by VALIXIS. It features offline-first Hive storage, Riverpod state management, and privacy-preserving Gemini telemetry.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    Text('1.0.0+1', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Developer & Platform', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    Text('VALIXIS', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
