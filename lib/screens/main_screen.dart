import 'package:flutter/material.dart';
import 'package:campus_online/screens/home/explore_screen.dart';
import 'package:campus_online/screens/favorites/favorites_screen.dart';
import 'package:campus_online/screens/settings/settings_screen.dart';
import 'package:campus_online/screens/admin/admin_panel_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/services/firebase/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late PageController _pageController;
  bool _isAdmin = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final authService = ref.read(authServiceProvider);
    final isAdmin = await authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          const ExploreScreen(),
          const FavoritesScreen(),
          const SettingsScreen(),
          if (_isAdmin) const AdminPanelScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
