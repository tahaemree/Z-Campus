import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/widgets/venue_card.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/widgets/home/search_bar_widget.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode(); // FocusNode eklendi
  bool _showSearchBar = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
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
    _focusNode.dispose(); // FocusNode'u dispose ediyoruz
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final venuesAsync = searchQuery.isEmpty
        ? ref.watch(venuesProvider)
        : ref.watch(searchVenuesProvider(searchQuery));
    final featuredVenuesAsync = ref.watch(featuredVenuesProvider);
    final recentlyViewedVenuesAsync = ref.watch(recentlyViewedVenuesProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          clearVenuesCache(ref);
          ref.invalidate(venuesProvider);
          ref.invalidate(featuredVenuesProvider);
          ref.invalidate(recentlyViewedVenuesProvider);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              elevation: 2,
              backgroundColor: theme.scaffoldBackgroundColor,
              toolbarHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTapDown: (_) => _focusNode.unfocus(),
                  child: SearchBarWidget(
                    onSearch: (query) {
                      ref.read(searchQueryProvider.notifier).state = query;
                    },
                  ),
                ),
              ),
            ),
            if (searchQuery.isEmpty) ...[
              featuredVenuesAsync.when(
                data: (featuredVenues) {
                  if (featuredVenues.isEmpty) return const SliverToBoxAdapter();
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Öne Çıkan Yerler',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(),
                error: (error, stack) => const SliverToBoxAdapter(),
              ),
              featuredVenuesAsync.when(
                data: (featuredVenues) {
                  if (featuredVenues.isEmpty) return const SliverToBoxAdapter();
                  return _buildVenuesList(featuredVenues, theme);
                },
                loading: () => const SliverToBoxAdapter(),
                error: (error, stack) => const SliverToBoxAdapter(),
              ),
              recentlyViewedVenuesAsync.when(
                data: (recentlyViewedVenues) {
                  if (recentlyViewedVenues.isEmpty) {
                    return const SliverToBoxAdapter();
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Son Aranan Yerler',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(),
                error: (error, stack) => const SliverToBoxAdapter(),
              ),
              recentlyViewedVenuesAsync.when(
                data: (recentlyViewedVenues) {
                  if (recentlyViewedVenues.isEmpty) {
                    return const SliverToBoxAdapter();
                  }
                  return _buildVenuesList(recentlyViewedVenues, theme);
                },
                loading: () => const SliverToBoxAdapter(),
                error: (error, stack) => const SliverToBoxAdapter(),
              ),
            ] else
              venuesAsync.when(
                data: (venues) {
                  if (venues.isEmpty) {
                    return _buildEmptyState(theme);
                  }
                  return _buildVenuesList(venues, theme);
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

  SliverFillRemaining _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mekan eklenmemiş',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
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
              'Mekanlar yüklenemedi',
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

  SliverList _buildVenuesList(List<VenueModel> venues, ThemeData theme) {
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
                isFavorite: venue.isFavorite,
                imageUrl: venue.imageUrl,
                announcement: venue.announcement,
                latitude: venue.latitude, // Yeni eklenen alan
                longitude: venue.longitude, // Yeni eklenen alan
                onFavoritePressed: () async {
                  await ref
                      .read(firestoreServiceProvider)
                      .toggleFavorite(venue.id);
                  ref.invalidate(venuesProvider);
                  ref.invalidate(featuredVenuesProvider);
                  ref.invalidate(recentlyViewedVenuesProvider);
                  ref.invalidate(favoriteVenuesProvider);
                },
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
