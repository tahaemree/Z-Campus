import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/providers/search_state.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/widgets/venue_list_sliver.dart';
import 'package:campus_online/widgets/home/search_bar_widget.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  int _currentTabIndex = 0;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }



  void _handleVenueTap(String venueId) {
    Navigator.pushNamed(context, '/venue_details', arguments: venueId);
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
              toolbarHeight: _isSearchActive ? 75 : 65,
              titleSpacing: _isSearchActive
                  ? 0
                  : NavigationToolbar.kMiddleSpacing,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
              leading: _isSearchActive
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        setState(() => _isSearchActive = false);
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        _focusNode.unfocus();
                      },
                    )
                  : null,
              title: _isSearchActive
                  ? Padding(
                      padding: const EdgeInsets.only(
                          right: 16.0, top: 8.0, bottom: 8.0),
                      child: SearchBarWidget(
                        controller: _searchController,
                        autoFocus: true,
                        onSearch: (query) {
                          ref.read(searchQueryProvider.notifier).state =
                              query;
                        },
                      ),
                    )
                  : Text(
                      'Campus Online',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
              actions: [
                if (!_isSearchActive)
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () =>
                        setState(() => _isSearchActive = true),
                  ),
                if (!_isSearchActive) const SizedBox(width: 8),
              ],
              bottom: searchQuery.isEmpty
                  ? TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Keşfet'),
                        Tab(text: 'Tüm Mekanlar'),
                      ],
                    )
                  : null,
            ),
            if (searchQuery.isEmpty) ...[
              if (_currentTabIndex == 0) ...[
                // Featured Venues Header
                featuredVenuesAsync.when(
                  data: (featured) {
                    if (featured.isEmpty) {
                      return const SliverToBoxAdapter();
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
                // Featured Venues List
                featuredVenuesAsync.when(
                  data: (featured) {
                    if (featured.isEmpty) {
                      return const SliverToBoxAdapter();
                    }
                    return VenueListSliver(
                      venues: featured,
                      onVenueTap: _handleVenueTap,
                    );
                  },
                  loading: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
                // Recently Viewed Header
                recentlyViewedVenuesAsync.when(
                  data: (recent) {
                    if (recent.isEmpty) {
                      return const SliverToBoxAdapter();
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
                // Recently Viewed List
                recentlyViewedVenuesAsync.when(
                  data: (recent) {
                    if (recent.isEmpty) {
                      return const SliverToBoxAdapter();
                    }
                    return VenueListSliver(
                      venues: recent,
                      onVenueTap: _handleVenueTap,
                    );
                  },
                  loading: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
              ] else if (_currentTabIndex == 1) ...[
                venuesAsync.when(
                  data: (allVenues) {
                    if (allVenues.isEmpty) {
                      return const VenueEmptyState(
                        icon: Icons.place,
                        title: 'Henüz mekan eklenmemiş',
                      );
                    }
                    final sortedVenues = List<VenueModel>.from(allVenues);
                    sortedVenues.sort((a, b) => a.name
                        .toLowerCase()
                        .compareTo(b.name.toLowerCase()));
                    return VenueListSliver(
                      venues: sortedVenues,
                      onVenueTap: _handleVenueTap,
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => VenueErrorState(
                    error: error,
                    title: 'Mekanlar yüklenemedi',
                  ),
                ),
              ],
            ] else ...[
              venuesAsync.when(
                data: (venues) {
                  if (venues.isEmpty) {
                    return const VenueEmptyState(
                      icon: Icons.search_off,
                      title: 'Sonuç bulunamadı',
                    );
                  }
                  return VenueListSliver(
                    venues: venues,
                    onVenueTap: _handleVenueTap,
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => VenueErrorState(
                  error: error,
                  title: 'Arama başarısız',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
