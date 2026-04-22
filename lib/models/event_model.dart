class EventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime startAt;
  final DateTime endAt;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.isPublished,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  factory EventModel.fromSupabaseJson(
    Map<String, dynamic> json, {
    String? userId,
  }) {
    final mapped = Map<String, dynamic>.from(json);
    mapped['is_favorite'] = userId != null &&
        mapped['event_favorites'] != null &&
        (mapped['event_favorites'] as List)
            .any((favorite) => favorite['user_id'] == userId);

    return EventModel.fromJson(mapped);
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'is_published': isPublished,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    bool? isFavorite,
    DateTime? startAt,
    DateTime? endAt,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
