import 'dart:convert' show base64Decode, base64Encode;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/category_icon.dart';

class SubscriptionModal extends StatefulWidget {
  final AppSubscription? subscription;
  const SubscriptionModal({super.key, this.subscription});

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  String? _categoryId;
  DateTime? _lastRenewal;
  String? _logoUrl;
  List<int>? _logoBytes;
  String? _logoFileName;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      final s = widget.subscription!;
      _nameCtrl.text = s.name;
      _costCtrl.text = s.cost.toString();
      _dayCtrl.text = s.expiryDay.toString();
      _categoryId = s.categoryId;
      _lastRenewal = s.lastRenewal;
      _logoUrl = s.logo;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 256, maxHeight: 256);
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        showAppToast(context, 'Immagine troppo grande (max 2MB)',
            type: ToastType.error);
      }
      return;
    }
    setState(() {
      _logoBytes = bytes.toList();
      _logoFileName = xFile.name;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final costText = _costCtrl.text.trim().replaceAll(',', '.');
    final dayText = _dayCtrl.text.trim();
    if (name.isEmpty || costText.isEmpty || dayText.isEmpty) {
      showAppToast(context, 'Compila tutti i campi', type: ToastType.error);
      return;
    }
    final cost = double.tryParse(costText);
    final day = int.tryParse(dayText);
    if (cost == null || cost <= 0) {
      showAppToast(context, 'Importo non valido', type: ToastType.error);
      return;
    }
    if (day == null || day < 1 || day > 31) {
      showAppToast(context, 'Giorno non valido (1-31)', type: ToastType.error);
      return;
    }

    setState(() => _loading = true);
    final data = context.read<DataProvider>();
    try {
      String? logoUrl = _logoUrl;
      if (_logoBytes != null && _logoFileName != null) {
        final ext = _logoFileName!.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/webp';
        logoUrl = 'data:$mime;base64,${base64Encode(_logoBytes!)}';
      }

      if (widget.subscription == null) {
        await data.addSubscription(
          name: name,
          cost: cost,
          categoryId: _categoryId,
          expiryDay: day,
          logo: logoUrl,
          lastRenewal: _lastRenewal,
        );
        if (mounted) showAppToast(context, 'Abbonamento aggiunto');
      } else {
        await data.updateSubscription(
          widget.subscription!.id,
          name: name,
          cost: cost,
          categoryId: _categoryId,
          expiryDay: day,
          logo: logoUrl,
          lastRenewal: _lastRenewal,
        );
        if (mounted) showAppToast(context, 'Abbonamento aggiornato');
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
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final expenseCategories =
        data.categories.where((c) => c.type == 'expense').toList();

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
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.subscription == null
                          ? 'Nuovo abbonamento'
                          : 'Modifica abbonamento',
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
                      // Logo picker
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBgInput
                                    : AppColors.lightBgContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _logoBytes != null
                                    ? Image.memory(
                                        Uint8List.fromList(_logoBytes!),
                                        fit: BoxFit.cover)
                                    : _logoUrl != null
                                        ? _logoUrl!.startsWith('data:')
                                            ? Image.memory(
                                                base64Decode(
                                                    _logoUrl!.split(',').last),
                                                fit: BoxFit.cover)
                                            : Image.network(_logoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                        Icons
                                                            .add_photo_alternate_outlined,
                                                        size: 28))
                                        : const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tocca per aggiungere\nun logo (opzionale)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nome abbonamento'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Costo mensile (€)',
                          prefixText: '€ ',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _dayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giorno di rinnovo (1-31)',
                          suffixText: 'del mese',
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
                          ...expenseCategories.map((c) => DropdownMenuItem(
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
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _lastRenewal ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _lastRenewal = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ultimo rinnovo (opzionale)',
                            suffixIcon:
                                Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          child: Text(
                            _lastRenewal != null
                                ? '${_lastRenewal!.day.toString().padLeft(2, '0')}/${_lastRenewal!.month.toString().padLeft(2, '0')}/${_lastRenewal!.year}'
                                : 'Seleziona data...',
                            style: TextStyle(
                              color: _lastRenewal != null
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                  : Theme.of(context).hintColor,
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
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(widget.subscription == null
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
