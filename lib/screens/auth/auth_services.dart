import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:campus_online/commnents/custom_keys.dart';
import 'package:campus_online/screens/navi_bar.dart';
import 'package:campus_online/models/user_model.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///Kullanıcı Kayıt
  Future<void> signUp(String userName, String email, String password) async {
    try {
      // Create auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      final user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: userName,
      );

      // Save to Firestore
      await _firestore
          .collection('users') // Changed from 'user' to 'users' for consistency
          .doc(userCredential.user!.uid)
          .set(user.toJson());

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(userName);

      await Fluttertoast.showToast(
        msg: CustomKeys.succesSignUp,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: CustomKeys.errorSignUp,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    }
  }

  ///Kullanıcı Giriş

  Future<void> signIn(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false,
          );
        }
      }
      await Fluttertoast.showToast(
        msg: CustomKeys.succesLogin,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      await Fluttertoast.showToast(
        msg: CustomKeys.errorLogin,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    }
  }

  ///Kullanıcı Çıkış İşlemleri

  Future<void> signOut() async {
    await _auth.signOut();
    await Fluttertoast.showToast(
      msg: CustomKeys.succesLogOut,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
}
