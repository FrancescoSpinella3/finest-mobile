import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/widgets/app_toast.dart';

const List<String> _icons = [
  '💼', '🎁', '🛒', '💡', '🚗', '🎮', '🏠', '🏥', '🏦', '🍕',
  '✈️', '📚', '💊', '🏋️', '🎵', '🐾', '🌱', '📱', '💳', '🎯',
  '🏖️', '🍺', '☕', '🎓', '🏢', '💰', '🔧', '🎪', '🛍️', '🚀',
];

class CategoryModal extends StatefulWidget {
  final AppCategory? category;
  const CategoryModal({super.key, this.category});

  @override
  State<CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends State<CategoryModal> {
  final _nameCtrl = TextEditingController();
  String _type = 'expense';
  String _icon = '💰';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _type = widget.category!.type;
      _icon = widget.category!.icon;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showAppToast(context, 'Inserisci il nome della categoria',
          type: ToastType.error);
      return;
    }
    setState(() => _loading = true);
    final data = context.read<DataProvider>();
    try {
      if (widget.category == null) {
        await data.addCategory(name: name, type: _type, icon: _icon);
        if (mounted) showAppToast(context, 'Categoria aggiunta');
      } else {
        await data.updateCategory(widget.category!.id, name, _type, _icon);
        if (mounted) showAppToast(context, 'Categoria aggiornata');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Errore durante il salvataggio', type: ToastType.error);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgContainer : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category == null ? 'Nuova categoria' : 'Modifica categoria',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon picker
                      Text('Icona', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBgInput : AppColors.lightBgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: _icons.length,
                          itemBuilder: (ctx, i) {
                            final icon = _icons[i];
                            final selected = icon == _icon;
                            return GestureDetector(
                              onTap: () => setState(() => _icon = icon),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.mainBlue.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected ? AppColors.mainBlue : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome categoria'),
                      ),
                      const SizedBox(height: 14),

                      // Type
                      Text('Tipo', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _TypeButton(
                            label: 'Entrata',
                            value: 'income',
                            color: AppColors.incomeColor,
                            selected: _type == 'income',
                            onTap: () => setState(() => _type = 'income'),
                          ),
                          const SizedBox(width: 8),
                          _TypeButton(
                            label: 'Uscita',
                            value: 'expense',
                            color: AppColors.expenseColor,
                            selected: _type == 'expense',
                            onTap: () => setState(() => _type = 'expense'),
                          ),
                          const SizedBox(width: 8),
                          _TypeButton(
                            label: 'Risparmio',
                            value: 'saving',
                            color: AppColors.savingColor,
                            selected: _type == 'saving',
                            onTap: () => setState(() => _type = 'saving'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(widget.category == null ? 'Aggiungi' : 'Salva'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label, required this.value,
    required this.color, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? color : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
