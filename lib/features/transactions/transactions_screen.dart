import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
import 'transaction_modal.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _typeFilter = 'Tutti';
  String _periodFilter = 'Tutti';
  String? _categoryFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppTransaction> _filtered(DataProvider data) {
    var list = data.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_search.isNotEmpty) {
      list = list
          .where((t) =>
              t.description.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    if (_typeFilter != 'Tutti') {
      final typeMap = {
        'Entrate': 'income',
        'Uscite': 'expense',
        'Risparmi': 'saving',
      };
      list = list.where((t) => t.type == typeMap[_typeFilter]).toList();
    }
    if (_categoryFilter != null) {
      list = list.where((t) => t.categoryId == _categoryFilter).toList();
    }
    if (_periodFilter != 'Tutti') {
      final now = DateTime.now();
      DateTime from;
      switch (_periodFilter) {
        case 'Ultima settimana':
          from = now.subtract(const Duration(days: 7));
          break;
        case 'Ultimi 30 giorni':
          from = now.subtract(const Duration(days: 30));
          break;
        case 'Ultimi 6 mesi':
          from = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'Ultimo anno':
          from = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          from = DateTime(2000);
      }
      list = list.where((t) => t.date.isAfter(from)).toList();
    }
    return list;
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TransactionModal(),
    );
  }

  void _showInfo() {
    showInfoDialog(
      context,
      title: 'Transazioni',
      message:
          'Qui puoi consultare tutte le tue transazioni. Usa la barra di ricerca e i filtri per periodo, tipo o categoria per trovare quelle che ti interessano. Tocca il pulsante "+" per aggiungerne una nuova, oppure usa il menu (⋮) su una voce per modificarla o eliminarla.',
    );
  }

  void _openEdit(AppTransaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionModal(transaction: t),
    );
  }

  Future<void> _delete(AppTransaction t) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Elimina transazione',
      message: 'Questa azione non può essere annullata.',
    );
    if (ok == true && mounted) {
      await context.read<DataProvider>().deleteTransaction(t.id);
      if (mounted) showAppToast(context, 'Transazione eliminata');
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
    final filtered = _filtered(data);

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpenses = filtered
        .where((t) => t.type == 'expense')
        .fold<double>(0, (s, t) => s + t.amount);
    final totalSavings = filtered
        .where((t) => t.type == 'saving')
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const SideDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Transazioni',
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Cerca transazione...',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipDropdown(
                        label: 'Periodo',
                        value: _periodFilter,
                        items: const [
                          'Tutti',
                          'Ultima settimana',
                          'Ultimi 30 giorni',
                          'Ultimi 6 mesi',
                          'Ultimo anno'
                        ],
                        onChanged: (v) => setState(() => _periodFilter = v),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipDropdown(
                        label: 'Tipo',
                        value: _typeFilter,
                        items: const ['Tutti', 'Entrate', 'Uscite', 'Risparmi'],
                        onChanged: (v) => setState(() => _typeFilter = v),
                      ),
                      const SizedBox(width: 8),
                      _CategoryFilterChip(
                        categories: data.categories,
                        value: _categoryFilter,
                        onChanged: (v) => setState(() => _categoryFilter = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Summary cards
                Row(
                  children: [
                    _SummaryCard(
                      label: 'Entrate',
                      value: totalIncome,
                      color: AppColors.incomeColor,
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Uscite',
                      value: totalExpenses,
                      color: AppColors.expenseColor,
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'Risparmi',
                      value: totalSavings,
                      color: AppColors.savingColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Transaction list
                if (filtered.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nessuna transazione trovata',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: borderColor,
                          indent: 16,
                          endIndent: 16),
                      itemBuilder: (ctx, i) {
                        final t = filtered[i];
                        final cat = data.getCategoryById(t.categoryId);
                        final catColor = categoryColor(t.categoryId);
                        Color color;
                        if (t.type == 'income') {
                          color = AppColors.incomeColor;
                        } else if (t.type == 'expense')
                          color = AppColors.expenseColor;
                        else
                          color = AppColors.savingColor;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: CategoryIcon(
                                icon: cat?.icon ?? '💰',
                                size: 20,
                                color: catColor,
                              ),
                            ),
                          ),
                          title: Text(
                            t.description,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${cat?.name ?? 'Nessuna categoria'} • ${DateFormat('d MMM yyyy', 'it_IT').format(t.date)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${t.type == 'expense' ? '-' : '+'}${formatCurrency(t.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (v) {
                                  if (v == 'edit') _openEdit(t);
                                  if (v == 'delete') _delete(t);
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
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrencyCompact(value),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterChipDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = value != 'Tutti';
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          builder: (_) =>
              _SimplePickerSheet(title: label, items: items, value: value),
        );
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.mainBlue.withValues(alpha: 0.1)
              : (isDark ? AppColors.darkBgInput : AppColors.lightBgInput),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive
                  ? AppColors.mainBlue
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == 'Tutti' ? label : value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.mainBlue : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: isActive ? AppColors.mainBlue : null),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final List<AppCategory> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CategoryFilterChip({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = value != null;
    final selectedName = isActive
        ? categories
            .firstWhere((c) => c.id == value,
                orElse: () => const AppCategory(
                    id: '', name: 'Categoria', type: '', icon: ''))
            .name
        : 'Categoria';

    return GestureDetector(
      onTap: () async {
        final items = ['Tutte', ...categories.map((c) => c.name)];
        final selected = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _SimplePickerSheet(
              title: 'Categoria', items: items, value: selectedName),
        );
        if (selected == null) return;
        if (selected == 'Tutte') {
          onChanged(null);
        } else {
          final cat = categories.firstWhere((c) => c.name == selected,
              orElse: () => categories.first);
          onChanged(cat.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.mainBlue.withValues(alpha: 0.1)
              : (isDark ? AppColors.darkBgInput : AppColors.lightBgInput),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive
                  ? AppColors.mainBlue
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.mainBlue : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: isActive ? AppColors.mainBlue : null),
          ],
        ),
      ),
    );
  }
}

class _SimplePickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String value;

  const _SimplePickerSheet(
      {required this.title, required this.items, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgContainer : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: items
                  .map((item) => ListTile(
                        title: Text(item),
                        trailing: item == value
                            ? const Icon(Icons.check, color: AppColors.mainBlue)
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
