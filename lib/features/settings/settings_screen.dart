import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loadingPassword = false;
  bool _loadingAvatar = false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        showAppToast(context, 'Immagine troppo grande (max 2MB)',
            type: ToastType.error);
      }
      return;
    }

    setState(() => _loadingAvatar = true);
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.uploadAvatar(bytes.toList(), xFile.name);
    if (mounted) {
      setState(() => _loadingAvatar = false);
      if (error != null) {
        showAppToast(context, error, type: ToastType.error);
      } else {
        showAppToast(context, 'Immagine profilo aggiornata');
      }
    }
  }

  Future<void> _changePassword() async {
    final pw = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;
    if (pw.length < 6) {
      showAppToast(context, 'La password deve essere di almeno 6 caratteri',
          type: ToastType.error);
      return;
    }
    if (pw != confirm) {
      showAppToast(context, 'Le password non coincidono',
          type: ToastType.error);
      return;
    }
    setState(() => _loadingPassword = true);
    final error = await context.read<AuthProvider>().updatePassword(pw);
    if (mounted) {
      setState(() => _loadingPassword = false);
      if (error != null) {
        showAppToast(context, error, type: ToastType.error);
      } else {
        showAppToast(context, 'Password aggiornata con successo');
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Elimina account',
      message:
          'Questa azione è irreversibile. Tutti i tuoi dati (transazioni, categorie, obiettivi, abbonamenti) saranno eliminati definitivamente.',
      confirmLabel: 'Elimina account',
    );
    if (ok == true && mounted) {
      final error = await context.read<AuthProvider>().deleteAccount();
      if (mounted && error != null) {
        showAppToast(context, error, type: ToastType.error);
      } else {
        context.read<DataProvider>().clear();
      }
    }
  }

  Future<void> _signOut() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Esci',
      message: 'Sei sicuro di voler uscire?',
      confirmLabel: 'Esci',
      isDangerous: false,
    );
    if (ok == true && mounted) {
      context.read<DataProvider>().clear();
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = auth.profile;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final avatarUrl = profile?['profileImage']?.toString();
    final name = profile?['name']?.toString() ?? '';
    final lastName = profile?['lastName']?.toString() ?? '';
    final fullName = '$name $lastName'.trim();
    final email = auth.user?.email ?? '';
    final initials = name.isNotEmpty
        ? (name[0] + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase()
        : 'U';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text('Impostazioni'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Profile Card ────────────────────────────────────────────
                _Card(
                  borderColor: borderColor,
                  cardColor: cardColor,
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _loadingAvatar
                              ? const CircularProgressIndicator()
                              : GestureDetector(
                                  onTap: _pickAvatar,
                                  child: CircleAvatar(
                                    radius: 44,
                                    backgroundColor: AppColors.mainBlue
                                        .withValues(alpha: 0.15),
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Text(
                                            initials,
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 24,
                                              color: AppColors.mainBlue,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.mainBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName.isNotEmpty ? fullName : 'Utente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (profile?['birthdate'] != null ||
                          profile?['gender'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (profile?['gender'] != null)
                              profile!['gender'].toString(),
                            if (profile?['birthdate'] != null)
                              DateFormat("dd MMMM yyyy", 'it').format(
                                DateTime.tryParse(profile!['birthdate'].toString()) ??
                                    DateTime.now(),
                              ),
                          ].join(' • '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Appearance ──────────────────────────────────────────────
                _Card(
                  borderColor: borderColor,
                  cardColor: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aspetto',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color: AppColors.mainBlue,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isDark ? 'Modalità scura' : 'Modalità chiara',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Switch(
                            value: isDark,
                            onChanged: (_) => theme.toggleTheme(),
                            activeThumbColor: AppColors.mainBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Change Password ──────────────────────────────────────────
                _Card(
                  borderColor: borderColor,
                  cardColor: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sicurezza',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _newPasswordCtrl,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nuova password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Conferma password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _loadingPassword ? null : _changePassword,
                          child: _loadingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Aggiorna password'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Sign out ─────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Esci dall\'account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mainBlue,
                      side: const BorderSide(color: AppColors.mainBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Danger Zone ──────────────────────────────────────────────
                _Card(
                  borderColor: AppColors.danger.withValues(alpha: 0.3),
                  cardColor: AppColors.danger.withValues(alpha: 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Zona pericolosa',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'L\'eliminazione dell\'account è irreversibile. Tutti i dati verranno cancellati definitivamente.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.danger.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Elimina account'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color cardColor;

  const _Card({
    required this.child,
    required this.borderColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
