import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/theme_provider.dart';
import 'package:campus_online/main.dart' as app;
import 'package:campus_online/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_online/screens/admin/admin_panel_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider).isDarkMode;
    final authService = ref.read(app.authServiceProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (currentUser != null) ...[
            _buildUserSection(context, currentUser),
            const SizedBox(height: 16),
            _buildDivider(),
          ],
          const SizedBox(height: 8),
          _buildSection(
            title: 'Görünüm',
            icon: Icons.palette_outlined,
            children: [
              _buildSettingTile(
                leading: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: 'Koyu Mod',
                trailing: Switch.adaptive(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: 'Gizlilik Politikası',
                onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
                showChevron: true,
              ),
              _buildSettingTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: 'Kullanım Koşulları',
                onTap: () => Navigator.pushNamed(context, '/terms_of_service'),
                showChevron: true,
              ),
            ],
          ),
          if (currentUser != null &&
              currentUser.email == 'admin@admin.com') ...[
            const SizedBox(height: 16),
            _buildSection(
              title: 'Yönetim',
              icon: Icons.admin_panel_settings_outlined,
              children: [
                _buildSettingTile(
                  leading: Icon(
                    Icons.dashboard_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: 'Admin Paneli',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  ),
                  showChevron: true,
                ),
              ],
            ),
          ],
          if (currentUser != null) ...[
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 8),
            _buildSection(
              title: 'Hesap',
              icon: Icons.account_circle_outlined,
              children: [
                _buildSettingTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: 'Çıkış Yap',
                  titleColor: Theme.of(context).colorScheme.error,
                  onTap: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, User user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.displayName?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Kullanıcı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingTile({
    required Widget leading,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool showChevron = false,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            (showChevron
                ? const Icon(Icons.chevron_right, size: 20)
                : const SizedBox.shrink()),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }
}
