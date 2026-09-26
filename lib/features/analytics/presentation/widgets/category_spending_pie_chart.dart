import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../features/transactions/domain/models/transaction.dart';
import '../providers/analytics_providers.dart';

/// An interactive Donut Chart widget displaying category expense breakdown.
///
/// Consumes [categorySpendingProvider] and supports touch slice selection
/// with dynamic category detail breakdown.
class CategorySpendingPieChart extends ConsumerStatefulWidget {
  const CategorySpendingPieChart({super.key});

  @override
  ConsumerState<CategorySpendingPieChart> createState() =>
      _CategorySpendingPieChartState();
}

class _CategorySpendingPieChartState
    extends ConsumerState<CategorySpendingPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final spendingMap = ref.watch(categorySpendingProvider);
    final currency = ref.watch(settingsProvider).currency;

    // Filter out categories with zero or negative spending
    final entries = spendingMap.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Highest first

    final totalExpenses = entries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    // Empty State Check
    if (entries.isEmpty || totalExpenses <= 0) {
      return _buildEmptyState(context);
    }

    // Reset touched index if out of bounds (e.g. data updated/deleted)
    if (_touchedIndex != null && _touchedIndex! >= entries.length) {
      _touchedIndex = null;
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Breakdown by Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Donut Chart Container
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback:
                          (
                            FlTouchEvent event,
                            PieTouchResponse? pieTouchResponse,
                          ) {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              return;
                            }

                            final index = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;

                            if (event is FlTapUpEvent) {
                              setState(() {
                                if (index >= 0 && index < entries.length) {
                                  if (_touchedIndex == index) {
                                    _touchedIndex = null; // Clear selection
                                  } else {
                                    _touchedIndex = index; // Select new slice
                                  }
                                } else {
                                  _touchedIndex = null;
                                }
                              });
                            }
                          },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    sections: List.generate(entries.length, (i) {
                      final isTouched = i == _touchedIndex;
                      final entry = entries[i];
                      final pct = (entry.value / totalExpenses) * 100.0;
                      final radius = isTouched ? 48.0 : 38.0;
                      final catColor = CategoryUiHelper.getColor(entry.key);

                      return PieChartSectionData(
                        color: catColor,
                        value: entry.value,
                        title: pct >= 8.0 ? '${pct.toStringAsFixed(0)}%' : '',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 14.0 : 11.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // Center Hole Info Display
                _buildCenterHoleContent(
                  context,
                  entries,
                  totalExpenses,
                  currency,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Selected Category Detail Breakdown Section
          _buildDetailBreakdown(context, entries, totalExpenses, currency),
        ],
      ),
    );
  }

  /// Builds content inside the donut hole (Center text)
  Widget _buildCenterHoleContent(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    double totalExpenses,
    String currency,
  ) {
    if (_touchedIndex != null && _touchedIndex! < entries.length) {
      final selectedEntry = entries[_touchedIndex!];
      final pct = (selectedEntry.value / totalExpenses) * 100.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: CategoryUiHelper.getColor(selectedEntry.key),
            ),
          ),
          const Text(
            'Selected',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CurrencyFormatter.formatCents(
            Transaction.doubleToCents(totalExpenses),
            currency,
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'Total Spent',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  /// Builds the detail breakdown card area below the chart
  Widget _buildDetailBreakdown(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    double totalExpenses,
    String currency,
  ) {
    final isSelected = _touchedIndex != null && _touchedIndex! < entries.length;

    final categoryKey = isSelected ? entries[_touchedIndex!].key : 'Total';
    final amount = isSelected ? entries[_touchedIndex!].value : totalExpenses;
    final pct = isSelected ? (amount / totalExpenses) * 100.0 : 100.0;

    final formattedName = isSelected
        ? (categoryKey.substring(0, 1).toUpperCase() +
              categoryKey.substring(1).replaceAll('_', ' '))
        : 'All Expenses';

    final catIcon = isSelected
        ? CategoryUiHelper.getIcon(categoryKey)
        : Icons.donut_small_outlined;
    final catColor = isSelected
        ? CategoryUiHelper.getColor(categoryKey)
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: catColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: catColor.withValues(alpha: 0.2),
            child: Icon(catIcon, color: catColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.formatCents(
                        Transaction.doubleToCents(amount),
                        currency,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      isSelected
                          ? 'Tap slice again to clear'
                          : 'Tap any slice to inspect',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds clean empty state when no expenses exist
  Widget _buildEmptyState(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Expense Breakdown by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.pie_chart_outline,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No Expense Category Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add expense transactions to see your interactive category breakdown.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
