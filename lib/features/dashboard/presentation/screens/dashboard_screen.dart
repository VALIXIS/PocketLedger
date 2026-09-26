import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';

export '../pages/dashboard_page.dart';

/// Legacy screen entry point for PocketLedger Dashboard.
///
/// Delegates directly to [DashboardPage] to ensure full backwards compatibility
/// across existing navigation and routing references.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
