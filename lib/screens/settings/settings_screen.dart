import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_online/providers/theme_provider.dart';
import 'package:campus_online/providers/access_provider.dart';
import 'package:campus_online/providers/service_providers.dart';
import 'package:campus_online/screens/admin/admin_panel_screen.dart';
import 'package:campus_online/screens/events/event_management_screen.dart';
import 'package:campus_online/commons/app_error.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider).isDarkMode;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);
    final accessAsync = ref.watch(currentUserAccessProvider);

    final String displayName =
        currentUser?.userMetadata?['display_name'] ?? 'İsimsiz Kullanıcı';
    final String photoUrl = currentUser?.userMetadata?['avatar_url'] ?? '';

    final isAdmin = accessAsync.maybeWhen(
      data: (access) => access.isAdmin,
      orElse: () => false,
    );

    final canManageEvents = accessAsync.maybeWhen(
      data: (access) => access.canManageEvents,
      orElse: () => false,
    );

    final canManageVenues = accessAsync.maybeWhen(
      data: (access) => access.isAdmin || access.editableVenueIds.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE SECTION
          if (currentUser != null) ...[
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 36,
                              color: theme.colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Giriş yapmadınız',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _buildSection(
            title: 'Görünüm',
            icon: Icons.palette_outlined,
            children: [
              _buildSettingTile(
                leading: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: 'Karanlık Mod',
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                    AppError.showSuccess(
                      context,
                      value
                          ? 'Karanlık mod etkinleştirildi.'
                          : 'Aydınlık mod etkinleştirildi.',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Destek',
            icon: Icons.support_agent_outlined,
            children: [
              _buildSettingTile(
                leading: Icon(
                  Icons.forum_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: 'Bize Ulaşın',
                onTap: () => Navigator.pushNamed(context, '/contact_us'),
                showChevron: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Yasal',
            icon: Icons.gavel_outlined,
            children: [
              _buildSettingTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: 'Gizlilik Politikası',
                onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
                showChevron: true,
              ),
              _buildSettingTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: 'Kullanım Koşulları',
                onTap: () => Navigator.pushNamed(context, '/terms_of_service'),
                showChevron: true,
              ),
            ],
          ),
          if (canManageVenues || canManageEvents) ...[
            const SizedBox(height: 16),
            _buildSection(
              title: 'Yönetim',
              icon: Icons.admin_panel_settings_outlined,
              children: [
                if (canManageVenues)
                  _buildSettingTile(
                    leading: Icon(
                      isAdmin ? Icons.dashboard_outlined : Icons.store_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: isAdmin ? 'Admin Paneli' : 'Mekan Yönetimi',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPanelScreen(),
                      ),
                    ),
                    showChevron: true,
                  ),
                if (canManageEvents)
                  _buildSettingTile(
                    leading: Icon(
                      Icons.event_note_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: 'Etkinlik Yönetimi',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventManagementScreen(),
                      ),
                    ),
                    showChevron: true,
                  ),
              ],
            ),
          ],
          if (currentUser != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),
            _buildSection(
              title: 'Hesap',
              icon: Icons.account_circle_outlined,
              children: [
                _buildSettingTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: 'Çıkış Yap',
                  titleColor: theme.colorScheme.error,
                  onTap: () => _handleLogout(context, theme, ref),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) {
          AppError.showSuccess(context, 'Çıkış yapıldı.');
        }
        // Auth state change handled by main.dart's authStateProvider
      } catch (e) {
        if (context.mounted) {
          AppError.showError(context, AppError.getUserFriendlyMessage(e));
        }
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required Widget leading,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
      ),
      trailing:
          trailing ?? (showChevron ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
