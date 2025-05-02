import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/services/map_service.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVenueData();
    });
  }

  Future<void> _loadVenueData() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.incrementVisitCount(widget.venueId);
    } catch (e) {
      debugPrint('Error incrementing visit count: $e');
    }
  }

  Future<void> _launchMap(VenueModel venue) async {
    await MapService.launchMap(
      latitude: venue.latitude,
      longitude: venue.longitude,
      locationName: venue.name,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));

    return Scaffold(
      body: venueAsync.when(
        data: (venue) {
          if (venue == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mekan bulunamadı',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(venue, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                venue.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          if (venue.latitude != null && venue.longitude != null)
                            FilledButton.icon(
                              onPressed: () => _launchMap(venue),
                              icon: const Icon(Icons.directions),
                              label: const Text('Git'),
                            ),
                        ],
                      ),
                      if (venue.location != null &&
                          venue.location!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  venue.location!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (venue.announcement != null &&
                          venue.announcement!.isNotEmpty) ...[
                        _buildAnnouncementCard(venue, theme),
                        const SizedBox(height: 16),
                      ],
                      _buildHoursSection(venue, theme),
                      if (venue.menu != null && venue.menu!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMenuSection(venue, theme),
                      ],
                      if (venue.description != null &&
                          venue.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDescriptionSection(venue, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  SliverAppBar _buildAppBar(VenueModel venue, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: venue.imageUrl != null
            ? Image.network(
                venue.imageUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.place,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            venue.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: venue.isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await ref
                        .read(firestoreServiceProvider)
                        .toggleFavorite(venue.id);

                    // Clear all caches and invalidate providers
                    clearVenuesCache(ref);
                    ref.invalidate(venuesProvider);
                    ref.invalidate(featuredVenuesProvider);
                    ref.invalidate(recentlyViewedVenuesProvider);
                    ref.invalidate(favoriteVenuesProvider);
                    ref.invalidate(venueByIdProvider(venue.id));

                    // Force a rebuild of the widget
                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Favori durumu güncellenemedi'),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(VenueModel venue, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.announcement,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Duyuru',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                venue.announcement!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursSection(VenueModel venue, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Çalışma Saatleri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: venue.weekendHours.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHoursRow('Hafta İçi', venue.weekdayHours, theme),
                        const SizedBox(height: 8),
                        _buildHoursRow('Hafta Sonu', venue.weekendHours, theme),
                      ],
                    )
                  : Text(
                      venue.weekdayHours,
                      style: theme.textTheme.bodyMedium,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursRow(String label, String hours, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            hours,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(VenueModel venue, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Menü',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                venue.menu!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(VenueModel venue, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Açıklama',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                venue.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
