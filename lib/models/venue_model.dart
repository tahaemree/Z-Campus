class VenueModel {
  final String id;
  final String name;
  final String? location;
  final double? latitude; // Yeni eklenen alan
  final double? longitude; // Yeni eklenen alan
  final String hours; // Supabase: hours
  final String weekendHours; // Supabase: weekend_hours
  final String? menu;
  final String? description;
  final String? announcement;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final List<String> amenities;
  final int visitCount;

  VenueModel({
    required this.id,
    required this.name,
    this.location,
    this.latitude, // Yeni eklenen alan
    this.longitude, // Yeni eklenen alan
    required this.hours, // Supabase: hours
    required this.weekendHours, // Supabase: weekend_hours
    this.menu,
    this.description,
    this.announcement,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.amenities = const [],
    this.visitCount = 0,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json, String id) {
    return VenueModel(
      id: id,
      name: json['name'] as String,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hours: json['hours'] as String? ?? '',
      weekendHours: json['weekend_hours'] as String? ?? '',
      menu: json['menu'] as String?,
      description: json['description'] as String?,
      announcement: json['announcement'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'] as List)
          : const [],
      visitCount: json['visit_count'] as int? ?? 0,
    );
  }

  /// Creates a VenueModel from a Supabase query response that includes
  /// a left-joined `user_favorites` relation.
  ///
  /// This centralizes the favorite-check logic that was previously
  /// duplicated across 7+ providers and services.
  factory VenueModel.fromSupabaseJson(
    Map<String, dynamic> json, {
    String? userId,
  }) {
    json['is_favorite'] = userId != null &&
        json['user_favorites'] != null &&
        (json['user_favorites'] as List)
            .any((fav) => fav['user_id'] == userId);
    return VenueModel.fromJson(json, json['id']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
      'weekend_hours': weekendHours,
      'menu': menu,
      'description': description,
      'announcement': announcement,
      'image_url': imageUrl,
      'visit_count': visitCount,
    };
  }

  VenueModel copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude, // Yeni eklenen alan
    double? longitude, // Yeni eklenen alan
    String? hours, // Supabase: hours
    String? weekendHours, // Supabase: weekend_hours
    String? menu,
    String? description,
    String? announcement,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    List<String>? amenities,
    int? visitCount,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude, // Yeni eklenen alan
      longitude: longitude ?? this.longitude, // Yeni eklenen alan
      hours: hours ?? this.hours, // Supabase: hours
      weekendHours:
          weekendHours ?? this.weekendHours, // Supabase: weekend_hours
      menu: menu ?? this.menu,
      description: description ?? this.description,
      announcement: announcement ?? this.announcement,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      amenities: amenities ?? this.amenities,
      visitCount: visitCount ?? this.visitCount,
    );
  }
}
