import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/category_icon.dart';
import 'category_modal.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
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

  void _openEdit(AppCategory cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryModal(category: cat),
    );
  }

  Future<void> _delete(AppCategory cat) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Elimina categoria',
      message:
          'Le transazioni e gli obiettivi collegati resteranno ma mostreranno "categoria eliminata".',
    );
    if (ok == true && mounted) {
      await context.read<DataProvider>().deleteCategory(cat.id);
      if (mounted) showAppToast(context, 'Categoria eliminata');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final income = data.categories.where((c) => c.type == 'income').toList();
    final expense = data.categories.where((c) => c.type == 'expense').toList();
    final saving = data.categories.where((c) => c.type == 'saving').toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            pinned: true,
            title: const Text('Categorie'),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.mainBlue,
              labelColor: AppColors.mainBlue,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Entrate'),
                Tab(text: 'Uscite'),
                Tab(text: 'Risparmi'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _CategoryList(
              categories: income,
              type: 'income',
              onEdit: _openEdit,
              onDelete: _delete,
            ),
            _CategoryList(
              categories: expense,
              type: 'expense',
              onEdit: _openEdit,
              onDelete: _delete,
            ),
            _CategoryList(
              categories: saving,
              type: 'saving',
              onEdit: _openEdit,
              onDelete: _delete,
            ),
          ],
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

class _CategoryList extends StatelessWidget {
  final List<AppCategory> categories;
  final String type;
  final void Function(AppCategory) onEdit;
  final void Function(AppCategory) onDelete;

  const _CategoryList({
    required this.categories,
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _typeColor {
    if (type == 'income') return AppColors.incomeColor;
    if (type == 'expense') return AppColors.expenseColor;
    return AppColors.savingColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor = _typeColor;

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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CategoryIcon(
                  icon: cat.icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
            ),
            title:
                Text(cat.name, style: Theme.of(context).textTheme.titleSmall),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.mainBlue,
                  onPressed: () => onEdit(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.danger,
                  onPressed: () => onDelete(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
