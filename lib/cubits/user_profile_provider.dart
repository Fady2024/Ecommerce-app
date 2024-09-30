import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileProvider extends ChangeNotifier {
  String? _profileImageUrl;
  String? _displayName;

  String? get profileImageUrl => _profileImageUrl;
  String? get displayName => _displayName;

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _displayName = user.displayName;
      _profileImageUrl = user.photoURL ?? await _getProfileImageUrl(user.uid);
      notifyListeners();
    }
  }

  Future<void> updateProfile(String? photoUrl, String displayName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateProfile(displayName: displayName, photoURL: photoUrl);
      _displayName = displayName;
      _profileImageUrl = photoUrl;
      notifyListeners();
    }
  }

  Future<String?> _getProfileImageUrl(String uid) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$uid.jpg');
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

}
