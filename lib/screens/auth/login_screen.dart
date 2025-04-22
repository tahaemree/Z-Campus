import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/services/firebase/auth_service.dart';
import 'package:campus_online/screens/auth/signup_screen.dart';
import 'package:campus_online/screens/main_screen.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isResettingPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta adresinizi giriniz.';
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir e-posta adresi giriniz.';
      });
      return;
    }

    setState(() {
      _isResettingPassword = true;
      _errorMessage = '';
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Şifre sıfırlama işlemi başarısız oldu. Lütfen tekrar deneyiniz.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Kullanıcı giriş yaptıysa ana ekrana yönlendir
      if (authService.currentUser != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (e.toString().contains('E-posta adresi bulunamadı')) {
          _errorMessage = 'E-posta adresi kayıtlı değil';
        } else if (e.toString().contains('Şifre yanlış')) {
          _errorMessage = 'E-posta veya şifre hatalı';
        } else if (e
            .toString()
            .contains('Çok fazla başarısız giriş denemesi')) {
          _errorMessage =
              'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
        } else if (e.toString().contains('Geçersiz e-posta formatı')) {
          _errorMessage = 'Geçerli bir e-posta adresi giriniz';
        } else {
          _errorMessage = 'Bir hata oluştu, lütfen tekrar deneyin';
          debugPrint('Login Error: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Üst başlık ve logo satırı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Campus\nOnline',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                  ),
                  Image.network(
                    'https://www.izu.edu.tr/images/default-source/amblem/arma_1.png?sfvrsn=51f8da3c_2',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Giriş Yap',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
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
                      keyboardType: TextInputType.emailAddress,
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
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
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi giriniz.';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isResettingPassword ? null : _resetPassword,
                        child: _isResettingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Şifremi Unuttum'),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
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
                                  const Icon(Icons.login_rounded),
                                  const SizedBox(width: 10),
                                  const Text('Giriş Yap',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('Hesabınız yok mu? Kayıt olun'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
