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
  Stream<List<VenueModel>> getVenues() async* {
    User? user = _auth.currentUser;
    List<String> favoriteVenues = [];

    if (user != null) {
      DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
      if (userDoc.exists) {
        favoriteVenues = List<String>.from(userDoc.get('favoriteVenues') ?? []);
      }
    }

    yield* _venuesRef.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['isFavorite'] = favoriteVenues.contains(doc.id);
          return VenueModel.fromJson(data, doc.id);
        }).toList());
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
  Stream<List<VenueModel>> searchVenues(String query) async* {
    if (query.isEmpty) {
      yield [];
      return;
    }

    User? user = _auth.currentUser;
    List<String> favoriteVenues = [];

    if (user != null) {
      DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
      if (userDoc.exists) {
        favoriteVenues = List<String>.from(userDoc.get('favoriteVenues') ?? []);
      }
    }

    final lowercaseQuery = query.toLowerCase();

    yield* _venuesRef.orderBy('name').limit(30).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['isFavorite'] = favoriteVenues.contains(doc.id);
            return VenueModel.fromJson(data, doc.id);
          })
          .where((venue) =>
              venue.name.toLowerCase().contains(lowercaseQuery) ||
              venue.description.toLowerCase().contains(lowercaseQuery) ||
              venue.category.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }

  // Get venue by ID with favorite status
  Future<VenueModel?> getVenueById(String venueId) async {
    try {
      DocumentSnapshot doc = await _venuesRef.doc(venueId).get();

      if (!doc.exists) {
        return null;
      }

      bool isFavorite = false;
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await _usersRef.doc(user.uid).get();
        if (userDoc.exists) {
          List<String> favoriteVenues =
              List<String>.from(userDoc.get('favoriteVenues') ?? []);
          isFavorite = favoriteVenues.contains(venueId);
        }
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['isFavorite'] = isFavorite;

      // Process venue view in background
      _processVenueView(venueId);

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
      final venueRef = _venuesRef.doc(venueId);

      await _firestore.runTransaction((transaction) async {
        // Get user document
        DocumentSnapshot userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('Kullanıcı bulunamadı');
        }

        // Get venue document
        DocumentSnapshot venueDoc = await transaction.get(venueRef);
        if (!venueDoc.exists) {
          throw Exception('Mekan bulunamadı');
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
        transaction.update(userRef, {'favoriteVenues': favoriteVenues});

        // Update venue document with favorite count
        int favoriteCount = venueDoc.get('favoriteCount') ?? 0;
        if (favoriteVenues.contains(venueId)) {
          favoriteCount++;
        } else {
          favoriteCount = favoriteCount > 0 ? favoriteCount - 1 : 0;
        }

        transaction.update(venueRef, {
          'favoriteCount': favoriteCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Favori durumu güncellenirken hata: $e');
      throw Exception('Favori durumu güncellenemedi');
    }
  }

  // Process venue view
  Future<void> _processVenueView(String venueId) async {
    try {
      final futures = <Future>[];

      futures.add(incrementVisitCount(venueId));

      User? user = _auth.currentUser;
      if (user != null) {
        futures.add(_usersRef.doc(user.uid).update({
          'recentlyViewed': FieldValue.arrayUnion([venueId])
        }));
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error in venue view processing: $e');
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
    try {
      await _firestore.collection('venues').doc(venue.id).set({
        'name': venue.name,
        'location': venue.location,
        'category': venue.category,
        'weekdayHours': venue.weekdayHours,
        'weekendHours': venue.weekendHours,
        'description': venue.description,
        'imageUrl': venue.imageUrl,
        'isFavorite': venue.isFavorite,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Mekan eklenirken bir hata oluştu: $e');
    }
  }

  Stream<QuerySnapshot> getVenuesStream() {
    return _venuesRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateVenue(VenueModel venue) async {
    try {
      await _venuesRef.doc(venue.id).update({
        'name': venue.name,
        'location': venue.location,
        'category': venue.category,
        'weekdayHours': venue.weekdayHours,
        'weekendHours': venue.weekendHours,
        'description': venue.description,
        'imageUrl': venue.imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Mekan güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteVenue(String venueId) async {
    try {
      await _venuesRef.doc(venueId).delete();
    } catch (e) {
      throw Exception('Mekan silinirken bir hata oluştu: $e');
    }
  }
}
