import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/event_model.dart';
import 'package:campus_online/providers/events_provider.dart';
import 'package:campus_online/services/map_service.dart';
import 'package:campus_online/widgets/over_image_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year} $hh:$min';
  }

  _EventStatus _statusFor(EventModel event) {
    final now = DateTime.now().toUtc();

    if (now.isBefore(event.startAt.toUtc())) {
      return _EventStatus.upcoming;
    }

    if (now.isAfter(event.endAt.toUtc())) {
      return _EventStatus.completed;
    }

    return _EventStatus.live;
  }

  String _statusLabel(_EventStatus status) {
    switch (status) {
      case _EventStatus.upcoming:
        return 'Yaklaşıyor';
      case _EventStatus.live:
        return 'Canli';
      case _EventStatus.completed:
        return 'Tamamlandi';
    }
  }

  Color _statusColor(_EventStatus status, ThemeData theme) {
    switch (status) {
      case _EventStatus.upcoming:
        return theme.colorScheme.primary;
      case _EventStatus.live:
        return Colors.green;
      case _EventStatus.completed:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes <= 0) {
      return '-';
    }

    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} dk';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (minutes == 0) {
      return '$hours saat';
    }

    return '$hours saat $minutes dk';
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    bool currentlyFavorite,
  ) async {
    try {
      await ref.read(eventFavoriteIdsProvider.notifier).toggle(eventId);
      if (!context.mounted) return;
      AppError.showSuccess(
        context,
        currentlyFavorite
            ? 'Etkinlik favorilerden çıkarıldı.'
            : 'Etkinlik favorilere eklendi.',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  Future<void> _openDirections(BuildContext context, EventModel event) async {
    final locationName = (event.location ?? '').trim().isEmpty
        ? event.title.trim()
        : event.location!.trim();

    if (event.latitude != null && event.longitude != null) {
      await MapService.launchMap(
        latitude: event.latitude,
        longitude: event.longitude,
        locationName: locationName,
        context: context,
      );
      return;
    }

    final query = locationName == event.title.trim()
        ? locationName
        : '$locationName ${event.title}'.trim();
    await MapService.launchMapByQuery(query: query, context: context);
  }

  bool _hasDirectionTarget(EventModel event) {
    return (event.latitude != null && event.longitude != null) ||
        (event.location ?? '').trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    final favoriteEventIds = ref.watch(eventFavoriteIdsProvider);

    return Scaffold(
      body: eventAsync.when(
        data: (event) {
          final status = _statusFor(event);
          final isFavorite = favoriteEventIds.contains(event.id);

          return CustomScrollView(
            slivers: [
              _buildAppBar(
                context,
                ref,
                event,
                status,
                isFavorite,
                theme,
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.1),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (event.location != null &&
                                      event.location!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.place_rounded,
                                            size: 16,
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            event.location!,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_hasDirectionTarget(event)) ...[
                              const SizedBox(width: 16),
                              _buildDirectionsButton(
                                theme,
                                onTap: () => _openDirections(context, event),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                theme,
                                icon: Icons.schedule,
                                label: 'Başlangıç',
                                value: _formatDateTime(event.startAt),
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                theme,
                                icon: Icons.event_available,
                                label: 'Bitiş',
                                value: _formatDateTime(event.endAt),
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                theme,
                                icon: Icons.timelapse,
                                label: 'Süre',
                                value: _formatDuration(
                                  event.endAt.toUtc().difference(
                                        event.startAt.toUtc(),
                                      ),
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
              if (event.description != null &&
                  event.description!.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
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
                                event.description!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Etkinlik yüklenemedi: $error'),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    _EventStatus status,
    bool isFavorite,
    ThemeData theme,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      leadingWidth: 64,
      leading: OverImageIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Geri',
        margin: const EdgeInsets.only(left: 12),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        OverImageIconButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
          iconColor: isFavorite ? Colors.redAccent : Colors.white,
          margin: const EdgeInsets.only(right: 12),
          onPressed: () => _toggleFavorite(
            context,
            ref,
            event.id,
            isFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              Hero(
                tag: 'event-${event.id}',
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/images/izu_fallback.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Image.asset(
                'assets/images/izu_fallback.jpg',
                fit: BoxFit.cover,
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status, theme).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionsButton(
    ThemeData theme, {
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tarif Al',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EventStatus { upcoming, live, completed }
