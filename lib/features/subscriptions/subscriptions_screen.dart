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
import 'subscription_modal.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionModal(),
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
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text('Abbonamenti'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Total monthly cost card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
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
                                        color: AppColors.expenseColor,
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
