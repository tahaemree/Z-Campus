import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_online/commons/app_error.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _deleting = false;
  bool _isEditing = false;
  String? _currentName;

  final _supabase = Supabase.instance.client;
  User? get user => _supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user!.id)
          .maybeSingle();

      if (!mounted) return;
      if (data != null && data['display_name'] != null) {
        _nameController.text = data['display_name'];
        setState(() => _currentName = data['display_name']);
      } else if (user!.userMetadata?['display_name'] != null) {
        _nameController.text = user!.userMetadata!['display_name'];
        setState(() => _currentName = user!.userMetadata!['display_name']);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false) || user == null) return;
    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      await _supabase
          .from('users')
          .update({'display_name': name}).eq('id', user!.id);
      await _supabase.auth
          .updateUser(UserAttributes(data: {'display_name': name}));

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _currentName = name;
      });
      AppError.showSuccess(context, 'Profil güncellendi.');
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, 'Profil güncellenemedi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(ctx).colorScheme.error, size: 48),
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınız ve tüm verileriniz kalıcı olarak silinecektir.\n\n'
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Hesabımı Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      // delete_user RPC handles all cleanup (public tables + auth.users)
      await _supabase.rpc('delete_user');
      await _supabase.auth.signOut();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.message.contains('function') || e.code == '42883') {
        AppError.showError(
          context,
          'Hesap silme işlevi henüz yapılandırılmamış. '
          'Lütfen destek ile iletişime geçin.',
        );
      } else {
        AppError.showError(context, 'Hesap silinemedi: ${e.message}');
      }
      setState(() => _deleting = false);
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, 'Hesap silinemedi.');
      setState(() => _deleting = false);
    }
  }

  String _getInitials() {
    if (_currentName != null && _currentName!.isNotEmpty) {
      final parts = _currentName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return user?.email?.substring(0, 1).toUpperCase() ?? '?';
  }

  String _getMemberSince() {
    final created = user?.createdAt;
    if (created == null) return '';
    final date = DateTime.tryParse(created);
    if (date == null) return '';
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // ─── Profile Header Card ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    _currentName ?? 'İsimsiz',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_getMemberSince().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_getMemberSince()}\'den beri üye',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Edit Name Section ───
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_outline,
                          color: theme.colorScheme.primary, size: 22),
                    ),
                    title: const Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: _isEditing
                        ? null
                        : Text(_currentName ?? '-',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() {
                          if (_isEditing) _nameController.text = _currentName ?? '';
                          _isEditing = !_isEditing;
                        });
                      },
                      child: Text(_isEditing ? 'İptal' : 'Düzenle'),
                    ),
                  ),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Adınızı girin',
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'İsim boş olamaz' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _saving ? null : _updateProfile,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Kaydet'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.email_outlined,
                          color: theme.colorScheme.primary, size: 22),
                    ),
                    title: const Text('E-posta', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(email,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Danger Zone ───
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error, size: 22),
                ),
                title: Text('Hesabı Sil',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error)),
                subtitle: Text('Tüm verileriniz kalıcı olarak silinir',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error.withValues(alpha: 0.7))),
                trailing: _deleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: theme.colorScheme.error))
                    : Icon(Icons.chevron_right,
                        color: theme.colorScheme.error.withValues(alpha: 0.5)),
                onTap: _deleting ? null : _deleteAccount,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
