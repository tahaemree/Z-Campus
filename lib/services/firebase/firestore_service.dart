import 'package:campus_online/models/venue_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _venuesRef => _firestore.collection('venues');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get all venues with favorite status
  Stream<List<VenueModel>> getVenues() {
    return _firestore
        .collection('venues')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VenueModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Get venues by category with favorite status
  Stream<List<VenueModel>> getVenuesByCategory(String category) async* {
    User? user = _auth.currentUser;
    List<String> favoriteVenues = [];

    if (user != null) {
      DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
      if (userDoc.exists) {
        favoriteVenues = List<String>.from(userDoc.get('favoriteVenues') ?? []);
      }
    }

    yield* _venuesRef
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['isFavorite'] = favoriteVenues.contains(doc.id);
              return VenueModel.fromJson(data, doc.id);
            }).toList());
  }

  // Search venues with favorite status
  Stream<List<VenueModel>> searchVenues(String query) {
    if (query.isEmpty) return Stream.value([]);

    // Normalize search query
    final normalizedQuery = _normalizeText(query);
    final searchTerms =
        normalizedQuery.split(' ').where((term) => term.isNotEmpty).toList();

    return _firestore
        .collection('venues')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            // Get venue data
            final venueName = _normalizeText(doc.get('name').toString());
            final venueDescription =
                _normalizeText(doc.get('description').toString());
            final venueMenu = _normalizeText(doc.get('menu').toString());

            // Check if any search term matches any field
            return searchTerms.any((term) =>
                venueName.contains(term) ||
                venueDescription.contains(term) ||
                venueMenu.contains(term));
          })
          .map((doc) => VenueModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Helper function to normalize text for search
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ''); // Remove special characters
  }

  // Get venue by ID with favorite status
  Future<VenueModel?> getVenueById(String venueId) async {
    try {
      final doc = await _venuesRef.doc(venueId).get();
      if (!doc.exists) return null;

      // Favori durumunu kontrol et
      User? user = _auth.currentUser;
      bool isFavorite = false;

      if (user != null) {
        DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
        if (userDoc.exists) {
          List<String> favoriteVenues = List<String>.from(userDoc.get('favoriteVenues') ?? []);
          isFavorite = favoriteVenues.contains(venueId);
        }
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      // Favori durumunu ekle
      data['isFavorite'] = isFavorite;
      
      return VenueModel.fromJson(data, doc.id);
    } catch (e) {
      debugPrint('Error getting venue by ID: $e');
      return null;
    }
  }

  // Get venues by IDs with favorite status
  Future<List<VenueModel>> getVenuesByIds(List<String> venueIds) async {
    if (venueIds.isEmpty) return [];

    try {
      User? user = _auth.currentUser;
      List<String> favoriteVenues = [];

      if (user != null) {
        DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
        if (userDoc.exists) {
          favoriteVenues =
              List<String>.from(userDoc.get('favoriteVenues') ?? []);
        }
      }

      final results = <VenueModel>[];

      for (var i = 0; i < venueIds.length; i += 10) {
        final end = (i + 10 < venueIds.length) ? i + 10 : venueIds.length;
        final chunk = venueIds.sublist(i, end);

        final snapshots = await Future.wait(
          chunk.map((id) => _venuesRef.doc(id).get()),
        );

        for (var doc in snapshots) {
          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['isFavorite'] = favoriteVenues.contains(doc.id);
            results.add(VenueModel.fromJson(data, doc.id));
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error getting venues by IDs: $e');
      return [];
    }
  }

  // Get featured venues with favorite status
  Future<List<VenueModel>> getFeaturedVenues({int limit = 5}) async {
    try {
      User? user = _auth.currentUser;
      List<String> favoriteVenues = [];

      if (user != null) {
        DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
        if (userDoc.exists) {
          favoriteVenues =
              List<String>.from(userDoc.get('favoriteVenues') ?? []);
        }
      }

      QuerySnapshot querySnapshot = await _venuesRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['isFavorite'] = favoriteVenues.contains(doc.id);
        return VenueModel.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting featured venues: $e');
      return [];
    }
  }

  // Get recently viewed venues with favorite status
  Future<List<VenueModel>> getRecentlyViewedVenues(String userId,
      {int limit = 5}) async {
    try {
      if (userId.isEmpty) return [];

      DocumentSnapshot userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) return [];

      List<String> recentlyViewedIds =
          List<String>.from(userDoc.get('recentlyViewed') ?? []);
      List<String> favoriteVenues =
          List<String>.from(userDoc.get('favoriteVenues') ?? []);

      if (recentlyViewedIds.length > limit) {
        recentlyViewedIds = recentlyViewedIds.sublist(0, limit);
      }

      if (recentlyViewedIds.isEmpty) return [];

      final results = <VenueModel>[];

      for (var i = 0; i < recentlyViewedIds.length; i += 10) {
        final end = (i + 10 < recentlyViewedIds.length)
            ? i + 10
            : recentlyViewedIds.length;
        final chunk = recentlyViewedIds.sublist(i, end);

        final snapshots = await Future.wait(
          chunk.map((id) => _venuesRef.doc(id).get()),
        );

        for (var doc in snapshots) {
          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['isFavorite'] = favoriteVenues.contains(doc.id);
            results.add(VenueModel.fromJson(data, doc.id));
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error getting recently viewed venues: $e');
      return [];
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String venueId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Lütfen önce giriş yapın');
      }

      final userRef = _usersRef.doc(user.uid);

      // Get user document
      DocumentSnapshot userDoc = await userRef.get();
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await userRef.set({
          'favoriteVenues': [],
          'recentSearches': [],
          'email': user.email,
          'displayName': user.displayName,
        });
      }

      // Get current favorite venues
      List<String> favoriteVenues =
          List<String>.from(userDoc.get('favoriteVenues') ?? []);

      // Toggle favorite status
      if (favoriteVenues.contains(venueId)) {
        favoriteVenues.remove(venueId);
      } else {
        favoriteVenues.add(venueId);
      }

      // Update user document
      await userRef.update({'favoriteVenues': favoriteVenues});
    } catch (e) {
      debugPrint('Favori durumu güncellenirken hata: $e');
      throw Exception('Favori durumu güncellenemedi');
    }
  }

  // Increment visit count
  Future<void> incrementVisitCount(String venueId) async {
    try {
      await _venuesRef.doc(venueId).update({
        'visitCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing visit count: $e');
    }
  }

  // Add recent search
  Future<void> addRecentSearch(String userId, String query) async {
    final userRef = _firestore.collection('users').doc(userId);

    await userRef.update({
      'recentSearches': FieldValue.arrayUnion([query])
    });
  }

  // Check if venue is favorited
  Future<bool> isVenueFavorited(String venueId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) return false;

    final favorites = List.from(userDoc.data()?['favoriteVenues'] ?? []);
    return favorites.contains(venueId);
  }

  Future<void> addVenue(VenueModel venue) async {
    await _firestore.collection('venues').doc(venue.id).set(venue.toJson());
  }

  Stream<QuerySnapshot> getVenuesStream() {
    return _venuesRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateVenue(VenueModel venue) async {
    await _firestore.collection('venues').doc(venue.id).update(venue.toJson());
  }

  Future<void> deleteVenue(String venueId) async {
    await _firestore.collection('venues').doc(venueId).delete();
  }
}
