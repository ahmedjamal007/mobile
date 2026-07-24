import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../state/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  String _gender = 'M';
  bool _obscure = true;

  // Backend field errors mapped onto inputs.
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final c in [
      _username,
      _email,
      _password,
      _firstName,
      _lastName,
      _phone,
      _nationalId
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    try {
      await auth.register({
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone_number': _phone.text.trim(),
        'national_id': _nationalId.text.trim(),
        'gender': _gender,
      });
      if (mounted) {
        Toast.success(context, 'Welcome aboard! Your account is ready.');
      }
    } on ApiException catch (e) {
      setState(() => _fieldErrors = e.fieldErrors);
      if (mounted) Toast.error(context, e.message);
      _formKey.currentState!.validate();
    } catch (_) {
      if (mounted) Toast.error(context, 'Registration failed. Try again.');
    }
  }

  String? _serverError(String field) => _fieldErrors[field];

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _username,
                  label: 'Username',
                  icon: Icons.alternate_email,
                  serverKey: 'username',
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Username is required' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _firstName,
                        label: 'First name',
                        icon: Icons.badge_outlined,
                        serverKey: 'first_name',
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _lastName,
                        label: 'Last name',
                        serverKey: 'last_name',
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                _field(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  serverKey: 'email',
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                _field(
                  controller: _phone,
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  serverKey: 'phone_number',
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Phone number is required' : null,
                ),
                _field(
                  controller: _nationalId,
                  label: 'National ID',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  serverKey: 'national_id',
                  validator: (v) =>
                      v!.trim().isEmpty ? 'National ID is required' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Male')),
                    DropdownMenuItem(value: 'F', child: Text('Female')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? 'M'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _serverError('password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Use at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can add a profile photo and national ID photo later '
                  'from your profile.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('I already have an account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? serverKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          errorText: serverKey != null ? _serverError(serverKey) : null,
        ),
        validator: validator,
      ),
    );
  }
}
