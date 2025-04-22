import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/widgets/venue_card.dart';
import 'package:campus_online/services/firebase/firestore_service.dart';
import 'package:campus_online/models/venue_model.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _toggleFavorite(String venueId) async {
    invalidateVenue(ref, venueId);
    clearVenuesCache(ref, specificKey: 'favorites');

    try {
      await _firestoreService.toggleFavorite(venueId);
      invalidateVenue(ref, venueId);
      clearVenuesCache(ref, specificKey: 'favorites');
    } catch (e) {
      if (mounted) {
        invalidateVenue(ref, venueId);
        clearVenuesCache(ref, specificKey: 'favorites');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Favori durumu güncellenemedi'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteVenuesAsync = ref.watch(favoriteVenuesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          clearVenuesCache(ref, specificKey: 'favorites');
          ref.invalidate(favoriteVenuesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            favoriteVenuesAsync.when(
              data: (favoriteVenues) {
                if (favoriteVenues.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildFavoriteVenuesList(favoriteVenues, theme);
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildErrorState(error, theme),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Favorilerim',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  SliverFillRemaining _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz favori mekan yok',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Favorilerinizi burada görmek için mekanları favorilere ekleyin',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverFillRemaining _buildErrorState(Object error, ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Favoriler yüklenemedi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildFavoriteVenuesList(
      List<VenueModel> venues, ThemeData theme) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        ...venues.map((venue) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Hero(
              tag: 'venue_card_${venue.id}',
              child: VenueCard(
                venueId: venue.id,
                venueName: venue.name,
                hours: venue.weekdayHours,
                weekendHours:
                    venue.weekendHours.isNotEmpty ? venue.weekendHours : null,
                location: venue.location ?? '',
                venueIcon: Icons.place,
                isFavorite: true,
                imageUrl: venue.imageUrl,
                announcement: venue.announcement,
                onFavoritePressed: () => _toggleFavorite(venue.id),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/venue_details',
                    arguments: venue.id,
                  );
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ]),
    );
  }
}
