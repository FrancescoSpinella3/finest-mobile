import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/category_icon.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<AppTransaction> transactions;
  final List<AppCategory> categories;

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    required this.categories,
  });

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

    final recent = transactions.take(5).toList();
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
            'Nessuna transazione',
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
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: borderColor,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (ctx, i) {
          final t = recent[i];
          final cat = _cat(t.categoryId);
          Color amountColor;
          if (t.type == 'income') {
            amountColor = AppColors.incomeColor;
          } else if (t.type == 'expense')
            amountColor = AppColors.expenseColor;
          else
            amountColor = AppColors.savingColor;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgCard : AppColors.lightBgDashboard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CategoryIcon(
                  icon: cat?.icon ?? '💰',
                  size: 20,
                  color: amountColor,
                ),
              ),
            ),
            title: Text(
              t.description,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat('d MMM yyyy', 'it_IT').format(t.date),
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
            trailing: Text(
              '${t.type == 'expense' ? '-' : '+'}${formatCurrency(t.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: amountColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
