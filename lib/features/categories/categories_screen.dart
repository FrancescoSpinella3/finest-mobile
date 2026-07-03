import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'category_modal.dart';

const _tabLabels = ['Entrate', 'Uscite', 'Risparmi'];
const _tabTypes = ['income', 'expense', 'saving'];

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryModal(),
    );
  }

  void _showInfo() {
    showInfoDialog(
      context,
      title: 'Categorie',
      message:
          'Qui puoi gestire le categorie di entrate, uscite e risparmi usando le schede in alto. Tocca il pulsante "+" per crearne una nuova, oppure tocca una categoria per vedere i dettagli e modificarla o eliminarla.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const SideDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Categorie',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showInfo,
              ),
              MenuAvatarButton(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              const SizedBox(width: 16),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgCard
                          : AppColors.lightBgInput,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: const Color.fromARGB(45, 236, 236, 236))),
                  child: AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (context, _) {
                      return Row(
                        children: List.generate(_tabLabels.length, (i) {
                          final selected = _tabCtrl.index == i;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() {
                                _tabCtrl.animateTo(i);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.mainBlue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _tabLabels[i],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children:
              _tabTypes.map((type) => _CategoryTypeView(type: type)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.mainBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryTypeView extends StatelessWidget {
  final String type;

  const _CategoryTypeView({required this.type});

  String get _typeLabel {
    if (type == 'income') return 'entrate';
    if (type == 'expense') return 'uscite';
    return 'risparmi';
  }

  Color get _typeColor {
    if (type == 'income') return AppColors.incomeColor;
    if (type == 'expense') return AppColors.expenseColor;
    return AppColors.savingColor;
  }

  void _openEdit(BuildContext context, AppCategory cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryModal(category: cat),
    );
  }

  Future<void> _delete(BuildContext context, AppCategory cat) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Elimina categoria',
      message:
          'Le transazioni e gli obiettivi collegati resteranno ma mostreranno "categoria eliminata".',
    );
    if (ok == true && context.mounted) {
      await context.read<DataProvider>().deleteCategory(cat.id);
      if (context.mounted) showAppToast(context, 'Categoria eliminata');
    }
  }

  void _showDetails(
    BuildContext context,
    AppCategory cat,
    double total,
    double pct,
    int count,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryDetailSheet(
        category: cat,
        total: total,
        percentage: pct,
        transactionCount: count,
        color: color,
        onEdit: () {
          Navigator.pop(context);
          _openEdit(context, cat);
        },
        onDelete: () {
          Navigator.pop(context);
          _delete(context, cat);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final categories = data.categories.where((c) => c.type == type).toList();

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📂', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Nessuna categoria in questo gruppo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);

    double totalFor(DateTime month, {String? categoryId}) {
      return data.transactions
          .where((t) =>
              t.type == type &&
              t.date.year == month.year &&
              t.date.month == month.month &&
              (categoryId == null || t.categoryId == categoryId))
          .fold<double>(0, (s, t) => s + t.amount);
    }

    int countFor(String categoryId) {
      return data.transactions
          .where((t) =>
              t.type == type &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.categoryId == categoryId)
          .length;
    }

    final monthTotal = totalFor(now);
    final prevMonthTotal = totalFor(prevMonth);
    final hasTrend = prevMonthTotal > 0;
    final trendPct =
        hasTrend ? ((monthTotal - prevMonthTotal) / prevMonthTotal * 100) : 0.0;

    final sorted = categories.toList()
      ..sort((a, b) => totalFor(now, categoryId: b.id)
          .compareTo(totalFor(now, categoryId: a.id)));

    final monthLabel = _capitalize(DateFormat('MMMM', 'it_IT').format(now));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgCard : AppColors.lightBgContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Totale $_typeLabel · $monthLabel',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        _SplitAmount(amount: monthTotal),
                      ],
                    ),
                  ),
                  if (hasTrend)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (trendPct >= 0
                                ? AppColors.success
                                : AppColors.danger)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendPct >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: trendPct >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trendPct >= 0 ? '+' : ''}${trendPct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: trendPct >= 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (monthTotal > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        for (var i = 0; i < sorted.length; i++)
                          if (totalFor(now, categoryId: sorted[i].id) > 0)
                            Expanded(
                              flex: (totalFor(now, categoryId: sorted[i].id) *
                                      1000 ~/
                                      monthTotal)
                                  .clamp(1, 1000),
                              child: Container(
                                color: categoryColor(sorted[i].id),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < sorted.length; i++)
                      if (totalFor(now, categoryId: sorted[i].id) > 0)
                        _LegendItem(
                          color: categoryColor(sorted[i].id),
                          label: sorted[i].name,
                          pct: totalFor(now, categoryId: sorted[i].id) /
                              monthTotal *
                              100,
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Section header ───────────────────────────────────────────
        Text(
          '${categories.length} ${categories.length == 1 ? 'CATEGORIA' : 'CATEGORIE'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 10),

        // ── Category cards ───────────────────────────────────────────
        for (var i = 0; i < sorted.length; i++) ...[
          Builder(builder: (context) {
            final cat = sorted[i];
            final total = totalFor(now, categoryId: cat.id);
            final pct = monthTotal > 0 ? total / monthTotal * 100 : 0.0;
            final count = countFor(cat.id);
            final color = categoryColor(sorted[i].id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      _showDetails(context, cat, total, pct, count, color),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CategoryIcon(
                              icon: cat.icon,
                              size: 22,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                count == 1
                                    ? '1 transazione'
                                    : '$count transazioni',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency(total),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _typeColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SplitAmount extends StatelessWidget {
  final double amount;

  const _SplitAmount({required this.amount});

  @override
  Widget build(BuildContext context) {
    final formatted = formatCurrency(amount);
    final parts = formatted.split(',');
    final main = parts.first;
    final decimals = parts.length > 1 ? ',${parts[1]}' : '';
    final color = Theme.of(context).textTheme.bodyLarge?.color;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: main,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 30,
              color: color,
            ),
          ),
          TextSpan(
            text: decimals,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ${pct.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CategoryDetailSheet extends StatelessWidget {
  final AppCategory category;
  final double total;
  final double percentage;
  final int transactionCount;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryDetailSheet({
    required this.category,
    required this.total,
    required this.percentage,
    required this.transactionCount,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: CategoryIcon(
                        icon: category.icon,
                        size: 26,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(
                  label: 'Totale questo mese', value: formatCurrency(total)),
              _DetailRow(
                  label: 'Percentuale sul totale',
                  value: '${percentage.toStringAsFixed(0)}%'),
              _DetailRow(
                label: 'Transazioni questo mese',
                value: '$transactionCount',
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

  const _DetailRow({required this.label, required this.value});

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
