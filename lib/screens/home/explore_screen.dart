import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/models/explore_models.dart';
import 'package:campus_online/providers/notifications_provider.dart';
import 'package:campus_online/config/app_config.dart';
import 'package:campus_online/providers/events_provider.dart';
import 'package:campus_online/providers/explore_provider.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/providers/search_state.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/widgets/event_card.dart';
import 'package:campus_online/widgets/venue_card.dart';
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

  void _handleEventTap(String eventId) {
    Navigator.pushNamed(context, '/event_details', arguments: eventId);
  }

  void _openNotificationsPanel() {
    Navigator.pushNamed(context, '/notifications');
  }

  Future<void> _toggleEventFavorite(
    String eventId,
    bool currentlyFavorite,
  ) async {
    try {
      await ref.read(eventFavoriteIdsProvider.notifier).toggle(eventId);
      if (!mounted) return;
      AppError.showSuccess(
        context,
        currentlyFavorite
            ? 'Etkinlik favorilerden çıkarıldı.'
            : 'Etkinlik favorilere eklendi.',
      );
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final venuesAsync = searchQuery.isEmpty
        ? ref.watch(venuesProvider)
        : ref.watch(searchVenuesProvider(searchQuery));
    final exploreSettings = ref.watch(exploreSettingsProvider).valueOrNull ??
        ExploreSettings.defaults;
    final contributionsAsync = ref.watch(exploreContributionsProvider);
    final recentlyViewedVenuesAsync =
        ref.watch(exploreRecentlyViewedVenuesProvider);
    final favoriteEventIds = ref.watch(eventFavoriteIdsProvider);
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          try {
            clearVenuesCache(ref);
            invalidateExplore(ref);
            ref.invalidate(venuesProvider);
            invalidateEvents(ref);

            await Future.wait([
              ref.read(eventFavoriteIdsProvider.notifier).load(),
              ref.refresh(exploreSettingsProvider.future),
              ref.refresh(exploreContributionsProvider.future),
              ref.refresh(exploreRecentlyViewedVenuesProvider.future),
              ref.refresh(venuesProvider.future),
            ]);

            if (!context.mounted) return;
            AppError.showSuccess(context, 'Mekanlar yenilendi.');
          } catch (e) {
            if (!context.mounted) return;
            AppError.showError(context, AppError.getUserFriendlyMessage(e));
          }
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
              centerTitle: true,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              backgroundColor: theme.scaffoldBackgroundColor,
              toolbarHeight: _isSearchActive ? 75 : 65,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: child.key == const ValueKey('search_view')
                        ? const Offset(0.05, 0.0)
                        : const Offset(-0.05, 0.0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: _isSearchActive
                    ? Row(
                        key: const ValueKey('search_view'),
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              setState(() => _isSearchActive = false);
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              _focusNode.unfocus();
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, bottom: 8.0, right: 8.0),
                              child: SearchBarWidget(
                                controller: _searchController,
                                autoFocus: true,
                                onSearch: (query) {
                                  ref.read(searchQueryProvider.notifier).state =
                                      query;
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        key: const ValueKey('default_view'),
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              AppConfig.appName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          Icons.notifications_none_rounded,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        if (unreadNotificationCount > 0)
                                          Positioned(
                                            right: -6,
                                            top: -6,
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                minWidth: 18,
                                                minHeight: 18,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.error,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: theme
                                                      .scaffoldBackgroundColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  unreadNotificationCount > 99
                                                      ? '99+'
                                                      : unreadNotificationCount
                                                          .toString(),
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.onError,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    tooltip: 'Bildirimler',
                                    onPressed: _openNotificationsPanel,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.search_rounded,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    onPressed: () =>
                                        setState(() => _isSearchActive = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
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
                contributionsAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const SliverToBoxAdapter();
                    return _ExploreSectionHeader(
                      title: exploreSettings.contributionsTitle,
                      topPadding: 16,
                    );
                  },
                  loading: () => const SliverToBoxAdapter(),
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
                contributionsAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const SliverToBoxAdapter();
                    return _ExploreContributionSliver(
                      items: items,
                      favoriteEventIds: favoriteEventIds,
                      onVenueTap: _handleVenueTap,
                      onEventTap: _handleEventTap,
                      onEventFavoriteToggle: _toggleEventFavorite,
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
                recentlyViewedVenuesAsync.when(
                  data: (recent) {
                    if (recent.isEmpty) {
                      return const SliverToBoxAdapter();
                    }
                    return _ExploreSectionHeader(
                      title: exploreSettings.recentViewsTitle,
                      topPadding:
                          (contributionsAsync.valueOrNull ?? const []).isEmpty
                              ? 16
                              : 8,
                    );
                  },
                  loading: () => const SliverToBoxAdapter(),
                  error: (_, __) => const SliverToBoxAdapter(),
                ),
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
                if ((contributionsAsync.valueOrNull ?? const []).isEmpty &&
                    (recentlyViewedVenuesAsync.valueOrNull ?? const [])
                        .isEmpty &&
                    !contributionsAsync.isLoading &&
                    !recentlyViewedVenuesAsync.isLoading)
                  const VenueEmptyState(
                    icon: Icons.explore_outlined,
                    title: 'Keşfet içerikleri hazırlanıyor',
                    subtitle:
                        'Öne çıkan mekanlar, etkinlikler ve son göz atılan yerler burada görünecek.',
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
                    sortedVenues.sort((a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

class _ExploreSectionHeader extends StatelessWidget {
  const _ExploreSectionHeader({
    required this.title,
    required this.topPadding,
  });

  final String title;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 4),
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ExploreContributionSliver extends StatelessWidget {
  const _ExploreContributionSliver({
    required this.items,
    required this.favoriteEventIds,
    required this.onVenueTap,
    required this.onEventTap,
    required this.onEventFavoriteToggle,
  });

  final List<ExploreContribution> items;
  final Set<String> favoriteEventIds;
  final void Function(String venueId) onVenueTap;
  final void Function(String eventId) onEventTap;
  final Future<void> Function(String eventId, bool currentlyFavorite)
      onEventFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            final venue = item.venue;
            final event = item.event;
            final label = item.label?.trim();

            Widget child;
            if (venue != null) {
              child = VenueCard(
                venueId: venue.id,
                venueName: venue.name,
                hours: venue.hours,
                weekendHours:
                    venue.weekendHours.isNotEmpty ? venue.weekendHours : null,
                location: venue.location ?? '',
                venueIcon: Icons.place,
                isFavorite: venue.isFavorite,
                imageUrl: venue.imageUrl,
                announcement: venue.announcement,
                latitude: venue.latitude,
                longitude: venue.longitude,
                onTap: () => onVenueTap(venue.id),
              );
            } else if (event != null) {
              final isFavorite = favoriteEventIds.contains(event.id);
              child = EventCard(
                event: event,
                isFavorite: isFavorite,
                onTap: () => onEventTap(event.id),
                onFavoriteToggle: () =>
                    onEventFavoriteToggle(event.id, isFavorite),
              );
            } else {
              child = const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null && label.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: _ContributionLabel(
                        label: label,
                        isEvent: event != null,
                      ),
                    ),
                  ],
                  child,
                ],
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _ContributionLabel extends StatelessWidget {
  const _ContributionLabel({
    required this.label,
    required this.isEvent,
  });

  final String label;
  final bool isEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEvent ? Icons.event_available_outlined : Icons.handshake,
              size: 14,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
