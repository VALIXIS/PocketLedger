import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../features/transactions/domain/models/transaction.dart';
import '../providers/analytics_providers.dart';

/// A 12-Month Spending Trend Line Chart widget.
///
/// Consumes [monthlyTrendProvider] and plots monthly expense trends for the
/// latest 12 calendar months with custom touch tooltips.
class SpendingTrendLineChart extends ConsumerStatefulWidget {
  const SpendingTrendLineChart({super.key});

  @override
  ConsumerState<SpendingTrendLineChart> createState() =>
      _SpendingTrendLineChartState();
}

class _SpendingTrendLineChartState
    extends ConsumerState<SpendingTrendLineChart> {
  int? _touchedSpotIndex;

  @override
  Widget build(BuildContext context) {
    final trends = ref.watch(monthlyTrendProvider);
    final currency = ref.watch(settingsProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Enforce 12-month maximum window (latest 12 months)
    final displayTrends =
        trends.length > 12 ? trends.sublist(trends.length - 12) : trends;

    if (displayTrends.isEmpty) {
      return _buildEmptyState(context);
    }

    // Find max expense value for Y axis scale
    double maxVal = 0.0;
    for (final t in displayTrends) {
      if (t.totalExpenses > maxVal) maxVal = t.totalExpenses;
    }
    if (maxVal <= 0) maxVal = 100.0;

    final spots = List.generate(displayTrends.length, (i) {
      return FlSpot(i.toDouble(), displayTrends[i].totalExpenses);
    });

    final lineColor = Theme.of(context).colorScheme.primary;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12-Month Spending Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '${displayTrends.length} ${displayTrends.length == 1 ? 'Month' : 'Months'} History',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                maxY: maxVal * 1.15,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) {
                      return isDark
                          ? const Color(0xFF2A363F)
                          : const Color(0xFF1E262B);
                    },
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= displayTrends.length) {
                          return null;
                        }
                        final trend = displayTrends[index];
                        final monthName = DateFormat(
                          'MMM yyyy',
                        ).format(DateTime(trend.year, trend.month));
                        final formattedAmount = CurrencyFormatter.formatCents(
                          Transaction.doubleToCents(spot.y),
                          currency,
                        );

                        return LineTooltipItem(
                          '$monthName\nSpending\n$formattedAmount',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (
                    FlTouchEvent event,
                    LineTouchResponse? response,
                  ) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.lineBarSpots == null ||
                          response.lineBarSpots!.isEmpty) {
                        _touchedSpotIndex = null;
                        return;
                      }
                      _touchedSpotIndex =
                          response.lineBarSpots!.first.spotIndex;
                    });
                  },
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
                                fontWeight: index == _touchedSpotIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: index == _touchedSpotIndex
                                    ? lineColor
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isTouched = index == _touchedSpotIndex;
                        return FlDotCirclePainter(
                          radius: isTouched ? 6 : 4,
                          color: isTouched ? Colors.white : lineColor,
                          strokeWidth: isTouched ? 3 : 2,
                          strokeColor: lineColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withValues(alpha: 0.25),
                          lineColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty state card when no spending trend data exists
  Widget _buildEmptyState(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '12-Month Spending Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.show_chart_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No Spending History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add expense transactions across months to visualize your 12-month spending curve.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
