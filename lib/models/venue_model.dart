import 'package:cloud_firestore/cloud_firestore.dart';

class VenueModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final String weekdayHours;
  final String weekendHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int visitCount;
  final String? imageUrl;
  final String category;
  final List<String> amenities;
  final bool isFavorite;

  const VenueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.weekdayHours,
    required this.weekendHours,
    required this.createdAt,
    required this.updatedAt,
    this.visitCount = 0,
    this.imageUrl,
    required this.category,
    this.amenities = const [],
    this.isFavorite = false,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json, String id) {
    return VenueModel(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      weekdayHours: json['weekdayHours'] as String? ?? '',
      weekendHours: json['weekendHours'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visitCount: json['visitCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? '',
      amenities: List<String>.from(json['amenities'] as List<dynamic>? ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'location': location,
        'weekdayHours': weekdayHours,
        'weekendHours': weekendHours,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'visitCount': visitCount,
        'imageUrl': imageUrl,
        'category': category,
        'amenities': amenities,
        'isFavorite': isFavorite,
      };

  bool get isCafeteria =>
      category.toLowerCase() == 'cafeteria' ||
      category.toLowerCase() == 'yemekhane';

  bool get isLibrary =>
      category.toLowerCase() == 'library' ||
      category.toLowerCase() == 'kütüphane';

  VenueModel copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? weekdayHours,
    String? weekendHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? visitCount,
    String? imageUrl,
    String? category,
    List<String>? amenities,
    bool? isFavorite,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      weekdayHours: weekdayHours ?? this.weekdayHours,
      weekendHours: weekendHours ?? this.weekendHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visitCount: visitCount ?? this.visitCount,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      amenities: amenities ?? this.amenities,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
