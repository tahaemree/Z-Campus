import 'package:flutter/material.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/widgets/venue_card.dart';

class VenueListSliver extends StatelessWidget {
  final List<VenueModel> venues;
  final void Function(String venueId) onVenueTap;

  const VenueListSliver({
    super.key,
    required this.venues,
    required this.onVenueTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final venue = venues[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: VenueCard(
                  venueId: venue.id,
                  venueName: venue.name,
                  hours: venue.hours,
                  weekendHours: venue.weekendHours.isNotEmpty ? venue.weekendHours : null,
                  location: venue.location ?? '',
                  venueIcon: Icons.place,
                  isFavorite: venue.isFavorite,
                  imageUrl: venue.imageUrl,
                  announcement: venue.announcement,
                  latitude: venue.latitude,
                  longitude: venue.longitude,
                  onTap: () => onVenueTap(venue.id),
                ),
            );
          },
          childCount: venues.length,
        ),
      ),
    );
  }
}

class VenueEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const VenueEmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: theme.colorScheme.onSurfaceVariant.withAlpha(153)),
            const SizedBox(height: 24),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 32.0), child: Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha(179)), textAlign: TextAlign.center)),
            ],
          ],
        ),
      ),
    );
  }
}

class VenueErrorState extends StatelessWidget {
  final Object error;
  final String title;
  const VenueErrorState({super.key, required this.error, this.title = 'Veriler yüklenemedi'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 32.0), child: Text(error.toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
