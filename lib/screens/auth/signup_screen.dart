import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/services/firebase/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        // Daha kullanıcı dostu hata mesajları
        if (e.toString().contains('E-posta adresi zaten kullanımda')) {
          _errorMessage = 'Bu e-posta adresi zaten kullanımda.';
        } else if (e.toString().contains('Geçersiz e-posta formatı')) {
          _errorMessage = 'Lütfen geçerli bir e-posta adresi giriniz.';
        } else if (e.toString().contains('Şifre çok zayıf')) {
          _errorMessage = 'Lütfen daha güçlü bir şifre seçiniz.';
        } else {
          _errorMessage =
              'Kayıt olurken bir hata oluştu. Lütfen tekrar deneyiniz.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Hesap Oluştur'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Campus Online',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen adınızı ve soyadınızı giriniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta adresinizi giriniz.';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Lütfen geçerli bir e-posta adresi giriniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi giriniz.';
                    }
                    if (value.length < 8) {
                      return 'Şifre en az 8 karakter olmalıdır.';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Şifre en az bir büyük harf içermelidir.';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Şifre en az bir küçük harf içermelidir.';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Şifre en az bir rakam içermelidir.';
                    }
                    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return 'Şifre en az bir özel karakter içermelidir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi tekrar giriniz.';
                    }
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.center,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add_alt_1_rounded),
                              const SizedBox(width: 10),
                              const Text('Hesap Oluştur',
                                  style: TextStyle(fontSize: 18)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Zaten hesabınız var mı? Giriş yapın'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
