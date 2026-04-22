import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/providers/service_providers.dart';
import 'package:campus_online/services/contact_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  ContactFeedbackCategory _selectedCategory = ContactFeedbackCategory.general;
  bool _isSubmitting = false;
  bool _wantsResponse = true;

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  bool get _isGuest => _currentUser == null;

  @override
  void initState() {
    super.initState();
    final email = _currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    _wantsResponse = _isGuest || _emailController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(contactServiceProvider);
      final shouldSendEmail = _isGuest || _wantsResponse;

      await service.submitFeedback(
        ContactFeedbackDraft(
          category: _selectedCategory,
          subject: _subjectController.text,
          message: _messageController.text,
          contactEmail: shouldSendEmail ? _emailController.text : null,
          devicePlatform: currentDevicePlatformLabel(),
        ),
      );

      if (!mounted) return;

      _subjectController.clear();
      _messageController.clear();
      if (_isGuest) {
        _emailController.clear();
      }

      AppError.showSuccess(
        context,
        'Mesajınız bize ulaştı. En kısa sürede değerlendirilecektir.',
      );
    } on ContactValidationException catch (error) {
      if (!mounted) return;
      AppError.showError(context, error.message);
    } catch (error) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateSubject(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Lütfen bir konu girin.';
    }
    if (text.length < 4 || text.length > 140) {
      return 'Konu 4 ile 140 karakter arasında olmalıdır.';
    }
    return null;
  }

  String? _validateMessage(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Lütfen mesajınızı yazın.';
    }
    if (text.length < 10 || text.length > 2000) {
      return 'Mesaj 10 ile 2000 karakter arasında olmalıdır.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    final isRequired = _isGuest || _wantsResponse;

    if (isRequired && text.isEmpty) {
      return 'Lütfen e-posta adresinizi girin.';
    }

    if (text.isNotEmpty && !ContactFeedbackPayloadBuilder.isValidEmail(text)) {
      return 'Lütfen geçerli bir e-posta adresi girin.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmailVisible = _isGuest || _wantsResponse;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bize Ulaşın'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geri bildirim, önerileriniz ve tavsiyeleriniz bizim için çok değerli.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isGuest
                          ? 'Misafir gönderimlerinde size dönüş yapabilmemiz için e-posta alanı zorunludur.'
                          : 'İsterseniz size dönüş yapabilmemiz için e-posta adresinizi bırakabilirsiniz.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ContactFeedbackCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: ContactFeedbackCategory.values
                    .map(
                      (category) => DropdownMenuItem<ContactFeedbackCategory>(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedCategory = value);
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                enabled: !_isSubmitting,
                maxLength: 140,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Konu',
                  hintText: 'Kısa ve anlaşılır bir başlık yazın',
                  border: OutlineInputBorder(),
                ),
                validator: _validateSubject,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                enabled: !_isSubmitting,
                minLines: 5,
                maxLines: 9,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Mesajınız',
                  hintText:
                      'Yaşadığınız durumu, beklentinizi veya önerilerinizi detaylı şekilde yazın.',
                  border: OutlineInputBorder(),
                ),
                validator: _validateMessage,
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isGuest ? true : _wantsResponse,
                onChanged: _isGuest || _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _wantsResponse = value);
                      },
                title: const Text('Geri dönüş almak istiyorum'),
                subtitle: Text(
                  _isGuest
                      ? 'Misafir kullanımda e-posta alanı zorunludur.'
                      : 'İşaretlerseniz ekibimiz e-posta ile size dönüş yapabilir.',
                ),
              ),
              if (isEmailVisible) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'ornek@universite.edu.tr',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting ? 'Gönderiliyor...' : 'Geri Bildirim Gönder',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
