import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/category_icon.dart';

class GoalModal extends StatefulWidget {
  final AppGoal? goal;
  const GoalModal({super.key, this.goal});

  @override
  State<GoalModal> createState() => _GoalModalState();
}

class _GoalModalState extends State<GoalModal> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _type = 'saving';
  String? _categoryId;
  String? _period;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameCtrl.text = widget.goal!.name;
      _targetCtrl.text = widget.goal!.targetAmount.toString();
      _type = widget.goal!.type;
      _categoryId = widget.goal!.categoryId;
      _period = widget.goal!.period;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final targetText = _targetCtrl.text.trim().replaceAll(',', '.');
    if (name.isEmpty || targetText.isEmpty) {
      showAppToast(context, 'Compila tutti i campi', type: ToastType.error);
      return;
    }
    final target = double.tryParse(targetText);
    if (target == null || target <= 0) {
      showAppToast(context, 'Importo non valido', type: ToastType.error);
      return;
    }
    setState(() => _loading = true);
    final data = context.read<DataProvider>();
    try {
      if (widget.goal == null) {
        await data.addGoal(
          name: name,
          type: _type,
          targetAmount: target,
          categoryId: _categoryId,
          period: _period,
        );
        if (mounted) showAppToast(context, 'Obiettivo creato');
      } else {
        await data.updateGoal(
          widget.goal!.id,
          name: name,
          type: _type,
          targetAmount: target,
          categoryId: _categoryId,
          period: _period,
        );
        if (mounted) showAppToast(context, 'Obiettivo aggiornato');
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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                      widget.goal == null
                          ? 'Nuovo obiettivo'
                          : 'Modifica obiettivo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
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
                      TextField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Nome obiettivo'),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration:
                            const InputDecoration(labelText: 'Tipo obiettivo'),
                        dropdownColor:
                            isDark ? AppColors.darkBgContainer : Colors.white,
                        items: const [
                          DropdownMenuItem(
                              value: 'income',
                              child: Text('Obiettivo entrate')),
                          DropdownMenuItem(
                              value: 'expense_limit',
                              child: Text('Limite uscite')),
                          DropdownMenuItem(
                              value: 'saving',
                              child: Text('Obiettivo risparmio')),
                        ],
                        onChanged: (v) => setState(() => _type = v ?? 'saving'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _targetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Importo target (€)',
                          prefixText: '€ ',
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                            labelText: 'Categoria (opzionale)'),
                        dropdownColor:
                            isDark ? AppColors.darkBgContainer : Colors.white,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Nessuna categoria')),
                          ...data.categories.map((c) => DropdownMenuItem(
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
                      DropdownButtonFormField<String>(
                        initialValue: _period,
                        decoration: const InputDecoration(labelText: 'Periodo'),
                        dropdownColor:
                            isDark ? AppColors.darkBgContainer : Colors.white,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Totale')),
                          DropdownMenuItem(
                              value: 'mensile', child: Text('Mensile')),
                        ],
                        onChanged: (v) => setState(() => _period = v),
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
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(widget.goal == null
                                  ? 'Crea obiettivo'
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

// ── Contribute Modal ──────────────────────────────────────────────────────────

class ContributeModal extends StatefulWidget {
  final AppGoal goal;
  const ContributeModal({super.key, required this.goal});

  @override
  State<ContributeModal> createState() => _ContributeModalState();
}

class _ContributeModalState extends State<ContributeModal> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _contribute() async {
    final amountText = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showAppToast(context, 'Inserisci un importo valido',
          type: ToastType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await context
          .read<DataProvider>()
          .contributeToGoal(widget.goal.id, amount);
      if (mounted) {
        showAppToast(context, 'Contributo aggiunto');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Errore', type: ToastType.error);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgContainer : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aggiungi contributo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            widget.goal.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Importo (€)',
              prefixText: '€ ',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _contribute,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Aggiungi'),
            ),
          ),
        ],
      ),
    );
  }
}
