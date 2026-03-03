import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/widgets/venue_list_sliver.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  void _handleVenueTap(String venueId) {
    Navigator.pushNamed(context, '/venue_details', arguments: venueId);
  }

  @override
  Widget build(BuildContext context) {
    // Uses derived provider — updates instantly when favorites change
    final favVenuesAsync = ref.watch(favoriteVenuesList);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          clearVenuesCache(ref);
          // Reload both venue data and favorite IDs
          await ref.read(favoriteIdsProvider.notifier).load();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            favVenuesAsync.when(
              data: (favorites) {
                if (favorites.isEmpty) {
                  return const VenueEmptyState(
                    icon: Icons.favorite_border,
                    title: 'Henüz favori mekan yok',
                    subtitle: 'Favorilerinizi burada görmek için mekanları favorilere ekleyin',
                  );
                }
                return VenueListSliver(venues: favorites, onVenueTap: _handleVenueTap);
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (error, _) => VenueErrorState(error: error, title: 'Favoriler yüklenemedi'),
            ),
          ],
        ),
      ),
    );
  }
}
