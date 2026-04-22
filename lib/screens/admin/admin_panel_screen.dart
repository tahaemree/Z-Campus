import 'package:campus_online/providers/access_provider.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/screens/admin/feedback_management_page.dart';
import 'package:campus_online/screens/admin/notification_send_page.dart';
import 'package:campus_online/screens/admin/permissions_management_page.dart';
import 'package:campus_online/screens/admin/venue_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin paneli — TabBar shell.
///
/// Her sekme ayrı bir sayfa widget'ına delege edilir:
/// - [VenueManagementPage]
/// - [PermissionsManagementPage]
/// - [FeedbackManagementPage]
/// - [NotificationSendPage]
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(currentUserAccessProvider);
    final venuesAsync = ref.watch(venuesProvider);

    return accessAsync.when(
      data: (access) {
        final canManageVenues =
            access.isAdmin || access.editableVenueIds.isNotEmpty;
        if (!canManageVenues) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Paneli')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bu alana erişim için admin veya mekan düzenleme yetkisi gereklidir.',
                ),
              ),
            ),
          );
        }

        final isAdmin = access.isAdmin;
        final tabCount = isAdmin ? 4 : 1;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Paneli'),
              bottom: TabBar(
                isScrollable: isAdmin,
                tabAlignment: isAdmin ? TabAlignment.start : TabAlignment.fill,
                tabs: [
                  const Tab(
                    icon: Icon(Icons.store_mall_directory_outlined),
                    text: 'Mekanlar',
                  ),
                  if (isAdmin)
                    const Tab(
                      icon: Icon(Icons.manage_accounts_outlined),
                      text: 'Yetki ve Hesap',
                    ),
                  if (isAdmin)
                    const Tab(
                      icon: Icon(Icons.feedback_outlined),
                      text: 'Geri Bildirimler',
                    ),
                  if (isAdmin)
                    const Tab(
                      icon: Icon(Icons.send_outlined),
                      text: 'Bildirim Gönder',
                    ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                VenueManagementPage(
                  venuesAsync: venuesAsync,
                  access: access,
                ),
                if (isAdmin)
                  PermissionsManagementPage(venuesAsync: venuesAsync),
                if (isAdmin) const FeedbackManagementPage(),
                if (isAdmin) const NotificationSendPage(),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Admin Paneli')),
        body: Center(child: Text('Yetki kontrolü yapılamadı: $error')),
      ),
    );
  }
}
