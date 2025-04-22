import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';

class VenueCard extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;
  final String hours;
  final String location;
  final IconData venueIcon;
  final bool isFavorite;
  final String? imageUrl;
  final VoidCallback onFavoritePressed;
  final VoidCallback onTap;
  final String? weekendHours;
  final String? announcement;

  const VenueCard({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.hours,
    required this.location,
    required this.venueIcon,
    required this.isFavorite,
    required this.imageUrl,
    required this.onFavoritePressed,
    required this.onTap,
    this.weekendHours,
    this.announcement,
  });

  @override
  ConsumerState<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends ConsumerState<VenueCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageContainer(theme),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.venueName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (widget.location.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  widget.venueIcon,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.location,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: widget.weekendHours != null &&
                                        widget.weekendHours!.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hafta içi: ${widget.hours}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Hafta sonu: ${widget.weekendHours!}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        widget.hours,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isFavorite
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    await ref
                                        .read(firestoreServiceProvider)
                                        .toggleFavorite(widget.venueId);
                                    ref.invalidate(venuesProvider);
                                    ref.invalidate(featuredVenuesProvider);
                                    ref.invalidate(
                                        recentlyViewedVenuesProvider);
                                    ref.invalidate(favoriteVenuesProvider);
                                    clearVenuesCache(ref);
                                    invalidateVenue(ref, widget.venueId);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Favori durumu güncellenemedi'),
                                          backgroundColor:
                                              theme.colorScheme.error,
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
                        if (widget.announcement != null &&
                            widget.announcement!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Icon(
                            Icons.campaign_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: widget.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    widget.venueIcon,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 32,
                  );
                },
              ),
            )
          : Icon(
              widget.venueIcon,
              color: theme.colorScheme.onSurfaceVariant,
              size: 32,
            ),
    );
  }
}
