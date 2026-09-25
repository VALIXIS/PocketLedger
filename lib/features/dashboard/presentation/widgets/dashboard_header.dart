import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budgets/presentation/screens/budget_list_screen.dart';
import '../../../recurring/presentation/screens/recurring_manager_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Clean, responsive dashboard greeting header for PocketLedger.
///
/// Dynamically calculates greeting based on time of day, presents the financial
/// overview context, and provides accessible quick action buttons.
class DashboardHeader extends StatelessWidget {
  /// Optional custom greeting override. If null, automatically computes from current hour.
  final String? customGreeting;

  /// Optional subtitle. Defaults to 'Your financial overview'.
  final String subtitle;

  const DashboardHeader({
    super.key,
    this.customGreeting,
    this.subtitle = 'Your financial overview',
  });

  String _computeGreeting() {
    if (customGreeting != null) return customGreeting!;
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark && theme.scaffoldBackgroundColor == AppColors.oledBackground;

    final greeting = _computeGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isOled
                        ? AppColors.oledTextPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isOled
                        ? AppColors.oledTextSecondary
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: 'Budgets & Pacing',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BudgetListScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.repeat_rounded),
                tooltip: 'Recurring Transactions',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecurringManagerScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
