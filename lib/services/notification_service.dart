import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:campus_online/models/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<NotificationModel>> fetchNotifications({int limit = 50}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from(dbNotificationsTable)
          .select()
          .or('user_id.eq.$userId,and(user_id.is.null,type.eq.admin_broadcast)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return [];
      rethrow;
    } catch (error) {
      debugPrint('Bildirimler getirilemedi: $error');
      return [];
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from(dbNotificationsTable)
          .select('id')
          .or('user_id.eq.$userId,and(user_id.is.null,type.eq.admin_broadcast)')
          .eq('is_read', false);

      return (response as List<dynamic>).length;
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return 0;
      rethrow;
    } catch (error) {
      debugPrint('Okunmamış bildirim sayısı alınamadı: $error');
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from(dbNotificationsTable)
          .update({'is_read': true}).eq('id', notificationId);
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return;
      rethrow;
    } catch (error) {
      debugPrint('Bildirim okundu olarak işaretlenemedi: $error');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from(dbNotificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return;
      rethrow;
    } catch (error) {
      debugPrint('Tüm bildirimler okundu olarak işaretlenemedi: $error');
    }
  }

  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _supabase.rpc(
        'send_broadcast_notification',
        params: {
          'p_title': title.trim(),
          'p_body': body.trim(),
        },
      );
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') {
        throw Exception(
          'Broadcast notification fonksiyonu eksik. Lütfen en güncel Supabase migration dosyalarını uygulayın.',
        );
      }
      if (isMissingRelation(error, dbNotificationsTable)) {
        throw Exception(
          'Bildirim modülü henüz etkinleştirilmemiş. Lütfen en güncel migration dosyalarını uygulayın.',
        );
      }
      rethrow;
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    final actorId = _supabase.auth.currentUser?.id;

    await _supabase.from(dbNotificationsTable).insert({
      'user_id': userId,
      'title': title.trim(),
      'body': body.trim(),
      'type': type,
      'created_by': actorId,
    });
  }

  Future<List<FeedbackItem>> fetchFeedbacks({
    String? statusFilter,
    int limit = 50,
  }) async {
    try {
      dynamic query = _supabase.from(dbUserFeedbackTable).select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List<dynamic>)
          .map((json) => FeedbackItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbUserFeedbackTable)) return [];
      rethrow;
    } catch (error) {
      debugPrint('Geri bildirimler getirilemedi: $error');
      return [];
    }
  }

  Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
    String? adminNote,
  }) async {
    final actorId = _supabase.auth.currentUser?.id;

    final updateData = <String, dynamic>{
      'status': status,
      'handled_by': actorId,
    };

    if (adminNote != null) {
      final trimmedNote = adminNote.trim();
      updateData['admin_note'] = trimmedNote.isEmpty ? null : trimmedNote;
    }

    await _supabase
        .from(dbUserFeedbackTable)
        .update(updateData)
        .eq('id', feedbackId);
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _supabase.from(dbUserFeedbackTable).delete().eq('id', feedbackId);
  }
}
