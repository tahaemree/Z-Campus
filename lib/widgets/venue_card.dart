import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/commons/app_error.dart';

class VenueCard extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;
  final String hours;
  final String location;
  final IconData venueIcon;
  final bool isFavorite; // Server state (fallback only)
  final String? imageUrl;
  final VoidCallback onTap;
  final String? weekendHours;
  final String? announcement;
  final double? latitude;
  final double? longitude;

  static const double cardHeight = 110;

  const VenueCard({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.hours,
    required this.location,
    required this.venueIcon,
    required this.isFavorite,
    required this.imageUrl,
    required this.onTap,
    this.weekendHours,
    this.announcement,
    this.latitude,
    this.longitude,
  });

  @override
  ConsumerState<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends ConsumerState<VenueCard> {
  Future<void> _handleFavoriteToggle() async {
    try {
      await ref.read(favoriteIdsProvider.notifier).toggle(widget.venueId);
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Read favorite state from the single source of truth
    final favIds = ref.watch(favoriteIdsProvider);
    final isFavorite = favIds.contains(widget.venueId);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: VenueCard.cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageContainer(theme),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              widget.venueName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (widget.location.isNotEmpty) ...[
                              Row(children: [
                                Icon(widget.venueIcon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 5),
                                Expanded(child: Text(widget.location, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ]),
                              const SizedBox(height: 4),
                            ],
                            Row(children: [
                              Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 5),
                              Expanded(
                                child: widget.weekendHours != null && widget.weekendHours!.isNotEmpty
                                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('Hafta içi: ${widget.hours.replaceAll('\n', ', ')}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('Hafta sonu: ${widget.weekendHours!.replaceAll('\n', ', ')}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ])
                                    : Text(widget.hours.replaceAll('\n', ', '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  key: ValueKey(isFavorite),
                                  color: isFavorite ? Colors.red : theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _handleFavoriteToggle,
                            ),
                            if (widget.announcement != null && widget.announcement!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Icon(Icons.campaign_rounded, color: theme.colorScheme.error, size: 20),
                            ],
                          ],
                        ),
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

  Widget _buildImageContainer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 94,
          child: widget.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Image.asset('assets/images/izu.png', fit: BoxFit.cover),
                  errorWidget: (_, __, ___) => Image.asset('assets/images/izu.png', fit: BoxFit.cover),
                )
              : Image.asset('assets/images/izu.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
