import 'package:campus_online/models/event_model.dart';
import 'package:campus_online/models/venue_model.dart';

class ExploreSettings {
  final bool showContributions;
  final bool showRecentViews;
  final String contributionsTitle;
  final String recentViewsTitle;
  final int contributionsLimit;
  final int recentViewsLimit;

  const ExploreSettings({
    required this.showContributions,
    required this.showRecentViews,
    required this.contributionsTitle,
    required this.recentViewsTitle,
    required this.contributionsLimit,
    required this.recentViewsLimit,
  });

  static const defaults = ExploreSettings(
    showContributions: true,
    showRecentViews: true,
    contributionsTitle: 'Katkıda Bulunanlar',
    recentViewsTitle: 'Son Göz Atılan Yerler',
    contributionsLimit: 10,
    recentViewsLimit: 10,
  );

  factory ExploreSettings.fromJson(Map<String, dynamic> json) {
    return ExploreSettings(
      showContributions: json['show_contributions'] as bool? ?? true,
      showRecentViews: json['show_recent_views'] as bool? ?? true,
      contributionsTitle:
          (json['contributions_title'] as String?)?.trim().isNotEmpty == true
              ? (json['contributions_title'] as String).trim()
              : defaults.contributionsTitle,
      recentViewsTitle:
          (json['recent_views_title'] as String?)?.trim().isNotEmpty == true
              ? (json['recent_views_title'] as String).trim()
              : defaults.recentViewsTitle,
      contributionsLimit: (json['contributions_limit'] as num?)?.toInt() ??
          defaults.contributionsLimit,
      recentViewsLimit: (json['recent_views_limit'] as num?)?.toInt() ??
          defaults.recentViewsLimit,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'id': true,
      'show_contributions': showContributions,
      'show_recent_views': showRecentViews,
      'contributions_title': contributionsTitle.trim(),
      'recent_views_title': recentViewsTitle.trim(),
      'contributions_limit': contributionsLimit,
      'recent_views_limit': recentViewsLimit,
    };
  }

  ExploreSettings copyWith({
    bool? showContributions,
    bool? showRecentViews,
    String? contributionsTitle,
    String? recentViewsTitle,
    int? contributionsLimit,
    int? recentViewsLimit,
  }) {
    return ExploreSettings(
      showContributions: showContributions ?? this.showContributions,
      showRecentViews: showRecentViews ?? this.showRecentViews,
      contributionsTitle: contributionsTitle ?? this.contributionsTitle,
      recentViewsTitle: recentViewsTitle ?? this.recentViewsTitle,
      contributionsLimit: contributionsLimit ?? this.contributionsLimit,
      recentViewsLimit: recentViewsLimit ?? this.recentViewsLimit,
    );
  }
}

class ExploreContribution {
  final String id;
  final String itemType;
  final String? label;
  final int displayOrder;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VenueModel? venue;
  final EventModel? event;

  const ExploreContribution({
    required this.id,
    required this.itemType,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.label,
    this.startsAt,
    this.endsAt,
    this.venue,
    this.event,
  });

  bool get isVenue => itemType == 'venue';
  bool get isEvent => itemType == 'event';

  String get title {
    if (venue != null) return venue!.name;
    if (event != null) return event!.title;
    return 'Keşfet öğesi';
  }

  String get subtitle {
    if (label != null && label!.trim().isNotEmpty) return label!.trim();
    return isVenue ? 'Mekan' : 'Etkinlik';
  }

  factory ExploreContribution.fromJson(
    Map<String, dynamic> json, {
    String? userId,
  }) {
    final venueJson = json['venues'];
    final eventJson = json['events'];

    VenueModel? venue;
    EventModel? event;

    if (venueJson is Map<String, dynamic>) {
      venue = VenueModel.fromSupabaseJson(venueJson, userId: userId);
    }

    if (eventJson is Map<String, dynamic>) {
      event = EventModel.fromSupabaseJson(eventJson, userId: userId);
    }

    return ExploreContribution(
      id: json['id'] as String,
      itemType: json['item_type'] as String,
      label: json['label'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String),
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['updated_at'] as String),
      venue: venue,
      event: event,
    );
  }
}
