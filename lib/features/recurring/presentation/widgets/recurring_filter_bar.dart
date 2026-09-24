import 'package:flutter/material.dart';

enum CycleFilter { all, weekly, monthly, yearly }

enum StatusFilter { all, active, paused, cancelled }

class RecurringFilterBar extends StatelessWidget {
  final CycleFilter selectedCycle;
  final StatusFilter selectedStatus;
  final ValueChanged<CycleFilter> onCycleChanged;
  final ValueChanged<StatusFilter> onStatusChanged;
  final int totalCount;
  final int weeklyCount;
  final int monthlyCount;
  final int annualCount;
  final int activeCount;
  final int pausedCount;
  final int cancelledCount;

  const RecurringFilterBar({
    super.key,
    required this.selectedCycle,
    required this.selectedStatus,
    required this.onCycleChanged,
    required this.onStatusChanged,
    this.totalCount = 0,
    this.weeklyCount = 0,
    this.monthlyCount = 0,
    this.annualCount = 0,
    this.activeCount = 0,
    this.pausedCount = 0,
    this.cancelledCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cycle Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text('All ($totalCount)'),
                selected: selectedCycle == CycleFilter.all,
                onSelected: (val) {
                  if (val) onCycleChanged(CycleFilter.all);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Weekly ($weeklyCount)'),
                selected: selectedCycle == CycleFilter.weekly,
                onSelected: (val) {
                  if (val) onCycleChanged(CycleFilter.weekly);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Monthly ($monthlyCount)'),
                selected: selectedCycle == CycleFilter.monthly,
                onSelected: (val) {
                  if (val) onCycleChanged(CycleFilter.monthly);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Annual ($annualCount)'),
                selected: selectedCycle == CycleFilter.yearly,
                onSelected: (val) {
                  if (val) onCycleChanged(CycleFilter.yearly);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Status Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Status'),
                selected: selectedStatus == StatusFilter.all,
                onSelected: (val) {
                  if (val) onStatusChanged(StatusFilter.all);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Active ($activeCount)'),
                selected: selectedStatus == StatusFilter.active,
                onSelected: (val) {
                  if (val) onStatusChanged(StatusFilter.active);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Paused ($pausedCount)'),
                selected: selectedStatus == StatusFilter.paused,
                onSelected: (val) {
                  if (val) onStatusChanged(StatusFilter.paused);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Cancelled ($cancelledCount)'),
                selected: selectedStatus == StatusFilter.cancelled,
                onSelected: (val) {
                  if (val) onStatusChanged(StatusFilter.cancelled);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
