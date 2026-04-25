/// Veritabanı-destekli bildirim modeli.
class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final bool isRead;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    required this.isRead,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: (json['type'] as String?) ?? 'general',
      targetId: json['target_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? targetId,
    bool? isRead,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isBroadcast => userId == null && type == 'admin_broadcast';
  bool get isFeedback => type == 'feedback';
}

/// Admin panelinden geri bildirim yönetimi için model.
class FeedbackItem {
  final String id;
  final String? userId;
  final String category;
  final String subject;
  final String message;
  final String? contactEmail;
  final String devicePlatform;
  final String status;
  final String? handledBy;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeedbackItem({
    required this.id,
    this.userId,
    required this.category,
    required this.subject,
    required this.message,
    this.contactEmail,
    required this.devicePlatform,
    required this.status,
    this.handledBy,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      category: (json['category'] as String?) ?? 'general',
      subject: json['subject'] as String,
      message: json['message'] as String,
      contactEmail: json['contact_email'] as String?,
      devicePlatform: (json['device_platform'] as String?) ?? 'unknown',
      status: (json['status'] as String?) ?? 'new',
      handledBy: json['handled_by'] as String?,
      adminNote: json['admin_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'general':
        return 'Genel';
      case 'suggestion':
        return 'Öneri';
      case 'recommendation':
        return 'Tavsiye';
      case 'bug_report':
        return 'Hata Bildirimi';
      default:
        return category;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'Yeni';
      case 'in_review':
        return 'İnceleniyor';
      case 'resolved':
        return 'Çözüldü';
      case 'archived':
        return 'Arşivlendi';
      default:
        return status;
    }
  }
}
