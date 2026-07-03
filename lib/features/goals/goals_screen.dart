import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/info_dialog.dart';
import '../../shared/widgets/menu_avatar_button.dart';
import '../../shared/widgets/side_drawer.dart';
import 'goal_modal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GoalModal(),
    );
  }

  void _showInfo(BuildContext context) {
    showInfoDialog(
      context,
      title: 'Obiettivi',
      message:
          'Qui puoi impostare e monitorare i tuoi obiettivi di risparmio. Tocca il pulsante "+" per crearne uno nuovo, "Aggiungi contributo" per registrare un versamento, o usa il menu (⋮) su una voce per modificarla o eliminarla.',
    );
  }

  void _openEdit(BuildContext context, AppGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalModal(goal: goal),
    );
  }

  void _openContribute(BuildContext context, AppGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContributeModal(goal: goal),
    );
  }

  Future<void> _delete(BuildContext context, AppGoal goal) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Elimina obiettivo',
      message: 'Questa azione non può essere annullata.',
    );
    if (ok == true && context.mounted) {
      await context.read<DataProvider>().deleteGoal(goal.id);
      if (context.mounted) showAppToast(context, 'Obiettivo eliminato');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const SideDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Obiettivi',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfo(context),
              ),
              MenuAvatarButton(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: data.goals.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Nessun obiettivo definito',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crea il tuo primo obiettivo',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final goal = data.goals[i];
                        final progress = data.computeGoalProgress(goal);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(
                            goal: goal,
                            progress: progress,
                            onEdit: () => _openEdit(context, goal),
                            onDelete: () => _delete(context, goal),
                            onContribute: () => _openContribute(context, goal),
                          ),
                        );
                      },
                      childCount: data.goals.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        backgroundColor: AppColors.mainBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final AppGoal goal;
  final double progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onContribute;

  const _GoalCard({
    required this.goal,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
    required this.onContribute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final pct = (progress * 100).clamp(0, 100);
    final pctStr = pct.toStringAsFixed(0);
    final isComplete = progress >= 1;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.4)
              : borderColor,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (goal.period != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        goal.period == 'mensile' ? 'Mensile' : 'Totale',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mainBlue,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✅ Completato',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (v) {
                  if (v == 'contribute') onContribute();
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'contribute', child: Text('Aggiungi contributo')),
                  const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                  const PopupMenuItem(value: 'delete', child: Text('Elimina')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pctStr% completato',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isComplete ? AppColors.success : AppColors.mainBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Target: ${formatCurrency(goal.targetAmount)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  (isComplete ? AppColors.success : AppColors.mainBlue)
                      .withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? AppColors.success : AppColors.mainBlue),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onContribute,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Aggiungi contributo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mainBlue,
                side: const BorderSide(color: AppColors.mainBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
