import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/financial_goal.dart';
import '../providers/goal_list_notifier.dart';
import 'contribution_modal.dart';
import 'goal_form.dart';
import 'goal_milestone_badges.dart';
import 'goal_progress_indicator.dart';

class GoalCard extends ConsumerWidget {
  final FinancialGoal goal;

  const GoalCard({super.key, required this.goal});

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'car':
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'flight':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'laptop':
      case 'tech':
        return Icons.laptop_mac_rounded;
      case 'school':
      case 'education':
        return Icons.school_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'heart':
      case 'health':
        return Icons.favorite_rounded;
      case 'emergency':
        return Icons.health_and_safety_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'savings':
      default:
        return Icons.savings_rounded;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text(
          'Are you sure you want to delete "${goal.name}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(goalListNotifierProvider.notifier)
                    .deleteGoal(goal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal "${goal.name}" deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete goal: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    Color textColor;
    String label;

    switch (goal.status) {
      case GoalStatus.active:
        chipColor = Colors.teal.shade50;
        textColor = Colors.teal.shade800;
        label = 'ACTIVE';
        break;
      case GoalStatus.completed:
        chipColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = 'COMPLETED';
        break;
      case GoalStatus.paused:
        chipColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = 'PAUSED';
        break;
      case GoalStatus.cancelled:
        chipColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = 'CANCELLED';
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      chipColor = chipColor.withValues(alpha: 0.15);
      textColor = textColor.withValues(alpha: 0.9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(settingsProvider).currency;
    final goalIcon = getIconData(goal.iconName);
    final goalColor = Color(goal.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon, Title, Status & Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: goalColor.withValues(alpha: 0.15),
                  child: Icon(goalIcon, color: goalColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (goal.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          goal.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(context),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        if (action == 'edit') {
                          GoalForm.showEditGoal(context, goal);
                        } else if (action == 'delete') {
                          _showDeleteConfirmation(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Edit Goal'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Delete Goal',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Saved vs Target Progress Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          CurrencyFormatter.formatCents(
                            goal.savedAmountInCents,
                            currency,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'of ${CurrencyFormatter.formatCents(goal.targetAmountInCents, currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.progressPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: goal.isCompleted ? Colors.green.shade600 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            GoalProgressIndicator(
              progress: goal.progress,
              color: goal.isCompleted ? Colors.green.shade600 : goalColor,
              height: 8,
            ),
            const SizedBox(height: 12),

            // Remaining Amount & Target Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.isCompleted
                        ? 'Goal Reached! 🏆'
                        : '${CurrencyFormatter.formatCents(goal.remainingAmountInCents, currency)} remaining',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: goal.isCompleted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: goal.isCompleted
                          ? Colors.green.shade600
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      goal.targetDate != null
                          ? CurrencyFormatter.formatDate(goal.targetDate!)
                          : 'No target date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Milestone Badge & Add Money Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: GoalMilestoneBadge(progress: goal.progress)),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => ContributionModal.show(context, goal),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Money'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
