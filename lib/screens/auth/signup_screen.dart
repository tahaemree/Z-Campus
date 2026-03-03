import 'package:flutter/material.dart';
import 'package:campus_online/commons/custom_keys.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/screens/auth/auth_services.dart';
import 'package:campus_online/widgets/auth/auth_scaffold.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthServices _services = AuthServices();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    userController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final String username = userController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (username.isEmpty) {
      AppError.showError(context, 'Kullanıcı adı gerekli');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      AppError.showError(context, 'Geçerli bir email adresi girin');
      return;
    }

    if (password.length < 6) {
      AppError.showError(context, 'Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _services.signUp(username, email, password);
      if (!mounted) return;

      AppError.showSuccess(context, CustomKeys.succesSignUp);
      Navigator.pop(context);
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
      subtitle: 'Aramıza Katıl',
      isLoading: _isLoading,
      formFields: [
        // Username Field
        TextField(
          controller: userController,
          keyboardType: TextInputType.text,
          enabled: !_isLoading,
          style: const TextStyle(color: Colors.white),
          decoration: AuthScaffold.inputDecoration(
              CustomKeys.userName, Icons.person_outline),
        ),
        const SizedBox(height: 16),
        // Email Field
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          style: const TextStyle(color: Colors.white),
          decoration: AuthScaffold.inputDecoration(
              CustomKeys.email, Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        // Password Field
        TextField(
          controller: passwordController,
          obscureText: _isObscure,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleSignUp(),
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
        onPressed: _isLoading ? null : _handleSignUp,
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
                CustomKeys.buttonNameUp,
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
            'Zaten hesabınız var mı?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              CustomKeys.buttonNameIn,
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
