import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/services/map_service.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:transparent_image/transparent_image.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVenueData();
    });
  }

  Future<void> _loadVenueData() async {
    try {
      await incrementVisitCount(ref, widget.venueId);
    } catch (e) {
      debugPrint('Error incrementing visit count: $e');
    }
  }

  Future<void> _handleToggleFavorite(String venueId) async {
    try {
      await ref.read(favoriteIdsProvider.notifier).toggle(venueId);
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
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
    final favIds = ref.watch(favoriteIdsProvider);

    return Scaffold(
      body: venueAsync.when(
        data: (venue) {
          final isFav = favIds.contains(widget.venueId);
          return CustomScrollView(
            slivers: [
              _buildAppBar(venue, theme, isFav),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow
                            .withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Venue name and direction button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue.name,
                                    style: theme
                                        .textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (venue.location != null &&
                                      venue.location!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            venue.location!,
                                            style: theme
                                                .textTheme.bodyLarge
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (venue.latitude != null &&
                                venue.longitude != null)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _launchMap(venue),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.directions_rounded,
                                            color: theme.colorScheme
                                                .onPrimary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tarif Al',
                                            style: theme
                                                .textTheme.labelLarge
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onPrimary,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Venue stats row
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme
                                .colorScheme.surfaceContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  Icons.visibility_outlined,
                                  'Ziyaret',
                                  '${venue.visitCount}',
                                  theme,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  Icons.favorite_outline,
                                  'Favori',
                                  isFav ? '❤️' : '🤍',
                                  theme,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  Icons.schedule_outlined,
                                  'Durum',
                                  _getOpenStatus(venue),
                                  theme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      if (venue.announcement != null &&
                          venue.announcement!.isNotEmpty) ...[
                        _buildAnnouncementCard(venue, theme),
                        const SizedBox(height: 16),
                      ],
                      _buildHoursSection(venue, theme),
                      if (venue.menu != null &&
                          venue.menu!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMenuSection(venue, theme),
                      ],
                      if (venue.description != null &&
                          venue.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDescriptionSection(venue, theme),
                      ],
                      const SizedBox(height: 32),
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

  SliverAppBar _buildAppBar(VenueModel venue, ThemeData theme, bool isFav) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            venue.imageUrl != null
                ? Hero(
                    tag: 'venue-${venue.id}',
                    child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: venue.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/izu.png',
                    fit: BoxFit.cover,
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.white,
              size: 28,
            ),
            onPressed: () => _handleToggleFavorite(venue.id),
          ),
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
              Icon(Icons.announcement,
                  color: theme.colorScheme.error, size: 20),
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
              Icon(Icons.access_time,
                  color: theme.colorScheme.primary, size: 20),
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
                        _buildHoursRow(
                            'Hafta İçi', venue.hours, theme),
                        const SizedBox(height: 8),
                        _buildHoursRow(
                            'Hafta Sonu', venue.weekendHours, theme),
                      ],
                    )
                  : Text(venue.hours,
                      style: theme.textTheme.bodyMedium),
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
          child: Text(hours, style: theme.textTheme.bodyMedium),
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
              Icon(Icons.restaurant_menu,
                  color: theme.colorScheme.primary, size: 20),
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
              child:
                  Text(venue.menu!, style: theme.textTheme.bodyMedium),
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
              Icon(Icons.info_outline,
                  color: theme.colorScheme.primary, size: 20),
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
              child: Text(venue.description!,
                  style: theme.textTheme.bodyMedium),
            ),
          ),
        ),
      ],
    );
  }

  /// Parses common hour formats to determine open/close status.
  /// Supports: "HH:MM-HH:MM", "24 saat", "7/24", "kapalı".
  String _getOpenStatus(VenueModel venue) {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final hours = isWeekend ? venue.weekendHours : venue.hours;

    if (hours.isEmpty || hours.toLowerCase().contains('kapalı')) {
      return 'Kapalı';
    }

    if (hours.toLowerCase().contains('24 saat') ||
        hours.toLowerCase().contains('7/24')) {
      return 'Açık';
    }

    // Try to parse "HH:MM-HH:MM" or "HH.MM-HH.MM" format
    final regex =
        RegExp(r'(\d{1,2})[:\.](\d{2})\s*[-–]\s*(\d{1,2})[:\.](\d{2})');
    final match = regex.firstMatch(hours);
    if (match != null) {
      final openHour = int.parse(match.group(1)!);
      final openMin = int.parse(match.group(2)!);
      final closeHour = int.parse(match.group(3)!);
      final closeMin = int.parse(match.group(4)!);

      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = openHour * 60 + openMin;
      final closeMinutes = closeHour * 60 + closeMin;

      if (nowMinutes >= openMinutes && nowMinutes < closeMinutes) {
        return 'Açık';
      }
      return 'Kapalı';
    }

    return '-';
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
