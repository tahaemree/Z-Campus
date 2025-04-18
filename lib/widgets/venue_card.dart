import 'package:flutter/material.dart';

class VenueCard extends StatelessWidget {
  final String venueName;
  final String hours;
  final String location;
  final IconData venueIcon;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onTap;
  final String? imageUrl;
  final String venueId;

  const VenueCard({
    super.key,
    required this.venueName,
    required this.hours,
    required this.location,
    required this.venueIcon,
    required this.venueId,
    this.isFavorite = false,
    this.onFavoritePressed,
    this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageContainer(colorScheme),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleRow(colorScheme),
                    const SizedBox(height: 2),
                    _buildHoursRow(colorScheme),
                    const SizedBox(height: 2),
                    _buildLocationRow(colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(ColorScheme colorScheme) {
    return Container(
      width: 96,
      height: 96,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 192, // 2x for retina displays
                cacheHeight: 192,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    venueIcon,
                    color: colorScheme.onSurface,
                    size: 48,
                  );
                },
              ),
            )
          : Icon(
              venueIcon,
              color: colorScheme.onSurface,
              size: 37,
            ),
    );
  }

  Widget _buildTitleRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            venueName,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onFavoritePressed,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                  reverseCurve: Curves.easeInBack,
                ),
                child: child,
              );
            },
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isFavorite),
              color:
                  isFavorite ? Colors.redAccent : colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildHoursRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 13,
        ),
        const SizedBox(width: 2),
        Text(
          hours,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 13,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
