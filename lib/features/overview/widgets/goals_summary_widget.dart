import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/data_provider.dart';

class GoalsSummaryWidget extends StatelessWidget {
  final List<AppGoal> goals;
  final double Function(AppGoal) computeProgress;

  const GoalsSummaryWidget({
    super.key,
    required this.goals,
    required this.computeProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (goals.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Nessun obiettivo definito',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final shown = goals.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: shown.map((goal) {
          final progress = computeProgress(goal);
          final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.mainBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color.fromARGB(255, 16, 121, 201)
                        .withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.mainBlue),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
