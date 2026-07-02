import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/category_icon.dart';

class TransactionModal extends StatefulWidget {
  final AppTransaction? transaction;

  const TransactionModal({super.key, this.transaction});

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'expense';
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descController.text = t.description;
      _amountController.text = t.amount.toString();
      _type = t.type;
      _categoryId = t.categoryId;
      _date = t.date;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final desc = _descController.text.trim();
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    if (desc.isEmpty || amountText.isEmpty) {
      showAppToast(context, 'Compila tutti i campi obbligatori',
          type: ToastType.error);
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showAppToast(context, 'Inserisci un importo valido',
          type: ToastType.error);
      return;
    }

    setState(() => _loading = true);
    final data = context.read<DataProvider>();
    try {
      if (widget.transaction == null) {
        await data.addTransaction(
          type: _type,
          description: desc,
          amount: amount,
          categoryId: _categoryId,
          date: _date,
        );
        if (mounted) showAppToast(context, 'Transazione aggiunta');
      } else {
        await data.updateTransaction(
          widget.transaction!.id,
          type: _type,
          description: desc,
          amount: amount,
          categoryId: _categoryId,
          date: _date,
        );
        if (mounted) showAppToast(context, 'Transazione aggiornata');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Errore durante il salvataggio',
            type: ToastType.error);
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catsByType = data.categories.where((c) => c.type == _type).toList();

    // Reset categoryId if it doesn't match current type
    if (_categoryId != null && !catsByType.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }

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
                width: 40,
                height: 4,
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
                      widget.transaction == null
                          ? 'Nuova transazione'
                          : 'Modifica transazione',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Type selector
                      Text('Tipo',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _TypeSelector(
                        value: _type,
                        onChanged: (v) => setState(() {
                          _type = v;
                          _categoryId = null;
                        }),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Descrizione',
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Importo (€)',
                          prefixText: '€ ',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        dropdownColor: isDark
                            ? AppColors.darkBgContainer
                            : AppColors.lightBgContainer,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Nessuna categoria')),
                          ...catsByType.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(children: [
                                  CategoryIcon(icon: c.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ]),
                              )),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 14),

                      // Date picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Data',
                              suffixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18),
                              hintText:
                                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                            ),
                            controller: TextEditingController(
                              text:
                                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(widget.transaction == null
                                  ? 'Aggiungi'
                                  : 'Salva'),
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

class _TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          label: 'Entrata',
          icon: Icons.trending_up_rounded,
          color: AppColors.incomeColor,
          selected: value == 'income',
          onTap: () => onChanged('income'),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: 'Uscita',
          icon: Icons.trending_down_rounded,
          color: AppColors.expenseColor,
          selected: value == 'expense',
          onTap: () => onChanged('expense'),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: 'Risparmio',
          icon: Icons.savings_outlined,
          color: AppColors.savingColor,
          selected: value == 'saving',
          onTap: () => onChanged('saving'),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.lightTextSecondary,
                  size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
