import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quick_filter_tag.dart';
import '../providers/search_providers.dart';

/// Horizontal scrollable bar of multi-tag quick filter chips.
class QuickFilterChipsBar extends ConsumerWidget {
  const QuickFilterChipsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTags = ref.watch(searchQuickFiltersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: QuickFilterTag.values.map((tag) {
          final isSelected = selectedTags.contains(tag);
          IconData tagIcon;
          switch (tag) {
            case QuickFilterTag.income:
              tagIcon = Icons.arrow_downward_rounded;
              break;
            case QuickFilterTag.expense:
              tagIcon = Icons.arrow_upward_rounded;
              break;
            case QuickFilterTag.today:
              tagIcon = Icons.today_rounded;
              break;
            case QuickFilterTag.thisWeek:
              tagIcon = Icons.calendar_view_week_rounded;
              break;
            case QuickFilterTag.thisMonth:
              tagIcon = Icons.calendar_month_rounded;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag.label),
              avatar: Icon(
                tagIcon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              checkmarkColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (_) {
                ref
                    .read(searchNotifierProvider.notifier)
                    .toggleQuickFilter(tag);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
