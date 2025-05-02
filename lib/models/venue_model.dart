import 'package:cloud_firestore/cloud_firestore.dart';

class VenueModel {
  final String id;
  final String name;
  final String? location;
  final double? latitude; // Yeni eklenen alan
  final double? longitude; // Yeni eklenen alan
  final String weekdayHours;
  final String weekendHours;
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
    required this.weekdayHours,
    required this.weekendHours,
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
      latitude: (json['latitude'] as num?)?.toDouble(), // Yeni eklenen alan
      longitude: (json['longitude'] as num?)?.toDouble(), // Yeni eklenen alan
      weekdayHours: json['weekdayHours'] as String? ?? '',
      weekendHours: json['weekendHours'] as String? ?? '',
      menu: json['menu'] as String?,
      description: json['description'] as String?,
      announcement: json['announcement'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      amenities: List<String>.from(json['amenities'] ?? []),
      visitCount: json['visitCount'] as int? ?? 0,
    );
  }

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'latitude': latitude, // Yeni eklenen alan
      'longitude': longitude, // Yeni eklenen alan
      'weekdayHours': weekdayHours,
      'weekendHours': weekendHours,
      'menu': menu,
      'description': description,
      'announcement': announcement,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'amenities': amenities,
      'visitCount': visitCount,
    };
  }

  VenueModel copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude, // Yeni eklenen alan
    double? longitude, // Yeni eklenen alan
    String? weekdayHours,
    String? weekendHours,
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
      weekdayHours: weekdayHours ?? this.weekdayHours,
      weekendHours: weekendHours ?? this.weekendHours,
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
