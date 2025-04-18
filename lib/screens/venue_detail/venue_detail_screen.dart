import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/firebase/firestore_service.dart';
import 'package:campus_online/models/venue_model.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailScreen({
    super.key,
    required this.venueId,
  });

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _toggleFavorite() async {
    try {
      // Get current venue
      final currentVenue = ref.read(venueByIdProvider(widget.venueId)).value;
      if (currentVenue == null) return;

      // Optimistic UI update
      ref.read(venuesCacheProvider.notifier).put(
        'venue_${widget.venueId}',
        [currentVenue.copyWith(isFavorite: !currentVenue.isFavorite)],
      );

      // Update Firestore
      await _firestoreService.toggleFavorite(widget.venueId);

      // Clear all relevant caches
      invalidateVenue(ref, widget.venueId);
      clearVenuesCache(ref, specificKey: 'favorites');
      clearVenuesCache(ref, specificKey: 'featured');
      clearVenuesCache(ref, specificKey: 'recentlyViewed');

      // Refresh the venue data
      ref.invalidate(venueByIdProvider(widget.venueId));
    } catch (e) {
      if (mounted) {
        // Restore state on error
        invalidateVenue(ref, widget.venueId);
        clearVenuesCache(ref, specificKey: 'favorites');
        clearVenuesCache(ref, specificKey: 'featured');
        clearVenuesCache(ref, specificKey: 'recentlyViewed');

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
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: venueAsync.whenData((venue) {
            if (venue == null) return const SizedBox.shrink();
            return FloatingActionButton(
              onPressed: _toggleFavorite,
              backgroundColor: Colors.white,
              elevation: 4,
              child: Icon(
                venue.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: venue.isFavorite ? Colors.red : Colors.grey,
              ),
            );
          }).value ??
          const SizedBox.shrink(),
      body: venueAsync.when(
        data: (venue) {
          if (venue == null) {
            return const Center(child: Text('Mekan bulunamadı'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Hero(
                  tag: 'venue_${venue.id}',
                  child: _buildHeader(venue),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Çalışma Saatleri',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimeRow('Hafta İçi', venue.weekdayHours),
                                if (venue.weekendHours.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildTimeRow(
                                      'Hafta Sonu', venue.weekendHours),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Konum',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              venue.location,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(String day, String hours) {
    return Row(
      children: [
        Text(
          '$day: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          hours,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(VenueModel venue) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: venue.imageUrl != null
          ? Image.network(
              venue.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultHeader(venue),
            )
          : _buildDefaultHeader(venue),
    );
  }

  Widget _buildDefaultHeader(VenueModel venue) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getVenueIcon(venue.category),
          size: 80,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  IconData _getVenueIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mosque':
      case 'cami':
        return Icons.mosque;
      case 'library':
      case 'kütüphane':
        return Icons.local_library;
      case 'cafeteria':
      case 'yemekhane':
        return Icons.restaurant;
      case 'cafe':
      case 'kafe':
        return Icons.coffee;
      case 'gym':
      case 'spor salonu':
        return Icons.fitness_center;
      default:
        return Icons.place;
    }
  }
}
