import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../features/transactions/domain/models/transaction.dart';
import '../providers/analytics_providers.dart';

/// A monthly income vs expense comparative bar chart widget.
///
/// Consumes [monthlyTrendProvider] and displays side-by-side bars for
/// income and expenses per month with custom touch tooltips.
class MonthlyCashflowBarChart extends ConsumerStatefulWidget {
  const MonthlyCashflowBarChart({super.key});

  @override
  ConsumerState<MonthlyCashflowBarChart> createState() =>
      _MonthlyCashflowBarChartState();
}

class _MonthlyCashflowBarChartState
    extends ConsumerState<MonthlyCashflowBarChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final trends = ref.watch(monthlyTrendProvider);
    final currency = ref.watch(settingsProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter out empty trends and limit to latest 6 months for clean bar spacing
    final displayTrends =
        trends.isEmpty ? <dynamic>[] : trends.take(6).toList();

    if (displayTrends.isEmpty) {
      return _buildEmptyState(context);
    }

    // Find max value for Y axis calculation
    double maxVal = 0.0;
    for (final t in displayTrends) {
      if (t.totalIncome > maxVal) maxVal = t.totalIncome;
      if (t.totalExpenses > maxVal) maxVal = t.totalExpenses;
    }
    if (maxVal <= 0) maxVal = 100.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Cashflow Comparison',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              _buildLegend(context),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) {
                      return isDark
                          ? const Color(0xFF2A363F)
                          : const Color(0xFF1E262B);
                    },
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= displayTrends.length) {
                        return null;
                      }
                      final trend = displayTrends[groupIndex];
                      final monthName = DateFormat(
                        'MMM yyyy',
                      ).format(DateTime(trend.year, trend.month));
                      final isIncome = rodIndex == 0;
                      final typeStr = isIncome ? 'Income' : 'Expense';
                      final formattedAmount = CurrencyFormatter.formatCents(
                        Transaction.doubleToCents(rod.toY),
                        currency,
                      );

                      return BarTooltipItem(
                        '$monthName\n$typeStr\n$formattedAmount',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  touchCallback: (
                    FlTouchEvent event,
                    BarTouchResponse? response,
                  ) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _touchedGroupIndex = null;
                        return;
                      }
                      _touchedGroupIndex =
                          response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        if (value >= 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < displayTrends.length) {
                          final trend = displayTrends[index];
                          final label = DateFormat('MMM').format(
                            DateTime(trend.year, trend.month),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: index == _touchedGroupIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: index == _touchedGroupIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayTrends.length, (i) {
                  final trend = displayTrends[i];
                  final isTouched = i == _touchedGroupIndex;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: trend.totalIncome,
                        color: Colors.green.shade600,
                        width: isTouched ? 14 : 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: trend.totalExpenses,
                        color: Colors.redAccent.shade400,
                        width: isTouched ? 14 : 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds legend indicators for Income and Expenses
  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        _buildLegendItem('Income', Colors.green.shade600),
        const SizedBox(width: 12),
        _buildLegendItem('Expenses', Colors.redAccent.shade400),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  /// Builds empty state card when no cashflow trend data exists
  Widget _buildEmptyState(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Monthly Cashflow Comparison',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.bar_chart_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No Monthly Cashflow Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add income and expense transactions to see monthly comparison bars.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
