import 'package:flutter/material.dart';

/// A stylized, Material 3 theme-integrated [RefreshIndicator] for the PocketLedger Dashboard.
///
/// Features smooth trigger dynamics, theme-aware progress indicators, and works
/// seamlessly with [CustomScrollView] and sliver architectures.
class DashboardRefreshIndicator extends StatelessWidget {
  /// The scrollable child (e.g. [CustomScrollView]).
  final Widget child;

  /// Asynchronous refresh callback invoked on pull-to-refresh.
  final Future<void> Function() onRefresh;

  /// Optional displacement distance from top edge. Defaults to 40.0.
  final double displacement;

  /// Optional edge offset.
  final double edgeOffset;

  const DashboardRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      edgeOffset: edgeOffset,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
