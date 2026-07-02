import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import 'auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _authError;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  String? _gender;

  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _authError = null;
      _errors.clear();
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _lastNameController.clear();
      _birthdateController.clear();
      _gender = null;
    });
  }

  bool _validate() {
    final errors = <String, String?>{};
    if (_emailController.text.trim().isEmpty) {
      errors['email'] = 'Inserire un\'email';
    }
    if (_passwordController.text.isEmpty) {
      errors['password'] = 'Inserire una password';
    }
    if (!_isLogin) {
      if (_nameController.text.trim().isEmpty) {
        errors['name'] = 'Inserire il nome';
      }
      if (_lastNameController.text.trim().isEmpty) {
        errors['lastName'] = 'Inserire il cognome';
      }
      if (_birthdateController.text.trim().isEmpty) {
        errors['birthdate'] = 'Inserire la data di nascita';
      }
      if (_gender == null) errors['gender'] = 'Selezionare il genere';
    }
    setState(() => _errors.addAll(errors));
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    setState(() {
      _errors.clear();
      _authError = null;
    });
    if (!_validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    String? error;

    if (_isLogin) {
      error = await auth.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      error = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthdate: _birthdateController.text.trim(),
        gender: _gender!,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _authError = error;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      _birthdateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _errors.remove('birthdate'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgMain : AppColors.lightBgMain;
    final cardColor =
        isDark ? AppColors.darkBgContainer : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Brand
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.mainBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'F',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Finest',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.mainBlue,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestisci le tue finanze',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isLogin ? 'Accedi' : 'Crea account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      if (!_isLogin) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nome',
                          error: _errors['name'],
                          onChanged: (_) =>
                              setState(() => _errors.remove('name')),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Cognome',
                          error: _errors['lastName'],
                          onChanged: (_) =>
                              setState(() => _errors.remove('lastName')),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        error: _errors['email'],
                        onChanged: (_) =>
                            setState(() => _errors.remove('email')),
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: _obscurePassword,
                        error: _errors['password'],
                        onChanged: (_) =>
                            setState(() => _errors.remove('password')),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.mainBlue,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _birthdateController,
                              label: 'Data di nascita',
                              error: _errors['birthdate'],
                              suffix: const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppColors.mainBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(
                          label: 'Genere',
                          value: _gender,
                          items: const ['Maschio', 'Femmina', 'Altro'],
                          error: _errors['gender'],
                          onChanged: (v) => setState(() {
                            _gender = v;
                            _errors.remove('gender');
                          }),
                        ),
                      ],
                      if (_authError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _authError!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isLogin ? 'Accedi' : 'Registrati'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? 'Non hai un account? '
                                : 'Hai già un account? ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          GestureDetector(
                            onTap: _switchMode,
                            child: Text(
                              _isLogin ? 'Registrati' : 'Accedi',
                              style: const TextStyle(
                                color: AppColors.mainBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? error,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: suffix,
            errorText: error,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    String? error,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
          ),
          dropdownColor:
              isDark ? AppColors.darkBgContainer : AppColors.lightBgContainer,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
