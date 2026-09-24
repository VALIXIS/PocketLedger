import 'package:flutter/material.dart';

class GoalMilestone {
  final String label;
  final double threshold;
  final IconData icon;
  final Color color;

  const GoalMilestone({
    required this.label,
    required this.threshold,
    required this.icon,
    required this.color,
  });

  static const List<GoalMilestone> allMilestones = [
    GoalMilestone(
      label: 'Getting Started',
      threshold: 0.0,
      icon: Icons.flag_outlined,
      color: Color(0xFF607D8B),
    ),
    GoalMilestone(
      label: 'Quarter Way',
      threshold: 0.25,
      icon: Icons.trending_up_rounded,
      color: Color(0xFF0288D1),
    ),
    GoalMilestone(
      label: 'Halfway There',
      threshold: 0.50,
      icon: Icons.star_half_rounded,
      color: Color(0xFF7B1FA2),
    ),
    GoalMilestone(
      label: 'Almost There',
      threshold: 0.75,
      icon: Icons.bolt_rounded,
      color: Color(0xFFE65100),
    ),
    GoalMilestone(
      label: 'Goal Achieved',
      threshold: 1.0,
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF2E7D32),
    ),
  ];

  static List<GoalMilestone> getReachedMilestones(double progress) {
    return allMilestones.where((m) => progress >= m.threshold).toList();
  }

  static GoalMilestone getHighestMilestone(double progress) {
    if (progress >= 1.0) {
      return allMilestones[4];
    } else if (progress >= 0.75) {
      return allMilestones[3];
    } else if (progress >= 0.50) {
      return allMilestones[2];
    } else if (progress >= 0.25) {
      return allMilestones[1];
    } else {
      return allMilestones[0];
    }
  }
}

class GoalMilestoneBadge extends StatelessWidget {
  final double progress;
  final bool showIconOnly;

  const GoalMilestoneBadge({
    super.key,
    required this.progress,
    this.showIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final milestone = GoalMilestone.getHighestMilestone(progress);
    final isAchieved = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: milestone.color.withValues(alpha: isAchieved ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: milestone.color.withValues(alpha: isAchieved ? 0.6 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(milestone.icon, size: 16, color: milestone.color),
          if (!showIconOnly) ...[
            const SizedBox(width: 6),
            Text(
              milestone.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAchieved ? FontWeight.bold : FontWeight.w600,
                color: milestone.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
