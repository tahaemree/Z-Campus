class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final List<String> favoriteVenues;
  final List<String> recentSearches;
  final List<String> recentlyViewed;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.favoriteVenues = const [],
    this.recentSearches = const [],
    this.recentlyViewed = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        favoriteVenues:
            List<String>.from(json['favoriteVenues'] as List<dynamic>? ?? []),
        recentSearches:
            List<String>.from(json['recentSearches'] as List<dynamic>? ?? []),
        recentlyViewed:
            List<String>.from(json['recentlyViewed'] as List<dynamic>? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'favoriteVenues': favoriteVenues,
        'recentSearches': recentSearches,
        'recentlyViewed': recentlyViewed,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    List<String>? favoriteVenues,
    List<String>? recentSearches,
    List<String>? recentlyViewed,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        favoriteVenues: favoriteVenues ?? this.favoriteVenues,
        recentSearches: recentSearches ?? this.recentSearches,
        recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      );
}
