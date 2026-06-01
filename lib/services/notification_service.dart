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
          .eq('user_id', userId)
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

  Stream<List<NotificationModel>> watchNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(const <NotificationModel>[]);

    return _supabase
        .from(dbNotificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          final items =
              rows.map(NotificationModel.fromJson).toList(growable: false);
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<int> fetchUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from(dbNotificationsTable)
          .select('id')
          .eq('user_id', userId)
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
      final response = await _supabase.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );

      if (response == false) {
        throw Exception('Bildirim bulunamadı veya okundu işaretlenemedi.');
      }
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return;
      rethrow;
    } catch (error) {
      debugPrint('Bildirim okundu olarak işaretlenemedi: $error');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _supabase.rpc('mark_all_notifications_read');
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return;
      rethrow;
    } catch (error) {
      debugPrint('Tüm bildirimler okundu olarak işaretlenemedi: $error');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _supabase.rpc(
        'delete_notification',
        params: {'p_notification_id': notificationId},
      );

      if (response == false) {
        throw Exception('Bildirim bulunamadı veya silme yetkiniz yok.');
      }

      // Backward compatibility for projects where the older void RPC is still
      // deployed: verify that the visible row is gone before the UI reports
      // success. Newer migrations return true and skip this extra round trip.
      if (response != true) {
        final remaining = await _supabase
            .from(dbNotificationsTable)
            .select('id')
            .eq('id', notificationId)
            .maybeSingle();

        if (remaining != null) {
          throw Exception('Bildirim silinemedi. Lütfen tekrar deneyin.');
        }
      }
    } on PostgrestException catch (error) {
      if (isMissingRelation(error, dbNotificationsTable)) return;
      rethrow;
    } catch (error) {
      debugPrint('Bildirim silinemedi: $error');
      rethrow;
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
