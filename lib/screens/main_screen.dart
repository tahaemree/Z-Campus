import 'package:flutter/material.dart';
import 'package:campus_online/screens/home/explore_screen.dart';
import 'package:campus_online/screens/favorites/favorites_screen.dart';
import 'package:campus_online/screens/settings/settings_screen.dart';
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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: const [
          ExploreScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primaryContainer.withOpacity(0.7),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 600),
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.explore_outlined,
                color: _currentIndex == 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.explore,
                color: theme.colorScheme.primary,
              ),
              label: 'Keşfet',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.favorite_outline,
                color: _currentIndex == 1
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
              ),
              label: 'Favoriler',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.settings,
                color: _currentIndex == 2
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
              ),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
