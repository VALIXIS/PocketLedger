import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Premium Material 3 side [NavigationRail] for tablet and desktop viewports.
///
/// Shares destination indices and semantics with the phone [NavigationBar],
/// while adapting to Light, Dark, and true OLED pitch-black themes.
class TabletNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isExtended;
  final Widget? leading;
  final Widget? trailing;

  const TabletNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isExtended = false,
    this.leading,
    this.trailing,
  });

  void _handleDestinationSelected(int index) {
    if (index == selectedIndex) return;
    HapticFeedback.selectionClick();
    onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled =
        isDark &&
        (theme.scaffoldBackgroundColor == AppColors.oledBackground ||
            theme.scaffoldBackgroundColor == Colors.black);

    // Theme-adaptive surface color
    final railBgColor = isOled
        ? AppColors.oledSurface
        : isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    final defaultLeading = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
    );

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: _handleDestinationSelected,
      extended: isExtended,
      backgroundColor: railBgColor,
      labelType: isExtended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      minWidth: 72,
      minExtendedWidth: 200,
      leading: leading ?? defaultLeading,
      trailing: trailing,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: Text('Plan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: Text('AI Assistant'),
        ),
      ],
    );
  }
}
