import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayit olusturulamadi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    if (!value.contains('@')) {
      return 'Gecerli bir e-posta gir';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunlu';
    }
    if (value.length < 6) {
      return 'Sifre en az 6 karakter olmali';
    }
    return null;
  }

  String? _passwordAgainValidator(String? value) {
    final passwordError = _passwordValidator(value);
    if (passwordError != null) {
      return passwordError;
    }
    if (value != _passwordController.text) {
      return 'Sifreler ayni degil';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap olustur')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Orman Pazar hesabi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppConstants.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kendi ilanlarini eklemek icin ucretsiz hesap olustur.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppConstants.mutedText),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Sifre'),
                validator: _passwordValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordAgainController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Sifre tekrar'),
                validator: _passwordAgainValidator,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _register,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(_isLoading ? 'Kayit olusturuluyor' : 'Kayit ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
