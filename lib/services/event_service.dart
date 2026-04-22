import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:campus_online/models/event_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  bool _isRelationMissing(PostgrestException error, String relationHint) {
    if (error.code == '42P01') return true;

    final message = error.message.toLowerCase();
    return message.contains('relation') &&
        message.contains('does not exist') &&
        message.contains(relationHint.toLowerCase());
  }

  Future<List<EventModel>> fetchUpcomingPublishedEvents({
    int limit = 100,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final userId = _currentUserId;

    dynamic rows;

    try {
      rows = userId == null
          ? await _supabase
              .from('events')
              .select('*')
              .eq('is_published', true)
              .gte('end_at', nowIso)
              .order('start_at')
              .limit(limit)
          : await _supabase
              .from('events')
              .select('''
                *,
                event_favorites!left(user_id)
              ''')
              .eq('is_published', true)
              .gte('end_at', nowIso)
              .order('start_at')
              .limit(limit);
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'event_favorites') && userId != null) {
        rows = await _supabase
            .from('events')
            .select('*')
            .eq('is_published', true)
            .gte('end_at', nowIso)
            .order('start_at')
            .limit(limit);
      } else if (_isRelationMissing(error, 'events')) {
        return <EventModel>[];
      } else {
        rethrow;
      }
    }

    return (rows as List<dynamic>)
        .map(
          (row) => EventModel.fromSupabaseJson(
            row as Map<String, dynamic>,
            userId: userId,
          ),
        )
        .toList();
  }

  Future<List<EventModel>> fetchManageableEvents({String query = ''}) async {
    final cleanQuery = query.trim();
    final userId = _currentUserId;

    final selectClause = userId == null
        ? '*'
        : '''
            *,
            event_favorites!left(user_id)
          ''';

    dynamic rows;

    try {
      rows = cleanQuery.isEmpty
          ? await _supabase
              .from('events')
              .select(selectClause)
              .order('start_at', ascending: false)
              .limit(200)
          : await _supabase
              .from('events')
              .select(selectClause)
              .or(
                'title.ilike.%${escapePostgrestLikeValue(cleanQuery)}%,description.ilike.%${escapePostgrestLikeValue(cleanQuery)}%,location.ilike.%${escapePostgrestLikeValue(cleanQuery)}%',
              )
              .order('start_at', ascending: false)
              .limit(200);
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'event_favorites') && userId != null) {
        rows = cleanQuery.isEmpty
            ? await _supabase
                .from('events')
                .select('*')
                .order('start_at', ascending: false)
                .limit(200)
            : await _supabase
                .from('events')
                .select('*')
                .or(
                  'title.ilike.%${escapePostgrestLikeValue(cleanQuery)}%,description.ilike.%${escapePostgrestLikeValue(cleanQuery)}%,location.ilike.%${escapePostgrestLikeValue(cleanQuery)}%',
                )
                .order('start_at', ascending: false)
                .limit(200);
      } else if (_isRelationMissing(error, 'events')) {
        return <EventModel>[];
      } else {
        rethrow;
      }
    }

    return (rows as List<dynamic>)
        .map(
          (row) => EventModel.fromSupabaseJson(
            row as Map<String, dynamic>,
            userId: userId,
          ),
        )
        .toList();
  }

  Future<EventModel> fetchEventById(String eventId) async {
    final userId = _currentUserId;

    dynamic row;

    try {
      row = userId == null
          ? await _supabase
              .from('events')
              .select('*')
              .eq('id', eventId)
              .maybeSingle()
          : await _supabase.from('events').select('''
                *,
                event_favorites!left(user_id)
              ''').eq('id', eventId).maybeSingle();
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'event_favorites') && userId != null) {
        row = await _supabase
            .from('events')
            .select('*')
            .eq('id', eventId)
            .maybeSingle();
      } else if (_isRelationMissing(error, 'events')) {
        throw Exception('Etkinlik modülü henüz etkinleştirilmemiş.');
      } else {
        rethrow;
      }
    }

    if (row == null) {
      throw Exception('Etkinlik bulunamadı.');
    }

    return EventModel.fromSupabaseJson(row, userId: userId);
  }

  Future<Set<String>> fetchFavoriteEventIds() async {
    final userId = _currentUserId;
    if (userId == null) return <String>{};

    try {
      final rows = await _supabase
          .from('event_favorites')
          .select('event_id')
          .eq('user_id', userId);

      return {
        for (final row in rows)
          if (row['event_id'] is String) row['event_id'] as String,
      };
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'event_favorites')) {
        return <String>{};
      }
      rethrow;
    }
  }

  Future<List<EventModel>> fetchFavoriteEvents({
    int limit = 200,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return <EventModel>[];

    final favoriteIds = await fetchFavoriteEventIds();
    if (favoriteIds.isEmpty) return <EventModel>[];

    try {
      final rows = await _supabase
          .from('events')
          .select('*')
          .inFilter('id', favoriteIds.toList())
          .order('start_at')
          .limit(limit);

      return (rows as List<dynamic>).map((row) {
        final mapped = Map<String, dynamic>.from(row as Map<String, dynamic>);
        mapped['is_favorite'] = true;
        return EventModel.fromJson(mapped);
      }).toList();
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'events') ||
          _isRelationMissing(error, 'event_favorites')) {
        return <EventModel>[];
      }
      rethrow;
    }
  }

  Future<void> addEventFavorite(String eventId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Favorilere eklemek için giriş yapmalısınız.');
    }

    try {
      await _supabase.from('event_favorites').insert({
        'user_id': userId,
        'event_id': eventId,
      });
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'event_favorites')) {
        throw Exception('Favori özelliği henüz etkinleştirilmemiş.');
      }

      if (error.code == '23505') {
        return;
      }

      rethrow;
    }
  }

  Future<void> removeEventFavorite(String eventId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Favorilerden çıkarmak için giriş yapmalısınız.');
    }

    try {
      await _supabase
          .from('event_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'event_favorites')) {
        throw Exception('Favori özelliği henüz etkinleştirilmemiş.');
      }
      rethrow;
    }
  }

  Future<void> saveEvent({
    String? eventId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublished,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'description':
          description?.trim().isEmpty == true ? null : description?.trim(),
      'location': location?.trim().isEmpty == true ? null : location?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'is_published': isPublished,
      'updated_by': _supabase.auth.currentUser?.id,
    };

    try {
      if (eventId == null) {
        payload['created_by'] = _supabase.auth.currentUser?.id;
        await _supabase.from('events').insert(payload);
        return;
      }

      await _supabase.from('events').update(payload).eq('id', eventId);
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'events')) {
        throw Exception('Etkinlik modülü henüz etkinleştirilmemiş.');
      }
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'events')) {
        throw Exception('Etkinlik modülü henüz etkinleştirilmemiş.');
      }
      rethrow;
    }
  }
}
