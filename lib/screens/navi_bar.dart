import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/screens/home/explore_screen.dart';
import 'package:campus_online/screens/favorites/favorites_screen.dart';
import 'package:campus_online/screens/settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

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
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          ExploreScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          height: 65,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: theme.colorScheme.surface,
          elevation: 8,
          shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
          surfaceTintColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primaryContainer.withOpacity(0.7),
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.explore_outlined,
                color: theme.colorScheme.onSurfaceVariant,
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
              ),
              label: 'Favoriler',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.settings_outlined,
                color: theme.colorScheme.onSurfaceVariant,
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
