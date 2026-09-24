import 'package:flutter/material.dart';
import '../../domain/entities/budget_stress_scenario.dart';
import '../../domain/entities/budget_stress_test.dart';
import '../../domain/services/budget_stress_test_engine.dart';

/// Interactive Material 3 card widget for executing and displaying budget stress tests.
class BudgetStressTestSection extends StatefulWidget {
  final int allocationInCents;
  final int currentSpendingInCents;
  final BudgetStressTestEngine engine;

  const BudgetStressTestSection({
    super.key,
    required this.allocationInCents,
    required this.currentSpendingInCents,
    this.engine = const BudgetStressTestEngine(),
  });

  @override
  State<BudgetStressTestSection> createState() =>
      _BudgetStressTestSectionState();
}

class _BudgetStressTestSectionState extends State<BudgetStressTestSection> {
  BudgetStressScenario _selectedScenario = BudgetStressScenario.moderate;

  Color _getStatusColor(BudgetStressStatus status, ColorScheme colorScheme) {
    switch (status) {
      case BudgetStressStatus.withinBudget:
        return colorScheme.primary;
      case BudgetStressStatus.nearLimit:
        return colorScheme.tertiary;
      case BudgetStressStatus.exceeded:
        return colorScheme.error;
    }
  }

  String _getStatusLabel(BudgetStressStatus status) {
    switch (status) {
      case BudgetStressStatus.withinBudget:
        return 'WITHIN BUDGET';
      case BudgetStressStatus.nearLimit:
        return 'NEAR LIMIT';
      case BudgetStressStatus.exceeded:
        return 'EXCEEDED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final testResult = widget.engine.run(
      allocationInCents: widget.allocationInCents,
      currentSpendingInCents: widget.currentSpendingInCents,
      scenario: _selectedScenario,
    );

    final statusColor = _getStatusColor(testResult.status, colorScheme);
    final statusLabel = _getStatusLabel(testResult.status);

    return Card(
      key: const Key('budget_stress_test_section'),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.speed_outlined,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Budget Stress Test',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  key: const Key('stress_status_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Simulate inflation and spending spikes to test how much pressure your budget can absorb.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stress Scenario',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: BudgetStressScenario.values.map((scenario) {
                  final isSelected = _selectedScenario == scenario;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      key: Key('scenario_chip_${scenario.name}'),
                      label: Text(scenario.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedScenario = scenario;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMetricRow(
                    context,
                    label: 'Current Allocation',
                    value:
                        '\$${(testResult.allocationInCents / 100.0).toStringAsFixed(2)}',
                  ),
                  const Divider(height: 16),
                  _buildMetricRow(
                    context,
                    label: 'Current Spending',
                    value:
                        '\$${(testResult.currentSpendingInCents / 100.0).toStringAsFixed(2)}',
                  ),
                  const Divider(height: 16),
                  _buildMetricRow(
                    context,
                    label: 'Stressed Spending (${_selectedScenario.label})',
                    value:
                        '\$${(testResult.stressedSpendingInCents / 100.0).toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: statusColor,
                  ),
                  const Divider(height: 16),
                  _buildMetricRow(
                    context,
                    label: testResult.exceedsBudget
                        ? 'Deficit / Overspending'
                        : 'Remaining After Stress',
                    value: testResult.exceedsBudget
                        ? 'Over by \$${((testResult.stressedSpendingInCents - testResult.allocationInCents) / 100.0).toStringAsFixed(2)}'
                        : '\$${(testResult.remainingInCents / 100.0).toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: statusColor,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (testResult.utilizationPercent / 100.0).clamp(
                        0.0,
                        1.0,
                      ),
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
