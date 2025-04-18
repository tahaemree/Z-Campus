import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_online/models/venue_model.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of venues
  Stream<List<VenueModel>> getVenues() {
    return _firestore.collection('venues').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VenueModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // Check if current user is admin
  bool isAdmin() {
    final user = _auth.currentUser;
    return user != null &&
        user.email == 'admin@example.com'; // TODO: Implement proper admin check
  }

  // Check if venue exists by name and return its ID if it does
  Future<String?> getVenueIdByName(String name) async {
    final querySnapshot = await _firestore
        .collection('venues')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  // Add a new venue
  Future<void> addVenue(Map<String, dynamic> venueData) async {
    if (!isAdmin()) {
      throw Exception('Yetkisiz erişim');
    }
    await _firestore.collection('venues').add(venueData);
  }

  // Update an existing venue
  Future<void> updateVenue(
      String venueId, Map<String, dynamic> venueData) async {
    if (!isAdmin()) {
      throw Exception('Yetkisiz erişim');
    }
    await _firestore.collection('venues').doc(venueId).update(venueData);
  }

  // Delete a venue
  Future<void> deleteVenue(String venueId) async {
    if (!isAdmin()) {
      throw Exception('Yetkisiz erişim');
    }
    await _firestore.collection('venues').doc(venueId).delete();
  }
}
