import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:campus_online/commons/custom_keys.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/screens/auth/signup_screen.dart';
import 'package:campus_online/screens/auth/auth_services.dart';
import 'package:campus_online/screens/navi_bar.dart';
import 'package:campus_online/widgets/auth/auth_scaffold.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthServices _services = AuthServices();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      AppError.showError(context, 'Geçerli bir email adresi girin');
      return;
    }

    if (password.isEmpty) {
      AppError.showError(context, 'Şifre gerekli');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _services.signIn(email, password);
      if (!mounted) return;

      AppError.showSuccess(context, CustomKeys.succesLogin);

      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      subtitle: 'Hoş Geldiniz',
      isLoading: _isLoading,
      formFields: [
        // Email Field
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          style: const TextStyle(color: Colors.white),
          decoration: AuthScaffold.inputDecoration(
              CustomKeys.email, Icons.email_outlined),
        ),
        const SizedBox(height: 20),
        // Password Field
        TextField(
          controller: passwordController,
          obscureText: _isObscure,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleSignIn(),
          style: const TextStyle(color: Colors.white),
          decoration: AuthScaffold.inputDecoration(
                  CustomKeys.password, Icons.lock_outline)
              .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white70,
              ),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
      ],
      actionButton: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                CustomKeys.buttonNameIn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ),
      bottomRow: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hesabınız yok mu?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const SignUp(),
                      ),
                    );
                  },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              CustomKeys.buttonNameUp,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
