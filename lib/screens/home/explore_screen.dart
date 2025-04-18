import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/widgets/home/search_bar_widget.dart';
import 'package:campus_online/widgets/venue_card.dart';
import 'package:campus_online/widgets/home/section_header.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/firebase/firestore_service.dart';
import 'package:campus_online/models/venue_model.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _scrollPhysics = const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    final show = _scrollController.position.pixels <= 50;
    if (show != _showSearchBar) {
      setState(() {
        _showSearchBar = show;
      });
    }
  }

  Future<void> _toggleFavorite(String venueId, bool currentIsFavorite) async {
    try {
      // Optimistic UI update
      ref.read(venuesCacheProvider.notifier).invalidate('venue_$venueId');
      clearVenuesCache(ref, specificKey: 'featured');
      clearVenuesCache(ref, specificKey: 'favorites');

      // Update Firestore
      await _firestoreService.toggleFavorite(venueId);

      // Clear affected caches
      invalidateVenue(ref, venueId);
      clearVenuesCache(ref, specificKey: 'featured');
      clearVenuesCache(ref, specificKey: 'favorites');
      clearVenuesCache(ref, specificKey: 'recentlyViewed');

      // Refresh providers
      ref.invalidate(venueByIdProvider(venueId));
      ref.invalidate(featuredVenuesProvider);
      ref.invalidate(favoriteVenuesProvider);
    } catch (e) {
      if (mounted) {
        // Restore state and show error
        invalidateVenue(ref, venueId);
        clearVenuesCache(ref, specificKey: 'featured');
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
    final featuredVenuesAsync = ref.watch(featuredVenuesProvider);
    final recentlyViewedVenuesAsync = ref.watch(recentlyViewedVenuesProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchBarWidget(onSearch: _handleSearch),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: () async {
                    clearVenuesCache(ref, specificKey: 'featured');
                    clearVenuesCache(ref, specificKey: 'recentlyViewed');
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: _scrollPhysics,
                    slivers: [
                      _buildSearchResultsSection(searchResultsAsync, theme),
                      if (searchQuery.isEmpty) ...[
                        _buildFeaturedVenuesSection(featuredVenuesAsync, theme),
                        _buildRecentlyViewedSection(
                            recentlyViewedVenuesAsync, theme),
                      ],
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 16),
                        sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedVenuesSection(
      AsyncValue<List<dynamic>> venuesAsync, ThemeData theme) {
    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildListDelegate([
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SectionHeader(title: 'Öne Çıkan Mekanlar'),
            ),
            ...venues.map((venue) => _buildVenueCard(venue, theme)),
          ]),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState(error, theme),
      ),
    );
  }

  Widget _buildRecentlyViewedSection(
      AsyncValue<List<dynamic>> venuesAsync, ThemeData theme) {
    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildListDelegate([
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: SectionHeader(title: 'Son Görüntülenenler'),
            ),
            ...venues.map((venue) => _buildVenueCard(venue, theme)),
          ]),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState(error, theme),
      ),
    );
  }

  Widget _buildVenueCard(VenueModel venue, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Hero(
        tag: 'venue_card_${venue.id}',
        child: VenueCard(
          venueId: venue.id,
          venueName: venue.name,
          hours: venue.weekdayHours,
          location: venue.location,
          venueIcon: _getVenueIcon(venue.category),
          isFavorite: venue.isFavorite,
          imageUrl: venue.imageUrl,
          onFavoritePressed: () => _toggleFavorite(venue.id, venue.isFavorite),
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
  }

  Widget _buildErrorState(dynamic error, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Mekanlar yüklenemedi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                clearVenuesCache(ref);
                ref.invalidate(featuredVenuesProvider);
                ref.invalidate(recentlyViewedVenuesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  IconData _getVenueIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cafeteria':
      case 'yemekhane':
        return Icons.restaurant;
      case 'library':
      case 'kütüphane':
        return Icons.local_library;
      case 'mosque':
      case 'cami':
        return Icons.mosque;
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

  Widget _buildSearchResultsSection(
      AsyncValue<List<VenueModel>> resultsAsync, ThemeData theme) {
    return resultsAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildListDelegate([
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SectionHeader(title: 'Arama Sonuçları'),
            ),
            ...venues.map((venue) => _buildVenueCard(venue, theme)),
          ]),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildErrorState(error, theme),
      ),
    );
  }
}
