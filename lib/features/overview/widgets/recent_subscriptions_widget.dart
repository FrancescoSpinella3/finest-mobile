import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/category_icon.dart';

class RecentSubscriptionsWidget extends StatelessWidget {
  final List<AppSubscription> subscriptions;
  final List<AppCategory> categories;

  const RecentSubscriptionsWidget({
    super.key,
    required this.subscriptions,
    required this.categories,
  });

  Widget _buildLogo(String logo) {
    if (logo.startsWith('data:')) {
      try {
        return Image.memory(base64Decode(logo.split(',').last),
            fit: BoxFit.contain);
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return Image.network(logo,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
  }

  AppCategory? _cat(String? id) {
    if (id == null) return null;
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final recent = subscriptions.take(4).toList();
    if (recent.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Nessun abbonamento',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
        itemBuilder: (ctx, i) {
          final sub = recent[i];
          final cat = _cat(sub.categoryId);
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: sub.logo != null
                    ? Colors.transparent
                    : AppColors.darkBgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: sub.logo != null
                    ? _buildLogo(sub.logo!)
                    : Center(
                        child: CategoryIcon(
                          icon: cat?.icon ?? '🔄',
                          size: 20,
                          color: AppColors.mainBlue,
                        ),
                      ),
              ),
            ),
            title: Text(
              sub.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(
              'Rinnovo il giorno ${sub.expiryDay}',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
            trailing: Text(
              '${formatCurrency(sub.cost)}/mese',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.expenseColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
