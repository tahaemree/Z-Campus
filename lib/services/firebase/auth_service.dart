import 'package:campus_online/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password, String displayName) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserInFirestore(
          userCredential.user!.uid, email, displayName);

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user in Firestore
  Future<void> _createUserInFirestore(
      String uid, String email, String displayName) async {
    UserModel newUser = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      favoriteVenues: [],
      recentSearches: [],
    );

    await _firestore.collection('users').doc(uid).set(newUser.toJson());
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel> getUserData() async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      } else {
        // Create user document if it doesn't exist
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toJson());
        return newUser;
      }
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user favorites
  Future<void> updateUserFavorites(String venueId, bool addToFavorites) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userDoc = _firestore.collection('users').doc(user.uid);

      if (addToFavorites) {
        // Add to favorites if not already added
        await userDoc.update({
          'favoriteVenues': FieldValue.arrayUnion([venueId])
        });
      } else {
        // Remove from favorites
        await userDoc.update({
          'favoriteVenues': FieldValue.arrayRemove([venueId])
        });
      }
    } catch (e) {
      throw Exception('Failed to update favorites: $e');
    }
  }

  // Add recent search
  Future<void> addRecentSearch(String venueId) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userDoc = _firestore.collection('users').doc(user.uid);

      // Get current recent searches
      DocumentSnapshot doc = await userDoc.get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> recentSearches =
            List<String>.from(data['recentSearches'] ?? []);

        // Remove if already exists to avoid duplicates
        recentSearches.remove(venueId);

        // Add to the beginning
        recentSearches.insert(0, venueId);

        // Keep only the most recent 10 searches
        if (recentSearches.length > 10) {
          recentSearches = recentSearches.sublist(0, 10);
        }

        // Update Firestore
        await userDoc.update({'recentSearches': recentSearches});
      }
    } catch (e) {
      throw Exception('Failed to add recent search: $e');
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('E-posta adresi bulunamadı.');
      case 'wrong-password':
        return Exception('Yanlış şifre girdiniz.');
      case 'email-already-in-use':
        return Exception('Bu e-posta adresi zaten kullanılmakta.');
      case 'weak-password':
        return Exception(
            'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçiniz.');
      case 'invalid-email':
        return Exception('Geçersiz e-posta formatı.');
      default:
        return Exception('Bir hata oluştu: ${e.message}');
    }
  }

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }
}
