import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:campus_online/models/explore_models.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreService {
  ExploreService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  String get _contributionSelect => _currentUserId == null
      ? '''
          *,
          venues(*),
          events(*)
        '''
      : '''
          *,
          venues(*, user_favorites!left(user_id)),
          events(*, event_favorites!left(user_id))
        ''';

  Future<ExploreSettings> fetchSettings() async {
    try {
      final row = await _supabase
          .from(dbExploreSettingsTable)
          .select()
          .eq('id', true)
          .maybeSingle();

      if (row == null) return ExploreSettings.defaults;
      return ExploreSettings.fromJson(row);
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbExploreSettingsTable)) {
        return ExploreSettings.defaults;
      }
      rethrow;
    }
  }

  Future<void> saveSettings(ExploreSettings settings) async {
    await _supabase.from(dbExploreSettingsTable).upsert(
          settings.toUpdateJson(),
          onConflict: 'id',
        );
  }

  Future<List<ExploreContribution>> fetchActiveContributions({
    required int limit,
  }) async {
    final now = DateTime.now().toUtc();

    try {
      final rows = await _supabase
          .from(dbExploreContributionsTable)
          .select(_contributionSelect)
          .eq('is_active', true)
          .or('starts_at.is.null,starts_at.lte.${now.toIso8601String()}')
          .or('ends_at.is.null,ends_at.gte.${now.toIso8601String()}')
          .order('display_order', ascending: true)
          .order('created_at', ascending: false)
          .limit(limit);

      return _parseContributions(rows, includeInactiveEvents: false);
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbExploreContributionsTable)) {
        return <ExploreContribution>[];
      }
      rethrow;
    }
  }

  Future<List<ExploreContribution>> fetchAdminContributions() async {
    try {
      final rows = await _supabase
          .from(dbExploreContributionsTable)
          .select(_contributionSelect)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      return _parseContributions(rows, includeInactiveEvents: true);
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbExploreContributionsTable)) {
        return <ExploreContribution>[];
      }
      rethrow;
    }
  }

  Future<void> saveContribution({
    String? id,
    required String itemType,
    required String targetId,
    required String? label,
    required int displayOrder,
    required bool isActive,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final cleanLabel = label?.trim();
    final payload = <String, dynamic>{
      'item_type': itemType,
      'venue_id': itemType == 'venue' ? targetId : null,
      'event_id': itemType == 'event' ? targetId : null,
      'label': cleanLabel == null || cleanLabel.isEmpty ? null : cleanLabel,
      'display_order': displayOrder,
      'is_active': isActive,
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
    };

    if (id == null) {
      await _supabase.from(dbExploreContributionsTable).insert(payload);
      return;
    }

    await _supabase
        .from(dbExploreContributionsTable)
        .update(payload)
        .eq('id', id);
  }

  Future<void> deleteContribution(String id) async {
    await _supabase.from(dbExploreContributionsTable).delete().eq('id', id);
  }

  Future<List<VenueModel>> fetchRecentlyViewedVenues({
    required int limit,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return <VenueModel>[];

    try {
      final rows = await _supabase
          .from('user_recent_views')
          .select('''
            venue_id,
            viewed_at,
            venues(*, user_favorites!left(user_id))
          ''')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(limit);

      final venues = <VenueModel>[];
      for (final row in rows) {
        final venueJson = row['venues'];
        if (venueJson is Map<String, dynamic>) {
          venues.add(VenueModel.fromSupabaseJson(venueJson, userId: userId));
        }
      }

      return venues;
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, 'user_recent_views')) {
        return <VenueModel>[];
      }
      rethrow;
    }
  }

  List<ExploreContribution> _parseContributions(
    List<dynamic> rows, {
    required bool includeInactiveEvents,
  }) {
    final userId = _currentUserId;
    final now = DateTime.now();

    return rows
        .map(
      (row) => ExploreContribution.fromJson(
        row as Map<String, dynamic>,
        userId: userId,
      ),
    )
        .where((item) {
      if (!includeInactiveEvents) {
        if (item.startsAt != null && item.startsAt!.isAfter(now)) {
          return false;
        }
        if (item.endsAt != null && item.endsAt!.isBefore(now)) {
          return false;
        }
      }

      if (item.isVenue) return item.venue != null;
      final event = item.event;
      if (event == null) return false;
      if (includeInactiveEvents) return true;
      return event.isPublished && !event.endAt.isBefore(now);
    }).toList(growable: false);
  }
}
