import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/info_dialog.dart';
import '../../shared/widgets/menu_avatar_button.dart';
import '../../shared/widgets/side_drawer.dart';
import '../../shared/utils/category_style.dart';
import 'subscription_modal.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionModal(),
    );
  }

  void _showInfo(BuildContext context) {
    showInfoDialog(
      context,
      title: 'Abbonamenti',
      message:
          'Qui trovi tutti i tuoi abbonamenti ricorrenti e la spesa mensile totale. Tocca il pulsante "+" per aggiungerne uno nuovo, oppure usa il menu (⋮) su una voce per modificarla o eliminarla.',
    );
  }

  void _openEdit(BuildContext context, AppSubscription sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionModal(subscription: sub),
    );
  }

  void _showDetails(BuildContext context, AppSubscription sub) {
    final cat = context.read<DataProvider>().getCategoryById(sub.categoryId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscriptionDetailSheet(
        subscription: sub,
        category: cat,
        onEdit: () {
          Navigator.pop(context);
          _openEdit(context, sub);
        },
        onDelete: () {
          Navigator.pop(context);
          _delete(context, sub);
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, AppSubscription sub) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Elimina abbonamento',
      message: 'Questa azione non può essere annullata.',
    );
    if (ok == true && context.mounted) {
      await context.read<DataProvider>().deleteSubscription(sub.id);
      if (context.mounted) showAppToast(context, 'Abbonamento eliminato');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const SideDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Abbonamenti',
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
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Total monthly cost card
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 129, 26)
                        .withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromARGB(255, 253, 132, 34)
                          .withValues(alpha: 0.50),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spesa mensile totale',
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(data.totalSubscriptionCost),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (data.subscriptions.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('🔄', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'Nessun abbonamento',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aggiungi il tuo primo abbonamento',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  ...data.subscriptions.map((sub) {
                    final cat = data.getCategoryById(sub.categoryId);
                    final catColor = categoryColor(sub.categoryId);
                    final now = DateTime.now();
                    final nextRenewal = now.day < sub.expiryDay
                        ? DateTime(now.year, now.month, sub.expiryDay)
                        : DateTime(now.year, now.month + 1, sub.expiryDay);
                    final nextRenewalStr =
                        DateFormat('d MMM yyyy', 'it_IT').format(nextRenewal);
                    final autoRenewalActive = sub.categoryId != null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: ListTile(
                          onTap: () => _showDetails(context, sub),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: sub.logo != null
                                  ? Colors.transparent
                                  : catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: sub.logo != null
                                  ? _LogoImage(logo: sub.logo!)
                                  : Center(
                                      child: CategoryIcon(
                                        icon: cat?.icon ?? '🔄',
                                        size: 22,
                                        color: catColor,
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            sub.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                'Prossimo rinnovo: $nextRenewalStr',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    autoRenewalActive
                                        ? Icons.autorenew
                                        : Icons.pause_circle_outline,
                                    size: 11,
                                    color: autoRenewalActive
                                        ? AppColors.success
                                        : AppColors.darkTextSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    autoRenewalActive
                                        ? 'Rinnovo automatico attivo'
                                        : 'Rinnovo manuale',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 11,
                                          color: autoRenewalActive
                                              ? AppColors.success
                                              : AppColors.darkTextSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatCurrency(sub.cost),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.expenseColor,
                                    ),
                                  ),
                                  const Text(
                                    '/mese',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (v) {
                                  if (v == 'edit') _openEdit(context, sub);
                                  if (v == 'delete') _delete(context, sub);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Modifica')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Elimina')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ]),
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

class _LogoImage extends StatelessWidget {
  const _LogoImage({required this.logo});
  final String logo;

  @override
  Widget build(BuildContext context) {
    if (logo.startsWith('data:')) {
      try {
        final bytes = base64Decode(logo.split(',').last);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return Image.network(logo,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
  }
}

class _SubscriptionDetailSheet extends StatelessWidget {
  final AppSubscription subscription;
  final AppCategory? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubscriptionDetailSheet({
    required this.subscription,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = categoryColor(subscription.categoryId);
    final now = DateTime.now();
    final nextRenewal = now.day < subscription.expiryDay
        ? DateTime(now.year, now.month, subscription.expiryDay)
        : DateTime(now.year, now.month + 1, subscription.expiryDay);
    final autoRenewalActive = subscription.categoryId != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgContainer : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: subscription.logo != null
                          ? (isDark
                              ? AppColors.darkBgCard
                              : AppColors.lightBgDashboard)
                          : catColor.withValues(alpha: 0.15),
                    ),
                    child: subscription.logo != null
                        ? _LogoImage(logo: subscription.logo!)
                        : Center(
                            child: CategoryIcon(
                              icon: category?.icon ?? '🔄',
                              size: 26,
                              color: catColor,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category?.name ?? 'Nessuna categoria',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(
                label: 'Costo mensile',
                value: formatCurrency(subscription.cost),
              ),
              _DetailRow(
                label: 'Giorno di rinnovo',
                value: 'Ogni ${subscription.expiryDay} del mese',
              ),
              _DetailRow(
                label: 'Prossimo rinnovo',
                value: DateFormat('d MMM yyyy', 'it_IT').format(nextRenewal),
              ),
              _DetailRow(
                label: 'Rinnovo automatico',
                value: autoRenewalActive ? 'Attivo' : 'Manuale',
                valueColor: autoRenewalActive ? AppColors.success : null,
              ),
              if (subscription.lastRenewal != null)
                _DetailRow(
                  label: 'Ultimo rinnovo',
                  value: DateFormat('d MMM yyyy', 'it_IT')
                      .format(subscription.lastRenewal!),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifica'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mainBlue,
                        side: const BorderSide(color: AppColors.mainBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Elimina'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
